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

-- loading splash FIRST (before heavy loads) with progress bar
local splashGui, splashFill, splashTxt
do
    local parent
    local okH, h = pcall(function() return gethui and gethui() end)
    if okH and h then parent = h end
    if not parent then
        local lp0 = game:GetService("Players").LocalPlayer
        parent = lp0 and lp0:FindFirstChildOfClass("PlayerGui")
    end
    splashGui = Instance.new("ScreenGui")
    splashGui.Name = "rivalspro_load" splashGui.ResetOnSpawn = false splashGui.Parent = parent
    local sp = Instance.new("Frame")
    sp.Size = UDim2.new(0, 340, 0, 120) sp.Position = UDim2.new(0.5, -170, 0.5, -60)
    sp.BackgroundColor3 = Color3.fromRGB(13, 13, 17) sp.BorderSizePixel = 0 sp.Parent = splashGui
    Instance.new("UICorner", sp).CornerRadius = UDim.new(0, 8)
    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1, 0, 0, 30) sl.Position = UDim2.new(0, 0, 0, 12)
    sl.BackgroundTransparency = 1 sl.Text = "MEDUSA"
    sl.TextColor3 = Color3.new(1,1,1) sl.Font = Enum.Font.GothamBlack sl.TextSize = 20 sl.Parent = sp
    splashTxt = Instance.new("TextLabel")
    splashTxt.Size = UDim2.new(1, 0, 0, 16) splashTxt.Position = UDim2.new(0, 0, 0, 44)
    splashTxt.BackgroundTransparency = 1 splashTxt.Text = "loading..."
    splashTxt.TextColor3 = Color3.fromRGB(130,130,142) splashTxt.Font = Enum.Font.Gotham
    splashTxt.Parent = sp
    local sbar = Instance.new("Frame")
    sbar.Size = UDim2.new(1, -40, 0, 6) sbar.Position = UDim2.new(0, 20, 0, 72)
    sbar.BackgroundColor3 = Color3.fromRGB(45,45,55) sbar.BorderSizePixel = 0 sbar.Parent = sp
    Instance.new("UICorner", sbar).CornerRadius = UDim.new(1, 0)
    splashFill = Instance.new("Frame")
    splashFill.Size = UDim2.new(0, 0, 1, 0) splashFill.BorderSizePixel = 0
    splashFill.BackgroundColor3 = Color3.fromRGB(168,130,255) splashFill.Parent = sbar
    Instance.new("UICorner", splashFill).CornerRadius = UDim.new(1, 0)
end
local function prog(p, t)
    pcall(function()
        splashFill.Size = UDim2.new(math.clamp(p, 0, 1), 0, 1, 0)
        if t then splashTxt.Text = t end
    end)
    task.wait(0.05)
end

-- core + modules (separate files) with splash progress
local Common = loadModule("nl/modules/common.lua")
if not Common then warn("[nl] common failed") return end
prog(0.15, "core...")
local Aimbot = loadModule("nl/modules/aimbot.lua", Common)
prog(0.3, "aimbot...")
local Silent = loadModule("nl/modules/silent.lua", Common)
prog(0.42, "silent...")
local ESP = loadModule("nl/modules/esp.lua", Common)
prog(0.54, "esp...")
local GunM = loadModule("nl/modules/gunmods.lua", Common)
prog(0.66, "combat...")
local Move = loadModule("nl/modules/movement.lua", Common)
prog(0.76, "movement...")
local Skins = loadModule("nl/modules/skins.lua", Common)
prog(0.86, "skins...")
local Misc = loadModule("nl/modules/misc.lua", Common)
prog(0.93, "finishing...")
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

-- imgui menu (real build at end)

local pages = {"Aimbot", "Silent", "ESP", "Combat", "Skins", "Move", "Misc"}
local groups = {} -- page -> {left widgets parent, right}
local cur = "Aimbot"

-- real menu build: tabs created inside imgui (direct refs, no searching)
prog(0.96, "menu...")
local Im = loadModule("nl/ui/imgui.lua", Common, C, Mods)
if not Im then warn("[nl] ui failed") return end

local function clearCols()
    for _, c in ipairs({Im.left, Im.right}) do
        for _, w in ipairs(c:GetChildren()) do
            if not w:IsA("UIListLayout") and not w:IsA("UIPadding") then w:Destroy() end
        end
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
        Im.group(L, "step 1 - enable")
        Im.checkbox(L, "enabled", C.Skin, "Enabled", function(v) if v then ensureSkins() end end)
        Im.group(L, "step 2 - pick weapon (click)")
        do
            local ws = Skins.Weapons()
            for i = 1, math.min(#ws, 10) do
                local wname = ws[i]
                local wb = Im.button(L, (wname == C.Skin.Weapon and "> " or "") .. wname, function()
                    C.Skin.Weapon = wname
                    buildPage("Skins")
                end)
                if wname == C.Skin.Weapon then wb.BackgroundColor3 = Im.ACC end
            end
            if #ws == 0 then
                local h = Im.status(L, 30) h.Text = "weapons load after match start"
            end
        end
        Im.group(R, "step 3 - pick skin (click = apply)")
        do
            local list = Skins.List(24)
            if #list == 0 then
                local h = Im.status(R, 40)
                h.Text = "skin list appears when libs ready. or type name below."
            end
            for _, sname in ipairs(list) do
                Im.button(R, sname, function()
                    ensureSkins()
                    C.Skin.Skin = sname
                    C.Skin.Enabled = true
                    Skins.Apply(C)
                end)
            end
        end
        Im.group(R, "manual (exact name)")
        local sb = Im.textbox(R, "skin name (exact)")
        sb.FocusLost:Connect(function() C.Skin.Skin = sb.Text end)
        Im.button(R, "APPLY TYPED NAME", function()
            ensureSkins()
            C.Skin.Skin = sb.Text
            C.Skin.Enabled = true
            Skins.Apply(C)
        end)
        Im.group(R, "status")
        local st2 = Im.status(R, 60)
        st2.Text = "idle"
        task.spawn(function()
            while true do
                task.wait(1)
                local ok = pcall(function() st2.Text = "weapon: " .. C.Skin.Weapon .. "\nstatus: " .. C.Skin.Status .. "\nafter apply: re-equip weapon (swap slot)" end)
                if not ok or not st2.Parent then break end
            end
        end)
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

prog(1, "ready")
pcall(function() splashGui:Destroy() end)
-- destroy the splash that imgui.build also makes (we already showed ours)
Im.build(pages, cur, function(n) cur = n buildPage(n) end)
Im.finish()
buildPage(cur)
-- sync left category list with tabs
if Im.paintCat then Im.paintCat(pages, cur, function(n) cur = n buildPage(n) end) end

getgenv().rivalspro = {cfg = C, Mods = Mods}
Common.notify("rivals.pro", "NL modular loaded | INS = menu")
print("rivals.pro NL modular ok")
