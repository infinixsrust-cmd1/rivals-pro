-- rivals.pro NL | init.lua (entry for modular build)
-- usage: loadstring(game:HttpGet(BASE.."/nl/init.lua"))()
-- ASCII only.

local BASE = getgenv().RIVALSPRO_BASE or "https://raw.githubusercontent.com/infinixsrust-cmd1/rivals-pro/main/src"

-- SINGLE HttpGet bundle (Rivals chokes on many sequential HttpGets).
-- bundle file: src/nl_bundle.txt with --@@FILE:name markers.
local Bundle = {}
local function loadBundle()
    -- cachebuster: executor/CDN cache stale bundles otherwise
    local url = BASE .. "/nl_bundle.txt?x=" .. tostring(os.time())
    local ok, src = pcall(game.HttpGet, game, url)
    if not ok or not src or #src < 1000 then
        return false, "bundle http fail (" .. tostring(src):sub(1, 80) .. ")"
    end
    local cur, buf = nil, {}
    local function flush()
        if cur and #buf > 0 then
            Bundle[cur] = table.concat(buf, "\n")
        end
        buf = {}
    end
    for line in (src .. "\n"):gmatch("(.-)\n") do
        local m = line:match("^%-%-@@FILE:(.+)$")
        if m then
            flush()
            cur = m:gsub("%s+$", "")
        elseif line:match("^%-%-@@END") then
            flush()
            cur = nil
        elseif cur then
            buf[#buf+1] = line
        end
    end
    flush()
    return true
end

local function loadModule(name, ...)
    local src = Bundle[name]
    if not src then
        return nil
    end
    local fn, err = loadstring(src)
    if not fn then warn("[nl] load fail: " .. name .. " " .. tostring(err)) return nil end
    local ok2, mod = pcall(fn, ...)
    if not ok2 then warn("[nl] run fail: " .. name .. " " .. tostring(mod)) return nil end
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
        Pred=0.12, Sticky=true, Dot=false, FP=true, Lock=false},
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

-- core + modules from ONE bundle fetch (fast in Rivals)
prog(0.1, "downloading...")
local okB, errB = loadBundle()
if not okB then
    pcall(function()
        splashTxt.Text = "ERR: " .. tostring(errB)
    end)
    warn("[nl] " .. tostring(errB))
    return
end
local Common = loadModule("common.lua")
if not Common then
    pcall(function() splashTxt.Text = "ERR: common" end)
    warn("[nl] common failed") return
end
prog(0.3, "aimbot...")
local Aimbot = loadModule("aimbot.lua", Common)
prog(0.42, "silent...")
local Silent = loadModule("silent.lua", Common)
prog(0.54, "esp...")
local ESP = loadModule("esp.lua", Common)
prog(0.66, "combat...")
local GunM = loadModule("gunmods.lua", Common)
prog(0.76, "movement...")
local Move = loadModule("movement.lua", Common)
prog(0.86, "skins...")
local Skins = loadModule("skins.lua", Common)
prog(0.93, "finishing...")
local Misc = loadModule("misc.lua", Common)
prog(0.95, "config...")
local Cfg = loadModule("cfg.lua", Common)
if not (Aimbot and ESP and Move and Misc) then
    pcall(function() splashTxt.Text = "ERR: modules" end)
    warn("[nl] modules failed") return
end

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

local pages = {"Aimbot", "Silent", "ESP", "Combat", "Skins", "Move", "Misc", "Config"}
local groups = {} -- page -> {left widgets parent, right}
local cur = "Aimbot"

-- real menu build: tabs created inside imgui (direct refs, no searching)
prog(0.96, "menu...")
local Im = loadModule("imgui.lua", Common, C, Mods)
if not Im then
    pcall(function() splashTxt.Text = "ERR: menu" end)
    warn("[nl] ui failed") return
end

local function safeBuild(n)
    cur = n
    local ok, err = pcall(buildPage, n)
    if not ok then
        warn("[nl] page " .. tostring(n) .. ": " .. tostring(err))
        pcall(function()
            local e = Im.status(Im.left, 60)
            e.Text = "page error: " .. tostring(err):sub(1, 120)
        end)
    end
