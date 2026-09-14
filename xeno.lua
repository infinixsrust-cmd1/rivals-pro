-- rivals.pro PREMIUM | single file | paid executors
-- paste ALL into executor -> Execute in RIVALS
-- menu: RightShift | aim: hold RMB or E | fly: F
-- ASCII only, no external loads

pcall(function()
    local cg = game:GetService("CoreGui"):FindFirstChild("rivalspro")
    if cg then cg:Destroy() end
end)
pcall(function()
    local lp0 = game:GetService("Players").LocalPlayer
    local pg0 = lp0 and lp0:FindFirstChildOfClass("PlayerGui")
    local o = pg0 and pg0:FindFirstChild("rivalspro")
    if o then o:Destroy() end
end)
for _, d in ipairs(getgenv()._rp_draw or {}) do pcall(function() d:Remove() end) end
getgenv()._rp_draw = {}

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer
local function cam() return workspace.CurrentCamera end

local function notify(t, s)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = t, Text = s, Duration = 4})
    end)
end

-- ============ CONFIG ============
local C = {
    Aim = {Enabled=false, Mode="Hold", Key=Enum.KeyCode.E, Part="Head",
        Smooth=6, FOV=130, ShowFOV=true, Team=true, Wall=true, Dead=true,
        Pred=0.12, Sticky=true, Dot=false},
    Silent = {Enabled=false, Hit=80, Part="Head", Team=true, Wall=true, Dist=900},
    ESP = {Enabled=false, Box=true, Name=true, HP=true, Dist=true, Tracer=false,
        Team=true, MaxD=2000, Color=Color3.fromRGB(255,0,60)},
    Gun = {NoRecoil=false, NoSpread=false, Rapid=false, RapidX=2, InfAmmo=false, Reload=false},
    Move = {Speed=false, SpeedV=24, Fly=false, FlyV=50, Noclip=false, InfJump=false, Knock=false},
    Misc = {NoShake=true, Bright=false, AFK=true, Spec=true},
}
getgenv().rivalspro = {cfg = C}

-- ============ HELPERS (bugfixed) ============
local function charOf(p) return p and p.Character end
local function humOf(p)
    local ch = charOf(p)
    return ch and ch:FindFirstChildOfClass("Humanoid")
end
local function rootOf(p)
    local ch = charOf(p)
    return ch and ch:FindFirstChild("HumanoidRootPart")
end
local function alive(p)
    local h = humOf(p)
    return h ~= nil and h.Health > 0
end
local function forcefield(p)
    local ch = charOf(p)
    return ch and ch:FindFirstChildOfClass("ForceField") ~= nil
end
local function teammate(p)
    if not (p and LP) then return false end
    if p == LP then return true end
    local ok, r = pcall(function() return p.Team end)
    if not ok or r == nil then return false end
    local ok2, mine = pcall(function() return LP.Team end)
    if not ok2 or mine == nil then return false end
    return r == mine
