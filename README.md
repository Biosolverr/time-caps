# ChronicleCapsules (Solidity)

**ChronicleCapsules** — маленький on-chain “архив тайм‑капсул” в формате **commit → time-lock → reveal**.
Вы создаёте капсулу с хэшем секрета (commit), опционально кладёте ETH, задаёте время разблокировки и бенефициара.
После наступления времени можно раскрыть секрет: контракт проверит соответствие хэшу и зафиксирует раскрытие событием.
Если был депозит, он станет доступен для вывода (pull-withdrawal), что безопаснее прямых переводов.

> Контракт написан без импортов и без сторонних библиотек — один файл, чтобы удобно заливать и читать.

---

## Возможности

- Создание капсулы: `commit`, `unlockTime`, `beneficiary`, опциональный `msg.value`
- Отмена капсулы до разблокировки (возврат депозита создателю через withdraw)
- Раскрытие секрета после времени разблокировки с проверкой commit-хэша
- Безопасный вывод ETH через `withdraw()` (pull payments)
- Небольшие “фишки” для гибкости:
  - `extendUnlockTime()` — создатель может **продлить** время (только вперёд, до наступления unlock)

---

## Быстрый старт без терминала (через Remix)

1. Откройте https://remix.ethereum.org
2. Создайте файл `ChronicleCapsules.sol` и вставьте код из `contracts/ChronicleCapsules.sol`
3. Вкладка **Solidity compiler**:
   - Version: `0.8.24` (или близкую `0.8.2x`)
   - Compile
4. Вкладка **Deploy & run**:
   - Environment: Remix VM (для теста) или Injected Provider (MetaMask)
   - Deploy

---

## Как пользоваться

### 1) Подготовить commit (хэш секрета)
Commit считается так:

- Берёте `salt` (bytes32, случайный)
- Берёте `payload` (bytes, например текст в UTF-8)
- Commit = `keccak256(abi.encode(salt, payload))`

В контракте есть helper:
- `computeCommit(bytes32 salt, bytes payload)`

> Важно: если вы раскроете `salt` и `payload` — это станет публичным в блокчейне (так и задумано).

### 2) Создать капсулу
Вызов:
- `createCapsule(commit, unlockTime, beneficiary)`  
и при желании отправьте ETH как `msg.value`.

- `unlockTime` должен быть **в будущем**
- `beneficiary` может быть `0x000...000` — тогда “получателем депозита” будет создатель

### 3) Отменить капсулу (до unlock)
- `cancelCapsule(capsuleId)`

Депозит не отправляется напрямую, а зачисляется в баланс вывода:
- потом вызовите `withdraw()`.

### 4) Раскрыть секрет (после unlock)
- `reveal(capsuleId, salt, payload)`

Если commit совпал:
- капсула помечается раскрытой
- эмитится событие с `payload`
- депозит (если был) зачисляется в withdraw-баланс бенефициара (или создателя, если beneficiary = 0)

### 5) Вывести ETH
- `withdraw()`

---

## Замечания по безопасности и ограничения

- Раскрытый `payload` навсегда публичен (в логах события и calldata).
- Это не шифрование и не “приватное хранение данных”, а именно commit‑reveal.
- Контракт использует pull-withdrawal и простую защиту от реэнтранси в `withdraw()`.

---

## Лицензия
MIT# time-caps
























DownloadCopy codecd /d C:\Users\1\Desktop\BaseEthUsdcswap-dapp-frontend-main

echo ===== ТЕКУЩАЯ ПАПКА =====
cd

echo ===== СТРУКТУРА ПРОЕКТА =====
tree /L 2

echo ===== ПРОВЕРКА PACKAGE.JSON =====
type package.json | findstr "name version"

echo ===== ПРОВЕРКА NODE_MODULES =====
dir node_modules | findstr /C:"wagmi" /C:"react" /C:"next"

echo ===== КОНФИГИ NEXT.JS =====
dir next.config.* 2>nul || echo ❌ next.config.* НЕ НАЙДЕН

echo ===== TAILWIND КОНФИГ =====
dir tailwind.config.* 2>nul || echo ❌ tailwind.config.* НЕ НАЙДЕН

echo ===== POSTCSS КОНФИГ =====
dir postcss.config.* 2>nul || echo ❌ postcss.config.* НЕ НАЙДЕН

echo ===== TSCONFIG =====
dir tsconfig.json 2>nul || echo ❌ tsconfig.json НЕ НАЙДЕН

echo ===== ENV ФАЙЛЫ =====
dir .env* 2>nul || echo ❌ .env файлы НЕ НАЙДЕНЫ

echo ===== ПАПКА SRC =====
dir src

echo ===== ПАПКА APP =====
dir src\app

echo ===== APP/LAYOUT.TSX =====
dir src\app\layout.tsx 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== APP/PAGE.TSX =====
dir src\app\page.tsx 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== APP/PROVIDERS.TSX =====
dir src\app\providers.tsx 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== APP/GLOBALS.CSS =====
dir src\app\globals.css 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== ПАПКА LIB =====
dir src\lib 2>nul || echo ❌ НЕ НАЙДЕНА

