-- rivals.pro NL | init.lua (entry for modular build)
-- usage: loadstring(game:HttpGet(BASE.."/nl/init.lua"))()
-- ASCII only.

local BASE = getgenv().RIVALSPRO_BASE or "https://raw.githubusercontent.com/infinixsrust-cmd1/rivals-pro/main/src"

local function loadModule(path, ...)
    local url = BASE .. "/" .. path
    local ok, src = pcall(game.HttpGet, game, url)
    if not ok or not src or #src < 10 then
        warn("[nl] http fail: " .. path)
        return nil
    end
    local fn, err = loadstring(src)
    if not fn then warn("[nl] load fail: " .. path .. " " .. tostring(err)) return nil end
    local ok2, mod = pcall(fn, ...)
    if not ok2 then warn("[nl] run fail: " .. path .. " " .. tostring(mod)) return nil end
    return mod
end

-- cleanup old
pcall(function()
    local o = game:GetService("CoreGui"):FindFirstChild("rivalspro")
    if o then o:Destroy() end
end)
for _, d in ipairs(getgenv()._rp_draw or {}) do pcall(function() d:Remove() end) end
getgenv()._rp_draw = {}

-- config
local C = {
    Aim = {Enabled=false, Mode="Hold", Key=Enum.KeyCode.E, Part="Head",
        Smooth=6, FOV=130, ShowFOV=true, Team=true, Wall=true, Dead=true,
        Pred=0.12, Sticky=true, Dot=false},
    Silent = {Enabled=false, Hit=80, Part="Head", Team=true, Wall=true, Dist=900},
    ESP = {Enabled=false, Box=true, Name=true, HP=true, Dist=true, Tracer=false,
        Team=true, MaxD=2000, Color=Color3.fromRGB(90,140,255)},
    Gun = {NoRecoil=false, NoSpread=false, Rapid=false, RapidX=2, InfAmmo=false, Reload=false},
    Move = {Speed=false, SpeedV=24, Fly=false, FlyV=50, Noclip=false, InfJump=false, Knock=false},
    Misc = {NoShake=true, Bright=false, AFK=true},
    Skin = {Enabled=false, Weapon="Assault Rifle", Skin="", Wrap="", Status="idle"},
}

-- core + modules (separate files)
local Common = loadModule("nl/modules/common.lua")
if not Common then warn("[nl] common failed") return end
local Aimbot = loadModule("nl/modules/aimbot.lua", Common)
local Silent = loadModule("nl/modules/silent.lua", Common)
local ESP = loadModule("nl/modules/esp.lua", Common)
local GunM = loadModule("nl/modules/gunmods.lua", Common)
local Move = loadModule("nl/modules/movement.lua", Common)
local Skins = loadModule("nl/modules/skins.lua", Common)
local Misc = loadModule("nl/modules/misc.lua", Common)
if not (Aimbot and ESP and Move and Misc) then warn("[nl] modules failed") return end

local Mods = {Aimbot=Aimbot, ESP=ESP}
-- light boot: only cheap modules now. Heavy ones (silent/gun/skins)
-- start lazily on first toggle — Rivals freezes if all require() at inject.
Aimbot.start(C)
ESP.start(C)
Move.start(C)
Misc.start(C)
local lazy = {silent=false, gun=false, skins=false}
local function ensureSilent()
    if lazy.silent then return end
    lazy.silent = true
    task.spawn(function()
        local ok, err = Silent.start(C)
        print("[nl] silent lazy:", tostring(ok), tostring(err))
    end)
end
local function ensureGun()
    if lazy.gun then return end
    lazy.gun = true
    task.spawn(function() GunM.start(C) end)
end
local function ensureSkins()
    if lazy.skins then return end
    lazy.skins = true
    task.spawn(function() Skins.start(C) end)
end

-- imgui menu
local Im = loadModule("nl/ui/imgui.lua", Common, C, Mods)
Im.build()