end
local function partOf(ch, name)
    if not ch then return nil end
    if name == "Head" then
        return ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
    elseif name == "Chest" then
        return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
            or ch:FindFirstChild("HumanoidRootPart")
    elseif name == "Legs" then
        return ch:FindFirstChild("LowerTorso") or ch:FindFirstChild("HumanoidRootPart")
    elseif name == "Random" then
        local pool = {}
        for _, n in ipairs({"Head","UpperTorso","HumanoidRootPart","LowerTorso"}) do
            local pt = ch:FindFirstChild(n)
            if pt then pool[#pool+1] = pt end
        end
        if #pool == 0 then return nil end
        return pool[math.random(1, #pool)]
    end
    return ch:FindFirstChild("HumanoidRootPart")
end
local function visible(part)
    if not part then return false end
    local c = cam()
    if not c then return false end
    local myCh = charOf(LP)
    local org = c.CFrame.Position
    local dir = part.Position - org
    if dir.Magnitude < 1 then return true end
    local pr = RaycastParams.new()
    pr.FilterType = Enum.RaycastFilterType.Exclude
    local filt = {c}
    if myCh then filt[#filt+1] = myCh end
    if part.Parent then filt[#filt+1] = part.Parent end
    pr.FilterDescendantsInstances = filt
    pr.IgnoreWater = true
    local ok, r = pcall(function() return workspace:Raycast(org, dir, pr) end)
    if not ok then return true end
    if not r then return true end
    return (r.Position - part.Position).Magnitude < 5
end
local function predict(part, k)
    local ok, v = pcall(function() return part.Velocity end)
    if not ok or typeof(v) ~= "Vector3" then return part.Position end
    if v.Magnitude > 200 then return part.Position end
    return part.Position + v * math.clamp(k or 0, 0, 0.3)
end
local function toScreen(pos)
    local c = cam()
    if not c then return Vector2.new(0,0), false end
    local v, on = c:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on
end

-- ============ DRAW POOL ============
local function mkDraw(cls, props)
    local ok, d = pcall(function() return Drawing.new(cls) end)
    if not ok or not d then return nil end
    for k, v in pairs(props) do pcall(function() d[k] = v end) end
    d.Visible = false
    getgenv()._rp_draw[#getgenv()._rp_draw+1] = d
    return d
end
local FOVc = mkDraw("Circle", {Thickness=1.5, NumSides=64, Filled=false, Transparency=1})
local FOVdot = mkDraw("Circle", {Radius=3, Filled=true, Transparency=1})

-- ============ AIMBOT (rewritten) ============
local holding, toggled, target, targetName = false, false, nil, "none"
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == C.Aim.Key or i.UserInputType == Enum.UserInputType.MouseButton2 then
        if C.Aim.Mode == "Toggle" then toggled = not toggled else holding = true end
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode == C.Aim.Key or i.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = false
    end
end)
local function aimOn()
    if not C.Aim.Enabled then return false end
    if C.Aim.Mode == "Toggle" then return toggled end
    return holding or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end
local function validTarget(p)
    if p == LP then return false end
    if C.Aim.Team and teammate(p) then return false end
    if C.Aim.Dead and not alive(p) then return false end
    if forcefield(p) then return false end
    local ch = charOf(p)
    if not ch then return false end
    local pt = partOf(ch, C.Aim.Part)
    if not pt then return false end
    return true
end
local function pickTarget()
    local mp = UIS:GetMouseLocation()
    -- sticky first
    if C.Aim.Sticky and target and validTarget(target) then
        local pt = partOf(charOf(target), C.Aim.Part)
        if pt then
            local sp, on = toScreen(predict(pt, C.Aim.Pred))
            if on and (sp - mp).Magnitude < C.Aim.FOV then
                if not (C.Aim.Wall and not visible(pt)) then
                    targetName = target.Name
                    return target, pt
                end
            end
        end
        target, targetName = nil, "none"
    else
        target = nil
    end
    local best, bd, bp = nil, C.Aim.FOV, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if validTarget(p) then
            local pt = partOf(charOf(p), C.Aim.Part)
            if pt and not (C.Aim.Wall and not visible(pt)) then
                local sp, on = toScreen(predict(pt, C.Aim.Pred))
                if on then
                    local d = (sp - mp).Magnitude
                    if d < bd then best, bd, bp = p, d, pt end
                end
            end
        end
    end
    target = best
    targetName = best and best.Name or "none"
    return best, bp
end
RS.RenderStepped:Connect(function(dt)
    local show = C.Aim.Enabled and C.Aim.ShowFOV and FOVc
    if FOVc then
        FOVc.Visible = show and true or false
        if show then
            local mp = UIS:GetMouseLocation()
            FOVc.Position = mp
            FOVc.Radius = C.Aim.FOV
            FOVc.Color = (target and targetName ~= "none") and Color3.fromRGB(255,0,60) or Color3.fromRGB(255,255,255)
        end
    end
    if not aimOn() then target, targetName = nil, "none"
        if FOVdot then FOVdot.Visible = false end
        return
    end
    local _, pt = pickTarget()
    if FOVdot then
        if C.Aim.Dot and pt then
            local sp, on = toScreen(pt.Position)
            FOVdot.Visible = on
            if on then FOVdot.Position = sp FOVdot.Color = Color3.fromRGB(255,0,60) end
        else
            FOVdot.Visible = false
        end
    end
    if not pt then return end
    local c = cam()
    if not c then return end
    local goal = CFrame.new(c.CFrame.Position, predict(pt, C.Aim.Pred))
    -- framerate-independent smoothing: higher Smooth = slower
    local s = math.clamp(C.Aim.Smooth, 1, 20)
    local alpha = 1 - math.exp(-dt * (30 / s) * 2)
    alpha = math.clamp(alpha, 0.02, 1)
    c.CFrame = c.CFrame:Lerp(goal, alpha)
end)

-- ============ SILENT AIM ============
if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if C.Silent.Enabled and (m == "FireServer" or m == "InvokeServer") then
            local okN, nm = pcall(function() return tostring(self.Name) end)
            local n = okN and string.lower(nm) or ""
            if string.find(n, "shoot") or string.find(n, "fire") or string.find(n, "bullet") then
                if math.random(1, 100) <= C.Silent.Hit then
                    local mp = UIS:GetMouseLocation()
                    local bp2, bd2 = nil, 420
                    local myR = rootOf(LP)
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and alive(p) and not forcefield(p)
                            and not (C.Silent.Team and teammate(p)) then
                            local ch = charOf(p)
                            local pt = ch and (ch:FindFirstChild(C.Silent.Part) or ch:FindFirstChild("Head"))
                            if pt then
                                local skip = false
                                if myR and (myR.Position - pt.Position).Magnitude > C.Silent.Dist then skip = true end
                                if not skip and C.Silent.Wall and not visible(pt) then skip = true end
                                if not skip then
                                    local sp, on = toScreen(pt.Position)
                                    if on then
                                        local d = (sp - mp).Magnitude
                                        if d < bd2 then bp2, bd2 = pt, d end
                                    end
                                end
                            end
                        end
                    end
                    if bp2 then
                        local args = {...}
                        local pr2 = predict(bp2, 0.12)
                        for i, v in ipairs(args) do
                            if typeof(v) == "Vector3" then args[i] = pr2
                            elseif typeof(v) == "CFrame" then args[i] = CFrame.new(pr2) end
                        end
                        return old(self, unpack(args))
                    end
                end
            end
        end
        return old(self, ...)
    end)
end

-- ============ ESP ============
local espObjs = {}
local function espGet(p)
    if espObjs[p] then return espObjs[p] end
    local box = mkDraw("Square", {Thickness=1.5, Filled=false, Transparency=1})
    local hp = mkDraw("Square", {Filled=true, Transparency=1})
    local nm = mkDraw("Text", {Size=13, Center=true, Outline=true, Transparency=1})
    local ds = mkDraw("Text", {Size=12, Center=true, Outline=true, Transparency=1})
    local tr = mkDraw("Line", {Thickness=1.5, Transparency=0.9})
    if not (box and hp and nm and ds and tr) then return nil end
    espObjs[p] = {box=box, hp=hp, nm=nm, ds=ds, tr=tr}
    return espObjs[p]
end
Players.PlayerRemoving:Connect(function(p)
    local s = espObjs[p]
    if s then for _, d in pairs(s) do pcall(function() d.Visible = false end) end espObjs[p] = nil end
end)
RS.RenderStepped:Connect(function()
    if FOVc == nil and next(espObjs) == nil then return end
    for _, p in ipairs(Players:GetPlayers()) do
        local s = espGet(p)
        if not s then continue end
        local show = C.ESP.Enabled and p ~= LP and alive(p) and not forcefield(p)
            and not (C.ESP.Team and teammate(p))
        local ch = charOf(p)
        local rt = ch and ch:FindFirstChild("HumanoidRootPart")
        local hd = ch and ch:FindFirstChild("Head")
        if show and (not rt or not hd) then show = false end
        local myR = rootOf(LP)
        local dd = (myR and rt) and (myR.Position - rt.Position).Magnitude or 0
        if show and dd > C.ESP.MaxD then show = false end
        if not show then
            for _, d in pairs(s) do d.Visible = false end
            continue
        end
        local c = cam()
        local tv, ton = c:WorldToViewportPoint(hd.Position + Vector3.new(0, 0.7, 0))
        local bv, bon = c:WorldToViewportPoint(rt.Position - Vector3.new(0, 3, 0))
        if not (ton and bon) then
            for _, d in pairs(s) do d.Visible = false end
            continue
        end
        local h = math.abs(bv.Y - tv.Y)
        if h < 4 or h > 2500 then
            for _, d in pairs(s) do d.Visible = false end
            continue
        end
        local w, x, y = h * 0.55, tv.X - (h * 0.55) / 2, tv.Y
        s.box.Visible = C.ESP.Box
        if C.ESP.Box then
            s.box.Size = Vector2.new(w, h) s.box.Position = Vector2.new(x, y)
            s.box.Color = C.ESP.Color
        end
        local hu = humOf(p)
        local fr = hu and math.clamp(hu.Health / math.max(hu.MaxHealth, 1), 0, 1) or 1
        s.hp.Visible = C.ESP.HP
        if C.ESP.HP then
            local fh = h * fr
            s.hp.Size = Vector2.new(3, fh)
            s.hp.Position = Vector2.new(x - 6, y + (h - fh))
            s.hp.Color = Color3.fromRGB(255 - math.floor(255 * fr), math.floor(255 * fr), 0)
        end
        s.nm.Visible = C.ESP.Name
        if C.ESP.Name then
            s.nm.Text = p.Name s.nm.Position = Vector2.new(tv.X, y - 16)
            s.nm.Color = Color3.new(1, 1, 1)
        end
        s.ds.Visible = C.ESP.Dist
        if C.ESP.Dist then
            s.ds.Text = "[" .. math.floor(dd) .. "m]"
            s.ds.Position = Vector2.new(tv.X, y + h + 1)
            s.ds.Color = Color3.new(1, 1, 1)
        end
        s.tr.Visible = C.ESP.Tracer
        if C.ESP.Tracer then
            s.tr.From = Vector2.new(c.ViewportSize.X / 2, c.ViewportSize.Y)
            s.tr.To = Vector2.new(tv.X, y + h / 2)
            s.tr.Color = C.ESP.Color
        end
    end
end)

-- ============ GUNMODS ============
task.spawn(function()
    while true do
        task.wait(2.5)
        pcall(function()
            local G = C.Gun
            if not (G.NoRecoil or G.NoSpread or G.Rapid or G.InfAmmo) then return end
            for _, o in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if o:IsA("ModuleScript") then
                    local ok, t = pcall(require, o)
                    if ok and typeof(t) == "table" then
                        if G.NoRecoil then
                            if t.Recoil ~= nil then t.Recoil = 0 end
                            for _, k in ipairs({"RecoilX","RecoilY","CameraKick","Kickback"}) do
                                if t[k] ~= nil then t[k] = 0 end
                            end
                        end
                        if G.NoSpread and t.Spread ~= nil then t.Spread = 0 end
                        if G.Rapid and typeof(t.FireRate) == "number" and not t._rp then
                            t.FireRate = t.FireRate * C.Gun.RapidX t._rp = true
                        end
                        if G.InfAmmo and t.Ammo ~= nil then t.Ammo = 999 end
                    end
                end
            end
            if G.Reload then
                local ch = charOf(LP)
                if ch then
                    for _, v in ipairs(ch:GetDescendants()) do
                        if v:IsA("NumberValue") and string.lower(v.Name) == "reloadtime" then
                            v.Value = 0.01
                        end
                    end
                end
            end
        end)
    end
end)

-- ============ MOVEMENT ============
RS.Heartbeat:Connect(function()
    if C.Move.Speed then
        local h = humOf(LP)
        if h and h.Health > 0 then h.WalkSpeed = C.Move.SpeedV end
    end
    if C.Move.Knock then
        local r = rootOf(LP)
        if r then
            local v = r.AssemblyLinearVelocity
            if v.Magnitude > 60 then
                r.AssemblyLinearVelocity = Vector3.new(math.clamp(v.X,-30,30), v.Y, math.clamp(v.Z,-30,30))
            end
        end
    end
end)
RS.Stepped:Connect(function()
    if C.Move.Noclip then
        local ch = charOf(LP)
        if ch then
            for _, pt in ipairs(ch:GetDescendants()) do
                if pt:IsA("BasePart") then pt.CanCollide = false end
            end
        end
    end
end)
local flyConn, flyBV, flyBG = nil, nil, nil
local function flyOff()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    pcall(function() if flyBV then flyBV:Destroy() end end)
    pcall(function() if flyBG then flyBG:Destroy() end end)
    flyBV, flyBG = nil, nil
end
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.Space and C.Move.InfJump then
        local h = humOf(LP)
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
    if i.KeyCode == Enum.KeyCode.F and C.Move.Fly then
        getgenv()._fly = not getgenv()._fly
        if getgenv()._fly then
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9) flyBV.Velocity = Vector3.zero
            flyBG = Instance.new("BodyGyro")
            flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyConn = RS.Heartbeat:Connect(function()
                local r = rootOf(LP)
                local c = cam()
                if not r or not c then return end
                if not flyBV.Parent then flyBV.Parent = r end
                if not flyBG.Parent then flyBG.Parent = r end
                flyBG.CFrame = c.CFrame
                local d = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + c.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - c.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + c.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - c.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
                flyBV.Velocity = d.Magnitude > 0 and (d.Unit * C.Move.FlyV) or Vector3.zero
            end)
        else
            flyOff()
        end
    end
end)

-- ============ MISC ============
if C.Misc.AFK then
    pcall(function()
        local vu = game:GetService("VirtualUser")
        LP.Idled:Connect(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end)
    end)
end
RS.RenderStepped:Connect(function()
    if C.Misc.NoShake then
        local h = humOf(LP)
        if h then h.CameraOffset = Vector3.zero end
    end
    if C.Misc.Bright then
        Lighting.Brightness = 2 Lighting.ClockTime = 14
        Lighting.FogEnd = 1e5 Lighting.GlobalShadows = false
    end
end)

-- ============ PREMIUM GUI ============
local ACC = Color3.fromRGB(255, 0, 60)
local BG = Color3.fromRGB(10, 10, 14)
local PANEL = Color3.fromRGB(18, 18, 24)
local ROWC = Color3.fromRGB(24, 24, 32)
local parentGui
do
    local okH, h = pcall(function() return gethui and gethui() end)
    if okH and h then parentGui = h
    else
        local okC, cg = pcall(function() return game:GetService("CoreGui") end)
        local probe = Instance.new("ScreenGui")
        local okP = pcall(function() probe.Parent = cg probe:Destroy() end)
        parentGui = (okC and okP) and cg or LP:WaitForChild("PlayerGui")
    end
end
local gui = Instance.new("ScreenGui")
gui.Name = "rivalspro" gui.ResetOnSpawn = false gui.Parent = parentGui

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 520, 0, 360) win.Position = UDim2.new(0.5, -260, 0.5, -180)
win.BackgroundColor3 = BG win.BorderSizePixel = 0 win.Active = true win.Draggable = true
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local ws = Instance.new("UIStroke", win) ws.Color = ACC ws.Thickness = 1.5

-- top bar
local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 44) top.BackgroundColor3 = PANEL top.BorderSizePixel = 0 top.Parent = win
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 10)
local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(0.6, 0, 1, 0) ttl.Position = UDim2.new(0, 14, 0, 0)
ttl.BackgroundTransparency = 1 ttl.Text = "RIVALS.PRO  v2.0"
ttl.TextColor3 = Color3.new(1,1,1) ttl.Font = Enum.Font.GothamBlack ttl.TextSize = 15
ttl.TextXAlignment = Enum.TextXAlignment.Left ttl.Parent = top
local st = Instance.new("TextLabel")
st.Name = "status" st.Size = UDim2.new(0.4, -14, 1, 0) st.Position = UDim2.new(0.6, 0, 0, 0)
st.BackgroundTransparency = 1 st.Text = "target: none"
st.TextColor3 = Color3.fromRGB(140,140,150) ttl.Font = Enum.Font.Gotham ttl.TextSize = 11
st.TextXAlignment = Enum.TextXAlignment.Right st.Font = Enum.Font.Gotham st.Parent = top

