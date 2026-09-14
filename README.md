# rivals.pro — мультифайл чит под RIVALS (Roblox)

Структура как у взрослых хабов: ядро + модули + меню. Не одна простыня на 1000 строк.

## Папка проекта

```
C:\Users\user\Documents\lua\
├── loader.lua          ← единственное что вставляешь в executor
├── README.md           ← ты здесь
└── src\
    ├── main.lua        ← точка входа, грузит всё по порядку
    ├── core\
    │   ├── Config.lua      ← ВСЕ настройки (аим, есп, ганмоды, мувмент)
    │   ├── Services.lua    ← кэш GetService + LocalPlayer/Camera
    │   └── Utils.lua       ← проверки (alive/team/visible), предикт, поиск Remote
    ├── modules\
    │   ├── Aimbot.lua      ← FOV + smooth + предикт + sticky target, RMB/E
    │   ├── SilentAim.lua   ← hook __namecall FireServer, подмена Vector3
    │   ├── ESP.lua         ← box/имя/хп/дистанция/трейсеры (Drawing API)
    │   ├── GunMods.lua     ← no recoil/spread, rapid fire, inf ammo (патч таблиц)
    │   ├── Movement.lua    ← speed/fly(F)/noclip/inf jump/no knockback
    │   └── Misc.lua        ← anti-afk, anti-shake, fullbright, fps boost, spectator warn
    └── ui\
        └── Menu.lua        ← меню на чистом GUI, RightShift — скрыть
```

## Запуск (2 шага)

1. Залей папку `src` в свой GitHub репозиторий (или оставь локально).
2. В `loader.lua` поменяй `YOURNAME/rivals-pro` на свой `юзер/репо`.
3. Открой **RIVALS** в Roblox → вставь `loader.lua` в executor (Delta / Solara / Wave / Xeno / Synapse Z) → Execute.
4. Меню: **RightShift**. Аим: держать **RMB или E**.

## Что откуда (github-источники)

Логика списана с живых ревёрсов, не с потолка:

| Фича | Источник идеи |
|---|---|
| Silent Aim hook FireServer + HitChance | kiciahook, Nebora SmoothAimbot |
| Aimbot FOV + smooth + prediction | VelocityHub Rivals, ttwizz Universal Aimbot |
| ESP box/hp/name/distance + tracers | ZekeHub Rivals (rscripts), SolixHub |
| GunMods патч Recoil/Spread/FireRate таблиц | Duck Hub (no spread, fast fire), BeeTech FastFire |
| Rapid fire / force full-auto | ZekeHub Gun Mods |
| Movement fly/noclip/speed | VelocityHub Player Utility |
| Unlock all / skin changer | SolixHub, KiciaHook (в GunMods не входит — отдельный Remote, смотри ниже) |

## Оффсеты / имена Remote

В Roblox Luau нет memory-оффсетов как в CS — есть **имена RemoteEvent**. Они меняются каждый патч Rivals.
Актуальные на сейчас лежат в `src/core/Config.lua → SilentAim.Remotes`:

```lua
Remotes = { "Shoot", "Fire", "FireBullet", "ShootGun", "RemoteEvent" }
```

Если после обновы silent aim перестал попадать:

1. Открой executor → SimpleSpy / RemoteSpy.
2. Постреляй → смотри какой Remote спамит Vector3/CFrame.
3. Добавь его имя в `Config.SilentAim.Remotes`.
4. Re-execute.

`Utils.FindShootRemote` сам подберёт fallback по подстроке shoot/fire/bullet/gun/damage.

## Крутилки (Config.lua)

- `Aimbot.Smoothness` 1–20, `FOV` в пикселях, `Prediction` 0–0.3
- `SilentAim.HitChance` 1–100 (палевный на 100 — ставь 70–85 под легит)
- `ESP.MaxDistance`, `Movement.Speed/FlySpeed`, `GunMods.FireRateMult`

## Совместимость executor

- Требуется: `Drawing`, `hookmetamethod`, `getnamecallmethod` (для silent aim).
- Есть в: Wave, Synapse Z, Delta, Solara, Xeno, AWP, Nihon.
- Без `hookmetamethod` — silent aim скипается, остальное работает (см. main.lua).

## Дисклеймер гнезда

Тестируй в приватке. Hitchance 100 + rapid fire x5 = репорт за 2 катки.
