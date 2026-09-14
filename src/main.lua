-- rivals.pro | main.lua
-- точка входа для executor: грузит все модули по порядку и стартует меню
-- использование: открой Rivals, вставь содержимое loader.lua в executor, нажми Execute

local BASE = getgenv().RIVALSPRO_BASE or "https://raw.githubusercontent.com/YOURNAME/rivals-pro/main/src"

local function loadModule(path)
    local url = BASE .. "/" .. path
    local src = game:HttpGet(url)
    local fn, err = loadstring(src)
    if not fn then
        warn("[rivals.pro] load fail: " .. path .. " :: " .. tostring(err))
        return nil
    end
    return fn()
end

-- 1. ядро
local Config   = loadModule("core/Config.lua")
local Services = loadModule("core/Services.lua")
local Utils    = loadModule("core/Utils.lua")

if not (Config and Services and Utils) then
    warn("[rivals.pro] core failed to load, abort")
    return
end

-- Utils внутри себя делает loadstring Services — подменяем на уже загруженный
-- (костыль для executor без файловой системы; в локальной сборке см. build.py)

-- проверка игры
if game.PlaceId ~= Config.GameId then
    Utils.Notify(Config.Prefix, "Это не RIVALS! PlaceId: " .. tostring(game.PlaceId), 5)
    -- не абортим жёстко: модули универсальные, пусть работают
end

getgenv().rivalspro = getgenv().rivalspro or {}
local g = getgenv().rivalspro

-- выгружаем старую копию если была
if g._loaded then
    pcall(function()
        if g.Modules and g.Modules.Aimbot then g.Modules.Aimbot:Destroy() end
        if g.Menu and g.Menu._gui then g.Menu._gui:Destroy() end
        for _, set in pairs(g.Modules and g.Modules.ESP and g.Modules.ESP._drawings or {}) do
            for _, d in pairs(set) do pcall(function() d:Remove() end) end
        end
    end)
end

-- 2. модули
local Modules = {}
Modules.Aimbot    = loadModule("modules/Aimbot.lua")
Modules.SilentAim = loadModule("modules/SilentAim.lua")
Modules.ESP       = loadModule("modules/ESP.lua")
Modules.GunMods   = loadModule("modules/GunMods.lua")
Modules.Movement  = loadModule("modules/Movement.lua")
Modules.Misc      = loadModule("modules/Misc.lua")

-- 3. init по порядку (сервисы -> утилиты -> combat -> visuals -> move -> misc)
if Modules.Aimbot then Modules.Aimbot.Init(Config, Services, Utils) end
if Modules.SilentAim then
    -- silent aim требует hookmetamethod (Synapse/Delta/Wave/Solara поддерживают)
    if hookmetamethod and getnamecallmethod then
        Modules.SilentAim.Init(Config, Services, Utils)
    else
        Utils.Notify(Config.Prefix, "executor без hookmetamethod: silent aim пропущен", 4)
    end
end
if Modules.ESP then Modules.ESP.Init(Config, Services, Utils) end
if Modules.GunMods then Modules.GunMods.Init(Config, Services, Utils) end
if Modules.Movement then Modules.Movement.Init(Config, Services, Utils) end
if Modules.Misc then Modules.Misc.Init(Config, Services, Utils) end

-- 4. меню
local Menu = loadModule("ui/Menu.lua")
if Menu then Menu.Init(Config, Services, Utils, Modules) end

g.Config, g.Services, g.Utils, g.Modules, g.Menu = Config, Services, Utils, Modules, Menu
g._loaded = true

Utils.Notify(Config.Prefix, "загружен v" .. Config.Version .. " | RightShift — меню", 5)
print(string.format("%s loaded v%s", Config.Prefix, Config.Version))