-- sidebar
local side = Instance.new("Frame")
side.Size = UDim2.new(0, 120, 1, -56) side.Position = UDim2.new(0, 8, 0, 50)
side.BackgroundColor3 = PANEL side.BorderSizePixel = 0 side.Parent = win
Instance.new("UICorner", side).CornerRadius = UDim.new(0, 8)
local sLay = Instance.new("UIListLayout", side)
sLay.Padding = UDim.new(0, 4) sLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
sLay.VerticalAlignment = Enum.VerticalAlignment.Top
local sPad = Instance.new("UIPadding", side)
sPad.PaddingTop = UDim.new(0, 6) sPad.PaddingLeft = UDim.new(0, 6) sPad.PaddingRight = UDim.new(0, 6)

-- pages
local pages = {}
local tabBtns = {}
local pageNames = {"Aim", "Visuals", "Combat", "Move", "Misc"}
for _, nm in ipairs(pageNames) do
    local pg = Instance.new("ScrollingFrame")
    pg.Name = nm pg.Size = UDim2.new(1, -144, 1, -62) pg.Position = UDim2.new(0, 136, 0, 50)
    pg.BackgroundTransparency = 1 pg.ScrollBarThickness = 3 pg.Visible = false
    pg.CanvasSize = UDim2.new(0, 0, 0, 800) pg.Parent = win
    local ll = Instance.new("UIListLayout", pg) ll.Padding = UDim.new(0, 4)
    pages[nm] = pg
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 32) b.BackgroundColor3 = ROWC
    b.Text = nm b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold b.TextSize = 12 b.Parent = side
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    tabBtns[nm] = b
    b.MouseButton1Click:Connect(function()
        for n, p2 in pairs(pages) do p2.Visible = (n == nm) end
        for n, b2 in pairs(tabBtns) do
            b2.BackgroundColor3 = (n == nm) and ACC or ROWC
        end
    end)