echo ===== LIB/CONFIG =====
dir src\lib\config 2>nul || echo ❌ НЕ НАЙДЕНА

echo ===== LIB/CONFIG/WAGMI.TS =====
dir src\lib\config\wagmi.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== LIB/CONFIG/CHAINS.TS =====
dir src\lib\config\chains.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== LIB/DOMAIN =====
dir src\lib\domain 2>nul || echo ❌ НЕ НАЙДЕНА

echo ===== LIB/DOMAIN/SWAP.TS =====
dir src\lib\domain\swap.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== LIB/DOMAIN/REPUTATION.TS =====
dir src\lib\domain\reputation.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== LIB/DOMAIN/CALCULATOR.TS =====
dir src\lib\domain\calculator.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== LIB/CONTRACTS =====
dir src\lib\contracts 2>nul || echo ❌ НЕ НАЙДЕНА

echo ===== LIB/CONTRACTS/CLIENT.TS =====
dir src\lib\contracts\client.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== LIB/CONTRACTS/PUBLIC-CLIENT.TS =====
dir src\lib\contracts\public-client.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== LIB/GENERATED/CONTRACTS =====
dir src\lib\generated\contracts 2>nul || echo ❌ НЕ НАЙДЕНА

echo ===== LIB/GENERATED/CONTRACTS/INDEX.TS =====
dir src\lib\generated\contracts\index.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== LIB/UTILS =====
dir src\lib\utils 2>nul || echo ❌ НЕ НАЙДЕНА

echo ===== LIB/UTILS/CN.TS =====
dir src\lib\utils\cn.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== LIB/ENV.TS =====
dir src\lib\env.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== MIDDLEWARE.TS =====
dir src\middleware.ts 2>nul || echo ❌ НЕ НАЙДЕН

echo ===== PUBLIC ПАПКА =====
dir public 2>nul || echo ❌ НЕ НАЙДЕНА

echo ===== GIT =====
dir .git 2>nul || echo ❌ .git НЕ НАЙДЕН

echo ===== PRETTIER КОНФИГ =====
dir .prettierrc* 2>nul || echo ⚠️  .prettierrc НЕ НАЙДЕН (опционально)

echo ===== ESLINT КОНФИГ =====
dir .eslintrc* 2>nul || echo ⚠️  .eslintrc НЕ НАЙДЕН (опционально)

echo ===== GITIGNORE =====
dir .gitignore 2>nul || echo ⚠️  .gitignore НЕ НАЙДЕН (опционально)

echo.
echo ===== ПРОВЕРКА WAGMI И ЗАВИСИМОСТЕЙ =====
npm list wagmi 2>nul || echo ❌ wagmi НЕ УСТАНОВЛЕН
npm list react 2>nul || echo ❌ react НЕ УСТАНОВЛЕН
npm list next 2>nul || echo ❌ next НЕ УСТАНОВЛЕН

echo.
echo ✅ РЕВИЗИЯ ЗАВЕРШЕНА
Запусти всё это в cmd сразу, скопируй и вставь!
Вывод покажет:

* ✅ Что есть (зелёный текст)
* ❌ Чего нет (красный текст)
* ⚠️ Опциональное (жёлтый текст)

Скопируй результат!I prefer thisMiniMax M2.5 LightningPRO
Вот все команды для ревизии проекта:
cmdDownloadCopy codecd /d C:\Users\1\Desktop\BaseEthUsdcswap-dapp-frontend-main
cmdDownloadCopy codedir
cmdDownloadCopy codedir src
cmdDownloadCopy codedir src\app
cmdDownloadCopy codedir src\lib
cmdDownloadCopy codedir src\lib\config
cmdDownloadCopy codedir src\lib\hooks
cmdDownloadCopy codetype src\app\layout.tsx
cmdDownloadCopy codetype src\app\page.tsx
cmdDownloadCopy codetype src\app\providers.tsx
cmdDownloadCopy codetype src\app\globals.css
cmdDownloadCopy codetype src\lib\config\wagmi.ts
cmdDownloadCopy codetype src\lib\config\env.ts
cmdDownloadCopy codetype package.json
cmdDownloadCopy codedir node_modules\@rainbow-me
cmdDownloadCopy codedir node_modules\wagmi
cmdDownloadCopy codedir node_modules\@tanstack
cmdDownloadCopy codetype .env.local 2>nul || echo "Файл .env.local НЕ найден"
cmdDownloadCopy codetype .env 2>nul || echo "Файл .env НЕ найден"

Для быстрой проверки всех важных файлов одной командой:
cmdDownloadCopy codecd /d C:\Users\1\Desktop\BaseEthUsdcswap-dapp-frontend-main && (
echo === СТРУКТУРА ПРОЕКТА === && dir /b && echo. && echo === SRC === && dir /b src && echo. && echo === APP === && dir /b src\app && echo. && echo === LIBCONFIG === && dir /b src\lib\config
)
