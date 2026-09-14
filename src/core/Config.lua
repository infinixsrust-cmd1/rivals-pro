-- rivals.pro | config
-- все настройки в одном месте, крути под себя

local Config = {}

Config.GameId = 17625359962 -- RIVALS PlaceId
Config.Version = "1.0.0"
Config.Prefix = "[rivals.pro]"

-- Aimbot
Config.Aimbot = {
    Enabled = false,
    Key = Enum.KeyCode.E,
    Toggle = false, -- false = hold, true = toggle
    TargetPart = "Head", -- Head / HumanoidRootPart / Torso
    Smoothness = 8, -- чем больше тем плавнее (1-20)
    FOV = 120, -- радиус в пикселях
    ShowFOV = true,
    FOVColor = Color3.fromRGB(255, 255, 255),
    TeamCheck = true,
    WallCheck = true,
    AliveCheck = true,
    Prediction = 0.135, -- предикт для движущихся целей
    StickyTarget = true, -- держать таргет пока в FOV
}

-- Silent Aim (на основе namecall hook, палится меньше чем aimbot)
Config.SilentAim = {
    Enabled = false,
    HitChance = 100, -- 1-100
    TargetPart = "Head",
    MaxDistance = 1000,
    TeamCheck = true,
    WallCheck = true,
    -- оффсеты / имена remote под текущий патч Rivals
    -- если после обновы не работает -> обнови имена, взято из github-ревёрсов:
    Remotes = {
        "Shoot",
        "Fire",
        "FireBullet",
        "ShootGun",
        "RemoteEvent",
    },
    MethodNames = {
        "FireServer",
        "InvokeServer",
    },
}

-- ESP
Config.ESP = {
    Enabled = false,
    TeamCheck = true,
    Box = true,
    BoxColor = Color3.fromRGB(255, 0, 60),
    Name = true,
    HealthBar = true,
    HealthText = false,
    Distance = true,
    Weapon = false,
    Chams = false,
    Tracers = false,
    TracerFrom = "Bottom", -- Bottom / Mouse / Top
    MaxDistance = 2000,
}

-- Gun Mods
Config.GunMods = {
    NoRecoil = false,
    RecoilAmount = 0, -- 0 = вырубить полностью
    NoSpread = false,
    RapidFire = false,
    FireRateMult = 2,
    InfiniteAmmo = false,
    InstantReload = false,
    NoBulletWaste = false,
}

-- Movement / Player
Config.Movement = {
    SpeedEnabled = false,
    Speed = 24, -- дефолт 16
    FlyEnabled = false,
    FlySpeed = 50,
    FlyKey = Enum.KeyCode.F,
    Noclip = false,
    InfiniteJump = false,
    NoKnockback = false,
}

-- Misc
Config.Misc = {
    NoCameraShake = true,
    AntiAFK = true,
    FPSBoost = false,
    Fullbright = false,
    SpectatorWarning = true,
}

-- UI
Config.UI = {
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "Dark",
    Accent = Color3.fromRGB(255, 0, 60),
}

return Config