end
pages["Aim"].Visible = true
tabBtns["Aim"].BackgroundColor3 = ACC

-- widgets
local function section(pg, txt)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 20) l.BackgroundTransparency = 1
    l.Text = string.upper(txt) l.TextColor3 = ACC
    l.Font = Enum.Font.GothamBold l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = pg
end
local function toggle(pg, label, tbl, key, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 30) b.BackgroundColor3 = ROWC
    b.TextColor3 = Color3.new(1,1,1) b.Font = Enum.Font.Gotham b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left b.AutoButtonColor = false b.Parent = pg
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8) dot.Position = UDim2.new(1, -20, 0.5, -4)
    dot.BorderSizePixel = 0 dot.Parent = b
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local function rf()
        b.Text = "  " .. label
        dot.BackgroundColor3 = tbl[key] and ACC or Color3.fromRGB(70, 70, 80)
    end
    rf()
    b.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        if cb then pcall(cb, tbl[key]) end
        rf()
    end)
end
local function slider(pg, label, tbl, key, mn, mx, sp)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -4, 0, 30) f.BackgroundColor3 = ROWC f.Parent = pg
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -70, 1, 0) t.Position = UDim2.new(0, 8, 0, 0)
    t.BackgroundTransparency = 1 t.TextColor3 = Color3.new(1,1,1)
    t.Font = Enum.Font.Gotham t.TextSize = 12 t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = f
    local function rf()
        local v = tbl[key]
        if typeof(v) == "number" and sp < 1 then v = math.floor(v / sp + 0.5) * sp end
        t.Text = label .. ": " .. tostring(v)
    end
    rf()
    local m = Instance.new("TextButton")
    m.Size = UDim2.new(0, 28, 0, 22) m.Position = UDim2.new(1, -62, 0.5, -11)
    m.Text = "-" m.BackgroundColor3 = Color3.fromRGB(40,40,50)
    m.TextColor3 = Color3.new(1,1,1) m.Font = Enum.Font.GothamBold m.TextSize = 13 m.Parent = f
    Instance.new("UICorner", m).CornerRadius = UDim.new(0, 5)
    local p = Instance.new("TextButton")
    p.Size = UDim2.new(0, 28, 0, 22) p.Position = UDim2.new(1, -32, 0.5, -11)
    p.Text = "+" p.BackgroundColor3 = ACC
    p.TextColor3 = Color3.new(1,1,1) p.Font = Enum.Font.GothamBold p.TextSize = 13 m.Parent = f
    p.Parent = f
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, 5)
    m.MouseButton1Click:Connect(function()
        tbl[key] = math.clamp(tbl[key] - sp, mn, mx) rf()
    end)
    p.MouseButton1Click:Connect(function()
        tbl[key] = math.clamp(tbl[key] + sp, mn, mx) rf()
    end)