end
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
        Im.checkbox(L, "AIMLOCK (hard snap)", C.Aim, "Lock")
        Im.combo(L, "mode", C.Aim, "Mode", {"Hold", "Toggle"})
        Im.combo(L, "bone", C.Aim, "Part", {"Head", "Chest", "Legs", "Random"})
        Im.slider(L, "smoothness", C.Aim, "Smooth", 1, 20, 1)
        Im.slider(L, "fov", C.Aim, "FOV", 20, 400, 5)
        Im.group(R, "assist")
        Im.slider(R, "prediction", C.Aim, "Pred", 0, 0.3, 0.01)
        Im.checkbox(R, "mouse move - 1st person", C.Aim, "FP")
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
        Im.group(L, "unlock all")
        Im.button(L, "UNLOCK ALL SKINS", function()
            ensureSkins()
            C.Skin.Enabled = true
            C.Skin.Status = "unlocking..."
        end)
        Im.button(L, "REFRESH LIST", function()
            buildPage("Skins")
        end)
        Im.group(L, "status")
        local stTop = Im.status(L, 40)
        stTop.Text = "status: " .. C.Skin.Status
        task.spawn(function()
            while true do
                task.wait(1)
                local ok = pcall(function() stTop.Text = "status: " .. C.Skin.Status end)
                if not ok or not stTop.Parent then break end
            end
        end)
        Im.group(L, "pick skin (click = wear)")
        do
            local list = {}
            if Skins and Skins.List then
                list = Skins.List(24)
            else
                local h = Im.status(L, 40)
                h.Text = "skins module failed to load: re-execute"
            end
            if #list == 0 then
                local h = Im.status(L, 40)
                h.Text = "empty: UNLOCK, wait unlocked, REFRESH LIST"
            end
            for _, sname in ipairs(list) do
                Im.button(L, sname, function()
                    Skins.Wear(C, sname)
                end)
            end
        end
        Im.group(R, "manual")
        local sb = Im.textbox(R, "exact skin name")
        Im.button(R, "WEAR TYPED", function()
            Skins.Wear(C, sb.Text)
        end)
        Im.group(R, "help")
        local st2 = Im.status(R, 100)
        st2.Text = "1. UNLOCK ALL SKINS\n2. wait unlocked\n3. REFRESH LIST\n4. click skin\n5. re-equip weapon\nlocker locks stay: wear HERE"
    elseif name == "Config" then
        Im.group(L, "config")
        local nb = Im.textbox(L, "name (default)")
        Im.button(L, "SAVE", function()
            local ok, msg = Cfg.save(C, nb.Text)
            Common.notify("cfg", ok and ("saved " .. Cfg.cur) or ("save fail: " .. tostring(msg)))
        end)
        Im.button(L, "LOAD", function()
            local ok, msg = Cfg.load(C, nb.Text)
            Common.notify("cfg", ok and ("loaded (" .. tostring(msg) .. ")") or ("load fail: " .. tostring(msg)))
            if ok then buildPage("Config") end
        end)
        Im.group(R, "info")
        local hc = Im.status(R, 90)
        hc.Text = "saves toggles + sliders to rivals-pro/<name>.lua. keybinds and colors are not saved."
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
local okBuild, errBuild = pcall(function()
    Im.build(pages, cur, function(n) safeBuild(n) end)
end)
if not okBuild then
    warn("[nl] menu build failed: " .. tostring(errBuild))
    Common.notify("menu error", tostring(errBuild))
    return
end
Im.finish()
-- synced navigation: tabs + left list always agree
local function go(n) Im.select(n, function(nn) safeBuild(nn) end) end
-- rewire tab buttons through select (built inside imgui)
for n, b in pairs(Im.tabBtns) do
    -- clear old connections by cloning
    local nb = b:Clone()
    nb.Parent = b.Parent
    b:Destroy()
    Im.tabBtns[n] = nb
    nb.MouseButton1Click:Connect(function() go(n) end)
end
go(cur)

getgenv().rivalspro = {cfg = C, Mods = Mods}
Common.notify("rivals.pro", "NL v4 guarded | INS = menu")
print("rivals.pro NL v4 guarded ok")
