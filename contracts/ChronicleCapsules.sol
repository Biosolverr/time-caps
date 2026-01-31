// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ChronicleCapsules
/// @notice Commit → time-lock → reveal "capsules" with optional ETH deposits.
/// @dev Standalone, no imports. Uses pull-withdrawals for ETH safety.
contract ChronicleCapsules {
    // ============
    // Custom errors
    // ============
    error ZeroCommit();
    error UnlockNotInFuture();
    error CapsuleNotFound();
    error NotCreator();
    error NotAuthorizedToReveal();
    error AlreadyRevealed();
    error AlreadyCanceled();
    error TooEarlyToReveal();
    error InvalidReveal();
    error UnlockAlreadyReached();
    error NewUnlockNotLater();
    error DepositTooLarge();
    error NothingToWithdraw();
    error WithdrawFailed();

    // ============
    // Events
    // ============
    event CapsuleCreated(
        uint256 indexed capsuleId,
        address indexed creator,
        address indexed beneficiary,
        uint64 unlockTime,
        bytes32 commit,
        uint128 deposit
    );

    event CapsuleCanceled(uint256 indexed capsuleId, address indexed creator);
    event CapsuleUnlockExtended(uint256 indexed capsuleId, uint64 oldUnlockTime, uint64 newUnlockTime);

    /// @dev Payload is emitted as bytes. If it's UTF-8 text, frontends can decode it.
    event CapsuleRevealed(
        uint256 indexed capsuleId,
        address indexed revealer,
        bytes32 commit,
        bytes payload
    );

    event Withdrawal(address indexed to, uint256 amount);

    // ============
    // Data model
    // ============
    struct Capsule {
        address creator;
        address beneficiary;
        uint64 unlockTime;
        uint128 deposit;     // stored amount (moved to withdrawCredits upon cancel/reveal)
        bytes32 commit;      // keccak256(abi.encode(salt, payload))
        bool revealed;
        bool canceled;
    }

    // capsuleId => Capsule
    mapping(uint256 => Capsule) private _capsules;

    // creator => nonce, used in capsuleId derivation
    mapping(address => uint256) public nonces;

    // pull-withdrawal credits
    mapping(address => uint256) public withdrawCredits;

    // lightweight nonReentrant
    uint256 private _lock = 1;

    modifier nonReentrant() {
        require(_lock == 1, "REENTRANCY");
        _lock = 2;
        _;
        _lock = 1;
    }

    // ============
    // Views / helpers
    // ============

    /// @notice Compute commit hash as keccak256(abi.encode(salt, payload)).
    function computeCommit(bytes32 salt, bytes calldata payload) external pure returns (bytes32) {
        return keccak256(abi.encode(salt, payload));
    }

    /// @notice Read capsule data by id.
    /// @dev Reverts if capsule doesn't exist.
    function getCapsule(uint256 capsuleId) external view returns (Capsule memory c) {
        c = _capsules[capsuleId];
        if (c.creator == address(0)) revert CapsuleNotFound();
    }

    // ============
    // Core actions
    // ============

    /// @notice Create a capsule with a commit hash and future unlock time.
    /// @param commit keccak256(abi.encode(salt, payload))
    /// @param unlockTime unix timestamp (must be in the future)
    /// @param beneficiary receiver of deposit after reveal (or creator if zero)
    function createCapsule(
        bytes32 commit,
        uint64 unlockTime,
        address beneficiary
    ) external payable returns (uint256 capsuleId) {
        if (commit == bytes32(0)) revert ZeroCommit();
        if (unlockTime <= block.timestamp) revert UnlockNotInFuture();

        // fit deposit into uint128 for tighter storage (optional constraint)
        if (msg.value > type(uint128).max) revert DepositTooLarge();

        uint256 n = nonces[msg.sender]++;
        capsuleId = uint256(keccak256(abi.encodePacked(
            bytes1(0xCC),              // domain separator-ish constant to avoid "looking generic"
            block.chainid,
            address(this),
            msg.sender,
            beneficiary,
            unlockTime,
            commit,
            n
        )));

        // extremely unlikely collision; if happens, user can retry
        Capsule storage c = _capsules[capsuleId];
        if (c.creator != address(0)) {
            // bump nonce and rederive (single extra try to avoid loops)
            n = nonces[msg.sender]++;
            capsuleId = uint256(keccak256(abi.encodePacked(
                bytes1(0xCD),
                block.chainid,
                address(this),
                msg.sender,
                beneficiary,
                unlockTime,
                commit,
                n
            )));
            c = _capsules[capsuleId];
            require(c.creator == address(0), "ID_COLLISION");
        }

        c.creator = msg.sender;
        c.beneficiary = beneficiary;
        c.unlockTime = unlockTime;
        c.deposit = uint128(msg.value);
        c.commit = commit;
        c.revealed = false;
        c.canceled = false;

        emit CapsuleCreated(capsuleId, msg.sender, beneficiary, unlockTime, commit, uint128(msg.value));
    }

    /// @notice Creator may cancel a capsule before unlockTime. Deposit becomes withdrawable by creator.
    function cancelCapsule(uint256 capsuleId) external {
        Capsule storage c = _capsules[capsuleId];
        if (c.creator == address(0)) revert CapsuleNotFound();
        if (msg.sender != c.creator) revert NotCreator();
        if (c.revealed) revert AlreadyRevealed();
        if (c.canceled) revert AlreadyCanceled();
        if (block.timestamp >= c.unlockTime) revert UnlockAlreadyReached();

        c.canceled = true;

        uint256 amount = c.deposit;
        if (amount != 0) {
            c.deposit = 0;
            withdrawCredits[c.creator] += amount;
        }

        emit CapsuleCanceled(capsuleId, msg.sender);
    }

    /// @notice Creator can extend unlockTime (only forward) while still locked.
    function extendUnlockTime(uint256 capsuleId, uint64 newUnlockTime) external {
        Capsule storage c = _capsules[capsuleId];
        if (c.creator == address(0)) revert CapsuleNotFound();
        if (msg.sender != c.creator) revert NotCreator();
        if (c.revealed) revert AlreadyRevealed();
        if (c.canceled) revert AlreadyCanceled();
        if (block.timestamp >= c.unlockTime) revert UnlockAlreadyReached();
        if (newUnlockTime <= c.unlockTime) revert NewUnlockNotLater();

        uint64 old = c.unlockTime;
        c.unlockTime = newUnlockTime;
        emit CapsuleUnlockExtended(capsuleId, old, newUnlockTime);
    }

    /// @notice Reveal the capsule content after unlockTime by providing salt + payload matching commit.
    /// @dev If deposit exists, it becomes withdrawable by beneficiary (or creator if beneficiary==0).
    function reveal(uint256 capsuleId, bytes32 salt, bytes calldata payload) external {
        Capsule storage c = _capsules[capsuleId];
        if (c.creator == address(0)) revert CapsuleNotFound();
        if (c.revealed) revert AlreadyRevealed();
        if (c.canceled) revert AlreadyCanceled();
        if (block.timestamp < c.unlockTime) revert TooEarlyToReveal();

        // only creator or beneficiary can reveal (beneficiary can be zero => only creator)
        if (msg.sender != c.creator) {
            if (c.beneficiary == address(0) || msg.sender != c.beneficiary) revert NotAuthorizedToReveal();
        }

        bytes32 computed = keccak256(abi.encode(salt, payload));
        if (computed != c.commit) revert InvalidReveal();

        c.revealed = true;

        uint256 amount = c.deposit;
        if (amount != 0) {
            c.deposit = 0;
            address receiver = c.beneficiary == address(0) ? c.creator : c.beneficiary;
            withdrawCredits[receiver] += amount;
        }

        emit CapsuleRevealed(capsuleId, msg.sender, c.commit, payload);
    }

    /// @notice Withdraw your available ETH credits.
    function withdraw() external nonReentrant {
        uint256 amount = withdrawCredits[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        withdrawCredits[msg.sender] = 0;

        (bool ok, ) = msg.sender.call{value: amount}("");
        if (!ok) {
            // restore balance on failure
            withdrawCredits[msg.sender] = amount;
            revert WithdrawFailed();
        }

        emit Withdrawal(msg.sender, amount);
    }

    // ============
    // Receive / fallback
    // ============
    /// @dev Contract is not intended to accept random ETH; use createCapsule() deposits.
    receive() external payable {
        revert("DIRECT_ETH_NOT_ACCEPTED");
    }

    fallback() external payable {
        revert("NO_FALLBACK");
    }
}