end
local function cycle(pg, label, tbl, key, opts)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 30) b.BackgroundColor3 = ROWC
    b.TextColor3 = Color3.new(1,1,1) b.Font = Enum.Font.Gotham b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left b.AutoButtonColor = false b.Parent = pg
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local function rf() b.Text = "  " .. label .. ": < " .. tostring(tbl[key]) .. " >" end
    rf()
    b.MouseButton1Click:Connect(function()
        local i = 1
        for k, v in ipairs(opts) do if v == tbl[key] then i = k break end end
        tbl[key] = opts[(i % #opts) + 1]
        rf()
    end)
end

-- AIM page
section(pages["Aim"], "lock")
toggle(pages["Aim"], "Aimbot enabled", C.Aim, "Enabled")
cycle(pages["Aim"], "Mode", C.Aim, "Mode", {"Hold", "Toggle"})
cycle(pages["Aim"], "Target bone", C.Aim, "Part", {"Head", "Chest", "Legs", "Random"})
slider(pages["Aim"], "Smoothness", C.Aim, "Smooth", 1, 20, 1)
slider(pages["Aim"], "FOV px", C.Aim, "FOV", 20, 400, 5)
slider(pages["Aim"], "Prediction", C.Aim, "Pred", 0, 0.3, 0.01)
section(pages["Aim"], "checks")
toggle(pages["Aim"], "Show FOV circle", C.Aim, "ShowFOV")
toggle(pages["Aim"], "Target dot", C.Aim, "Dot")
toggle(pages["Aim"], "Team check", C.Aim, "Team")
toggle(pages["Aim"], "Wall check", C.Aim, "Wall")
toggle(pages["Aim"], "Sticky target", C.Aim, "Sticky")
section(pages["Aim"], "silent")
toggle(pages["Aim"], "Silent aim", C.Silent, "Enabled")
slider(pages["Aim"], "Hit chance %", C.Silent, "Hit", 1, 100, 1)
slider(pages["Aim"], "Max dist", C.Silent, "Dist", 100, 3000, 50)

-- VISUALS page
section(pages["Visuals"], "esp")
toggle(pages["Visuals"], "ESP enabled", C.ESP, "Enabled")
toggle(pages["Visuals"], "Boxes", C.ESP, "Box")
toggle(pages["Visuals"], "Names", C.ESP, "Name")
toggle(pages["Visuals"], "Health bars", C.ESP, "HP")
toggle(pages["Visuals"], "Distance", C.ESP, "Dist")
toggle(pages["Visuals"], "Tracers", C.ESP, "Tracer")
toggle(pages["Visuals"], "Team check", C.ESP, "Team")
slider(pages["Visuals"], "Max distance", C.ESP, "MaxD", 200, 5000, 100)
section(pages["Visuals"], "world")
toggle(pages["Visuals"], "Fullbright", C.Misc, "Bright")
toggle(pages["Visuals"], "No camera shake", C.Misc, "NoShake")

-- COMBAT page
section(pages["Combat"], "weapon")
toggle(pages["Combat"], "No recoil", C.Gun, "NoRecoil")
toggle(pages["Combat"], "No spread", C.Gun, "NoSpread")
toggle(pages["Combat"], "Rapid fire", C.Gun, "Rapid")
slider(pages["Combat"], "Fire rate mult", C.Gun, "RapidX", 1, 5, 0.5)
toggle(pages["Combat"], "Infinite ammo", C.Gun, "InfAmmo")
toggle(pages["Combat"], "Instant reload", C.Gun, "Reload")

-- MOVE page
section(pages["Move"], "movement")
toggle(pages["Move"], "Speed", C.Move, "Speed")
slider(pages["Move"], "WalkSpeed", C.Move, "SpeedV", 16, 120, 1)
toggle(pages["Move"], "Fly [F]", C.Move, "Fly")
slider(pages["Move"], "Fly speed", C.Move, "FlyV", 10, 200, 5)
toggle(pages["Move"], "Noclip", C.Move, "Noclip")
toggle(pages["Move"], "Infinite jump", C.Move, "InfJump")
toggle(pages["Move"], "No knockback", C.Move, "Knock")

-- MISC page
section(pages["Misc"], "system")
toggle(pages["Misc"], "Anti AFK", C.Misc, "AFK")
toggle(pages["Misc"], "No camera shake", C.Misc, "NoShake")
toggle(pages["Misc"], "Fullbright", C.Misc, "Bright")
section(pages["Misc"], "info")
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -4, 0, 60) info.BackgroundColor3 = ROWC
info.TextColor3 = Color3.fromRGB(160,160,170) info.Font = Enum.Font.Gotham info.TextSize = 11
info.TextWrapped = true
info.Text = "Hold RMB or E to lock. F toggles fly. RightShift hides menu."
info.Parent = pages["Misc"]
Instance.new("UICorner", info).CornerRadius = UDim.new(0, 6)

UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.RightShift then win.Visible = not win.Visible end
end)

-- live status
task.spawn(function()
    while true do
        task.wait(0.25)
        pcall(function()
            local fps = math.floor(1 / math.max(RS.RenderStepped:Wait(), 1e-4))
            st.Text = "target: " .. targetName .. "  |  " .. tostring(fps) .. " fps"
        end)
    end
end)

notify("rivals.pro", "PREMIUM v2.0 loaded | RightShift = menu")
print("rivals.pro premium v2.0 ok")