-- tab bar buttons
local win = Im.win
local tabsBar = nil
for _, ch in ipairs(win:GetChildren()) do
    if ch:IsA("Frame") and ch.Name == "" and ch.Size.Y.Offset == 28 then tabsBar = ch break end
end
-- fallback: find by position
if not tabsBar then
    for _, ch in ipairs(win:GetChildren()) do
        if ch:IsA("Frame") and ch.Position.Y.Offset == 32 then tabsBar = ch break end
    end
end

local pages = {"Aimbot", "Silent", "ESP", "Combat", "Skins", "Move", "Misc"}
local groups = {} -- page -> {left widgets parent, right}
local cur = "Aimbot"

local function clearCols()
    for _, c in ipairs({Im.left, Im.right}) do
        for _, w in ipairs(c:GetChildren()) do
            if not w:IsA("UIListLayout") and not w:IsA("UIPadding") then w:Destroy() end
        end
    end
end

local tabBtns = {}
local function paintTabs()
    for n, b in pairs(tabBtns) do
        b.BackgroundColor3 = (n == cur) and Im.ACC or Im.ROW
        b.TextColor3 = (n == cur) and Color3.new(1,1,1) or Im.DIM
    end
end

local function buildPage(name)
    clearCols()
    local L, R = Im.left, Im.right
    if name == "Aimbot" then
        Im.group(L, "aimbot")
        Im.checkbox(L, "enabled", C.Aim, "Enabled")
        Im.combo(L, "mode", C.Aim, "Mode", {"Hold", "Toggle"})
        Im.combo(L, "bone", C.Aim, "Part", {"Head", "Chest", "Legs", "Random"})
        Im.slider(L, "smoothness", C.Aim, "Smooth", 1, 20, 1)
        Im.slider(L, "fov", C.Aim, "FOV", 20, 400, 5)
        Im.group(R, "assist")
        Im.slider(R, "prediction", C.Aim, "Pred", 0, 0.3, 0.01)
        Im.checkbox(R, "show fov", C.Aim, "ShowFOV")
        Im.checkbox(R, "target dot", C.Aim, "Dot")
        Im.checkbox(R, "team check", C.Aim, "Team")
        Im.checkbox(R, "wall check", C.Aim, "Wall")
        Im.checkbox(R, "sticky target", C.Aim, "Sticky")
    elseif name == "Silent" then
        Im.group(L, "silent aim")
        Im.checkbox(L, "enabled", C.Silent, "Enabled", function(v) if v then ensureSilent() end end)
        Im.slider(L, "hit chance", C.Silent, "Hit", 1, 100, 1)
        Im.slider(L, "max dist", C.Silent, "Dist", 100, 3000, 50)
        Im.group(R, "checks")
        Im.combo(R, "bone", C.Silent, "Part", {"Head", "HumanoidRootPart"})
        Im.checkbox(R, "team check", C.Silent, "Team")
        Im.checkbox(R, "wall check", C.Silent, "Wall")
    elseif name == "ESP" then
        Im.group(L, "esp")
        Im.checkbox(L, "enabled", C.ESP, "Enabled")
        Im.checkbox(L, "boxes", C.ESP, "Box")
        Im.checkbox(L, "names", C.ESP, "Name")
        Im.checkbox(L, "health", C.ESP, "HP")
        Im.group(R, "extra")
        Im.checkbox(R, "distance", C.ESP, "Dist")
        Im.checkbox(R, "tracers", C.ESP, "Tracer")
        Im.checkbox(R, "team check", C.ESP, "Team")
        Im.slider(R, "max dist", C.ESP, "MaxD", 200, 5000, 100)
    elseif name == "Combat" then
        Im.group(L, "weapon")
        Im.checkbox(L, "no recoil", C.Gun, "NoRecoil", function(v) if v then ensureGun() end end)
        Im.checkbox(L, "no spread", C.Gun, "NoSpread", function(v) if v then ensureGun() end end)
        Im.checkbox(L, "rapid fire", C.Gun, "Rapid", function(v) if v then ensureGun() end end)
        Im.slider(L, "rate mult", C.Gun, "RapidX", 1, 5, 0.5)
        Im.group(R, "ammo")
        Im.checkbox(R, "infinite ammo", C.Gun, "InfAmmo", function(v) if v then ensureGun() end end)
        Im.checkbox(R, "instant reload", C.Gun, "Reload", function(v) if v then ensureGun() end end)
    elseif name == "Skins" then
        Im.group(L, "changer")
        Im.checkbox(L, "enabled", C.Skin, "Enabled", function(v) if v then ensureSkins() end end)
        local wb = Im.button(L, "weapon: " .. tostring(C.Skin.Weapon), function() end)
        wb.MouseButton1Click:Connect(function()
            local ws = Skins.Weapons()
            if #ws == 0 then return end
            local i = 1
            for k, v in ipairs(ws) do if v == C.Skin.Weapon then i = k break end end
            C.Skin.Weapon = ws[(i % #ws) + 1]
            wb.Text = "weapon: " .. tostring(C.Skin.Weapon)
        end)
        local sb = Im.textbox(L, "skin name (exact)")
        sb.FocusLost:Connect(function() C.Skin.Skin = sb.Text end)
        local wb2 = Im.textbox(L, "wrap name (optional)")
        wb2.FocusLost:Connect(function() C.Skin.Wrap = wb2.Text end)
        Im.button(L, "APPLY", function()
            C.Skin.Skin = sb.Text C.Skin.Wrap = wb2.Text
            Skins.Apply(C)
        end)
        Im.group(R, "status")
        local st2 = Im.status(R, 80)
        st2.Text = "idle"
        task.spawn(function()
            while true do
                task.wait(1)
                pcall(function() st2.Text = "status: " .. C.Skin.Status end)
                if not st2.Parent then break end
            end
        end)
        local h = Im.status(R, 60)
        h.Text = "type exact skin name from locker. re-equip weapon after apply."
    elseif name == "Move" then
        Im.group(L, "movement")
        Im.checkbox(L, "speed", C.Move, "Speed")
        Im.slider(L, "walkspeed", C.Move, "SpeedV", 16, 120, 1)
        Im.checkbox(L, "fly [F]", C.Move, "Fly")
        Im.slider(L, "fly speed", C.Move, "FlyV", 10, 200, 5)
        Im.group(R, "extra")
        Im.checkbox(R, "noclip", C.Move, "Noclip")
        Im.checkbox(R, "inf jump", C.Move, "InfJump")
        Im.checkbox(R, "no knockback", C.Move, "Knock")
    elseif name == "Misc" then
        Im.group(L, "system")
        Im.checkbox(L, "anti afk", C.Misc, "AFK")
        Im.checkbox(L, "no shake", C.Misc, "NoShake")
        Im.checkbox(L, "fullbright", C.Misc, "Bright")
        Im.group(R, "info")
        local h = Im.status(R, 80)
        h.Text = "hold RMB/E = lock. F = fly. INS = menu. modular build: nl/modules/*.lua"
    end
end

if tabsBar then
    for _, n in ipairs(pages) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 72, 1, 0) b.BackgroundColor3 = Im.ROW
        b.Text = n b.TextColor3 = Im.DIM b.Font = Enum.Font.Code b.TextSize = 11
        b.AutoButtonColor = false b.Parent = tabsBar
        tabBtns[n] = b
        b.MouseButton1Click:Connect(function() cur = n paintTabs() buildPage(n) end)
    end
    paintTabs()
end
buildPage(cur)

getgenv().rivalspro = {cfg = C, Mods = Mods}
Common.notify("rivals.pro", "NL modular loaded | INS = menu")
print("rivals.pro NL modular ok")
