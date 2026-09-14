-- rivals.pro XENO build | single file, no HttpGet
-- вставь ВЕСЬ файл в Xeno -> Execute в игре RIVALS
-- меню: RightShift | аим: держать RMB или E

-- ═══ защита от двойного запуска ═══
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("rivalspro")
    if old then old:Destroy() end
end)
pcall(function()
    local plr = game:GetService("Players").LocalPlayer
    local old2 = plr and plr:FindFirstChildOfClass("PlayerGui"):FindFirstChild("rivalspro")
    if old2 then old2:Destroy() end
end)

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function Notify(t, s)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = t, Text = s, Duration = 4})
    end)
end

-- ═══ конфиг ═══
local C = {
    Aim = {Enabled=false, Key=Enum.KeyCode.E, Smooth=8, FOV=120, ShowFOV=true, Team=true, Wall=true, Pred=0.135, Part="Head"},
    Silent = {Enabled=false, Hit=80, Part="Head", Team=true, Wall=true},
    ESP = {Enabled=false, Box=true, Name=true, HP=true, Dist=true, Tracer=false, Team=true, Color=Color3.fromRGB(255,0,60)},
    Gun = {NoRecoil=false, NoSpread=false, Rapid=false, RapidX=2, InfAmmo=false},
    Move = {Speed=false, SpeedV=24, Fly=false, FlyV=50, Noclip=false, InfJump=false},
    Misc = {NoShake=true, Bright=false},
}
getgenv().rivalspro_cfg = C

-- ═══ хелперы ═══
local function alive(p)
    local ch = p and p.Character
    if not ch then return false end
    local h = ch:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function teammate(p)
    if p.Team and LP.Team and p.Team == LP.Team then return true end
    return false
end
local function visible(part)
    local org = Camera.CFrame.Position
    local dir = part.Position - org
    local pr = RaycastParams.new()
    pr.FilterType = Enum.RaycastFilterType.Exclude
    pr.FilterDescendantsInstances = {LP.Character, part.Parent, Camera}
    pr.IgnoreWater = true
    local r = workspace:Raycast(org, dir, pr)
    if not r then return true end
    return (r.Position - part.Position).Magnitude < 4
end
local function predict(part, k)
    local ok, v = pcall(function() return part.Velocity end)
    if not ok or not v then return part.Position end
    return part.Position + v * k
end
local function targetPart(ch, name)
    if name == "Head" then return ch:FindFirstChild("Head") end
    return ch:FindFirstChild("HumanoidRootPart")
end

-- ═══ AIMBOT ═══
local holding, toggled, target = false, false, nil
local hasDrawing, FOVc = pcall(function() return Drawing.new("Circle") end)
if hasDrawing and FOVc then
    FOVc.Thickness, FOVc.NumSides, FOVc.Filled, FOVc.Transparency = 1.5, 64, false, 1
end
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == C.Aim.Key or i.UserInputType == Enum.UserInputType.MouseButton2 then holding = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode == C.Aim.Key or i.UserInputType == Enum.UserInputType.MouseButton2 then holding = false end
end)
local function aimActive()
    if not C.Aim.Enabled then return false end
    return holding or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end
local function closest()
    local mp = UIS:GetMouseLocation()
    local best, bd, bp = nil, C.Aim.FOV, nil
    if target then
        local ok = (target.Parent and target ~= LP and alive(target))
        if ok then
            local pt = targetPart(target.Character, C.Aim.Part)
            if pt then
                local sp, on = Camera:WorldToViewportPoint(predict(pt, C.Aim.Pred))
                if on and (Vector2.new(sp.X,sp.Y)-mp).Magnitude < C.Aim.FOV then
                    if not (C.Aim.Wall and not visible(pt)) then return target, pt end
                end
            end
        end
        target = nil
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and alive(p) then
            if not (C.Aim.Team and teammate(p)) then
                local pt = targetPart(p.Character, C.Aim.Part)
                if pt and not (C.Aim.Wall and not visible(pt)) then
                    local sp, on = Camera:WorldToViewportPoint(predict(pt, C.Aim.Pred))
                    if on then
                        local d = (Vector2.new(sp.X,sp.Y)-mp).Magnitude
                        if d < bd then best, bd, bp = p, d, pt end
                    end
                end
            end
        end
    end
    if best then target = best end
    return best, bp
end
RS.RenderStepped:Connect(function()
    if hasDrawing and FOVc then
        local v = C.Aim.Enabled and C.Aim.ShowFOV
        FOVc.Visible = v
        if v then FOVc.Position, FOVc.Radius, FOVc.Color = UIS:GetMouseLocation(), C.Aim.FOV, Color3.new(1,1,1) end
    end
    if not aimActive() then target = nil return end
    local _, pt = closest()
    if pt then
        local goal = CFrame.new(Camera.CFrame.Position, predict(pt, C.Aim.Pred))
        Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(1/C.Aim.Smooth, 0.05, 1))
    end
end)

-- ═══ SILENT AIM (только если executor умеет hook) ═══
if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if C.Silent.Enabled and (m == "FireServer" or m == "InvokeServer") then
            local n = string.lower(tostring(self.Name or ""))
            if string.find(n,"shoot") or string.find(n,"fire") or string.find(n,"bullet") then
                if math.random(1,100) <= C.Silent.Hit then
                    local mp = UIS:GetMouseLocation()
                    local bp2, bd2 = nil, 400
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and alive(p) and not (C.Silent.Team and teammate(p)) then
                            local pt = p.Character and (p.Character:FindFirstChild(C.Silent.Part) or p.Character:FindFirstChild("Head"))
                            if pt and not (C.Silent.Wall and not visible(pt)) then
                                local sp, on = Camera:WorldToViewportPoint(pt.Position)
                                if on then
                                    local d = (Vector2.new(sp.X,sp.Y)-mp).Magnitude
                                    if d < bd2 then bp2, bd2 = pt, d end
                                end
                            end
                        end
                    end
                    if bp2 then
                        local args = {...}
                        local pr2 = predict(bp2, 0.135)
                        for i,v in ipairs(args) do
                            if typeof(v)=="Vector3" then args[i]=pr2
                            elseif typeof(v)=="CFrame" then args[i]=CFrame.new(pr2) end
                        end
                        return old(self, unpack(args))
                    end
                end
            end
        end
        return old(self, ...)
    end)
end

-- ═══ ESP (Drawing, с защитой) ═══
local espObjs = {}
local function espGet(p)
    if not espObjs[p] then
        local ok, set = pcall(function()
            local function mk(cl, pr2)
                local d = Drawing.new(cl)
                for k,v in pairs(pr2) do d[k]=v end
                d.Visible=false return d
            end
            return {
                box = mk("Square",{Thickness=1.5,Filled=false,Transparency=1}),
                hp = mk("Square",{Filled=true,Transparency=1}),
                nm = mk("Text",{Size=13,Center=true,Outline=true,Transparency=1}),
                ds = mk("Text",{Size=12,Center=true,Outline=true,Transparency=1}),
                tr = mk("Line",{Thickness=1.5,Transparency=0.9}),
            }
        end)
        if ok then espObjs[p]=set end
    end
    return espObjs[p]
end
Players.PlayerRemoving:Connect(function(p)
    local s = espObjs[p]
    if s then for _,d in pairs(s) do pcall(function() d:Remove() end) end espObjs[p]=nil end
end)
RS.RenderStepped:Connect(function()
    if typeof(Drawing) ~= "table" and typeof(Drawing) ~= "userdata" then return end
    for _, p in ipairs(Players:GetPlayers()) do
        local s = espGet(p)
        if not s then continue end
        local show = C.ESP.Enabled and p ~= LP and alive(p) and not (C.ESP.Team and teammate(p))
        local ch = p.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        local head = ch and ch:FindFirstChild("Head")
        if show and (not root or not head) then show=false end
        if not show then for _,d in pairs(s) do d.Visible=false end continue end
        local t,b = Camera:WorldToViewportPoint(head.Position+Vector3.new(0,.7,0)), Camera:WorldToViewportPoint(root.Position-Vector3.new(0,3,0))
        -- t/b это Vector3; onScreen в .Z проверять не надо, WorldToViewportPoint вне экрана даёт мусор — чекаем через вторую return? у Drawing-билда упрощённо:
        local h = math.abs(b.Y-t.Y)
        if h < 5 or h > 2000 then for _,d in pairs(s) do d.Visible=false end continue end
        local w,x,y = h*0.55, t.X-(h*0.55)/2, t.Y
        s.box.Visible=C.ESP.Box
        if C.ESP.Box then s.box.Size,s.box.Position,s.box.Color=Vector2.new(w,h),Vector2.new(x,y),C.ESP.Color end
        local hum=ch:FindFirstChildOfClass("Humanoid")
        local fr=hum and math.clamp(hum.Health/hum.MaxHealth,0,1) or 1
        s.hp.Visible=C.ESP.HP
        if C.ESP.HP then local fh=h*fr s.hp.Size=Vector2.new(3,fh) s.hp.Position=Vector2.new(x-6,y+(h-fh)) s.hp.Color=Color3.fromRGB(255-math.floor(255*fr),math.floor(255*fr),0) end
        s.nm.Visible=C.ESP.Name
        if C.ESP.Name then s.nm.Text, s.nm.Position, s.nm.Color=p.Name,Vector2.new(t.X,y-16),Color3.new(1,1,1) end
        local mr=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local dd=mr and math.floor((mr.Position-root.Position).Magnitude) or 0
        s.ds.Visible=C.ESP.Dist
        if C.ESP.Dist then s.ds.Text, s.ds.Position, s.ds.Color="["..dd.."m]",Vector2.new(t.X,y+h+1),Color3.new(1,1,1) end
        s.tr.Visible=C.ESP.Tracer
        if C.ESP.Tracer then s.tr.From,s.tr.To,s.tr.Color=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y),Vector2.new(t.X,y+h/2),C.ESP.Color end
    end
end)

-- ═══ GUNMODS ═══
task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            local G=C.Gun
            if not (G.NoRecoil or G.NoSpread or G.Rapid or G.InfAmmo) then return end
            for _,o in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if o:IsA("ModuleScript") then
                    local ok,t=pcall(require,o)
                    if ok and typeof(t)=="table" then
                        if G.NoRecoil and t.Recoil~=nil then t.Recoil=0 end
                        if G.NoSpread and t.Spread~=nil then t.Spread=0 end
                        if G.Rapid and typeof(t.FireRate)=="number" and not t._rp then t.FireRate=t.FireRate*G.RapidX t._rp=true end
                        if G.InfAmmo and t.Ammo~=nil then t.Ammo=999 end
                    end
                end
            end
        end)
    end
end)

-- ═══ MOVEMENT ═══
RS.Heartbeat:Connect(function()
    if C.Move.Speed then
        local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h and h.Health>0 then h.WalkSpeed=C.Move.SpeedV end
    end
end)
RS.Stepped:Connect(function()
    if C.Move.Noclip and LP.Character then
        for _,pt in ipairs(LP.Character:GetDescendants()) do
            if pt:IsA("BasePart") then pt.CanCollide=false end
        end
    end
end)
UIS.InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode==Enum.KeyCode.Space and C.Move.InfJump then
        local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
    if i.KeyCode==Enum.KeyCode.F and C.Move.Fly then
        getgenv()._fly = not getgenv()._fly
        if getgenv()._fly then
            local bv=Instance.new("BodyVelocity") bv.MaxForce=Vector3.new(9e9,9e9,9e9) bv.Name="rpfly"
            local bg=Instance.new("BodyGyro") bg.MaxTorque=Vector3.new(9e9,9e9,9e9) bg.Name="rpgyro"
            getgenv()._bv, getgenv()._bg = bv, bg
            getgenv()._flyc = RS.Heartbeat:Connect(function()
                local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not r then return end
                if not bv.Parent then bv.Parent=r end
                if not bg.Parent then bg.Parent=r end
                bg.CFrame=Camera.CFrame
                local d=Vector3.zero local cf=Camera.CFrame
                if UIS:IsKeyDown(Enum.KeyCode.W) then d+=cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then d-=cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then d+=cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then d-=cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then d+=Vector3.new(0,1,0) end
                bv.Velocity = d.Magnitude>0 and d.Unit*C.Move.FlyV or Vector3.zero
            end)
        else
            if getgenv()._flyc then getgenv()._flyc:Disconnect() end
            pcall(function() getgenv()._bv:Destroy() end) pcall(function() getgenv()._bg:Destroy() end)
        end
    end
end)
RS.RenderStepped:Connect(function()
    if C.Misc.NoShake then
        local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.CameraOffset=Vector3.zero end
    end
    if C.Misc.Bright then
        Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.FogEnd=1e5 Lighting.GlobalShadows=false
    end
end)

-- ═══ GUI (Xeno-safe: gethui → CoreGui → PlayerGui) ═══
local function getParent()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then
        local t = Instance.new("ScreenGui") t.Name="rptest"
        local ok3 = pcall(function() t.Parent=cg t:Destroy() end)
        if ok3 then return cg end
    end
    return LP:WaitForChild("PlayerGui")
end
local gui = Instance.new("ScreenGui") gui.Name="rivalspro" gui.ResetOnSpawn=false
gui.Parent = getParent()

local main = Instance.new("Frame")
main.Size=UDim2.new(0,380,0,320) main.Position=UDim2.new(0.5,-190,0.5,-160)
main.BackgroundColor3=Color3.fromRGB(14,14,18) main.BorderSizePixel=0
main.Active=true main.Draggable=true main.Parent=gui
Instance.new("UICorner",main).CornerRadius=UDim.new(0,8)
local st=Instance.new("UIStroke",main) st.Color=Color3.fromRGB(255,0,60) st.Thickness=1.5

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,0,0,32) title.BackgroundTransparency=1
title.Text="  rivals.pro XENO | RightShift — скрыть" title.TextColor3=Color3.new(1,1,1)
title.Font=Enum.Font.GothamBold title.TextSize=13 title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=main

local list=Instance.new("ScrollingFrame")
list.Size=UDim2.new(1,-16,1,-44) list.Position=UDim2.new(0,8,0,36)
list.BackgroundTransparency=1 list.ScrollBarThickness=3 list.CanvasSize=UDim2.new(0,0,0,700)
list.Parent=main
local lay=Instance.new("UIListLayout",list) lay.Padding=UDim.new(0,3)

local function toggle(label, tbl, key, cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,28) b.BackgroundColor3=Color3.fromRGB(22,22,28)
    b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.Gotham b.TextSize=12 b.TextXAlignment=Enum.TextXAlignment.Left
    b.Parent=list Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    local function rf()
        b.Text=string.format("  %s  [%s]",label,tbl[key] and "ON" or "OFF")
        b.BackgroundColor3=tbl[key] and Color3.fromRGB(60,10,20) or Color3.fromRGB(22,22,28)
    end
    rf()
    b.MouseButton1Click:Connect(function() tbl[key]=not tbl[key] if cb then pcall(cb,tbl[key]) end rf() end)
end
local function slider(label, tbl, key, mn, mx, sp)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,0,0,28) f.BackgroundColor3=Color3.fromRGB(22,22,28) f.Parent=list
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local t=Instance.new("TextLabel") t.Size=UDim2.new(1,-66,1,0) t.BackgroundTransparency=1
    t.TextColor3=Color3.new(1,1,1) t.Font=Enum.Font.Gotham t.TextSize=12 t.TextXAlignment=Enum.TextXAlignment.Left t.Parent=f
    local function rf() t.Text=string.format("  %s: %s",label,tostring(tbl[key])) end rf()
    local m=Instance.new("TextButton") m.Size=UDim2.new(0,30,1,0) m.Position=UDim2.new(1,-62,0,0)
    m.Text="-" m.BackgroundColor3=Color3.fromRGB(34,34,42) m.TextColor3=Color3.new(1,1,1) m.Font=Enum.Font.GothamBold m.TextSize=14 m.Parent=f
    local p=Instance.new("TextButton") p.Size=UDim2.new(0,30,1,0) p.Position=UDim2.new(1,-30,0,0)
    p.Text="+" p.BackgroundColor3=Color3.fromRGB(255,0,60) p.TextColor3=Color3.new(1,1,1) p.Font=Enum.Font.GothamBold p.TextSize=14 p.Parent=f
    m.MouseButton1Click:Connect(function() tbl[key]=math.clamp(tbl[key]-sp,mn,mx) rf() end)
    p.MouseButton1Click:Connect(function() tbl[key]=math.clamp(tbl[key]+sp,mn,mx) rf() end)
end

toggle("Aimbot", C.Aim, "Enabled")
toggle("Silent Aim", C.Silent, "Enabled")
slider("FOV", C.Aim, "FOV", 20, 400, 5)
slider("Smooth", C.Aim, "Smooth", 1, 20, 1)
slider("HitChance", C.Silent, "Hit", 1, 100, 1)
toggle("Show FOV", C.Aim, "ShowFOV")
toggle("Wall Check", C.Aim, "Wall")
toggle("ESP", C.ESP, "Enabled")
toggle("ESP Box", C.ESP, "Box")
toggle("ESP Name", C.ESP, "Name")
toggle("ESP HP", C.ESP, "HP")
toggle("ESP Dist", C.ESP, "Dist")
toggle("ESP Tracer", C.ESP, "Tracer")
toggle("No Recoil", C.Gun, "NoRecoil")
toggle("No Spread", C.Gun, "NoSpread")
toggle("Rapid Fire", C.Gun, "Rapid")
toggle("Inf Ammo", C.Gun, "InfAmmo")
toggle("Speed", C.Move, "Speed")
slider("SpeedV", C.Move, "SpeedV", 16, 100, 1)
toggle("Fly (F)", C.Move, "Fly")
toggle("Noclip", C.Move, "Noclip")
toggle("Inf Jump", C.Move, "InfJump")
toggle("NoShake", C.Misc, "NoShake")
toggle("Fullbright", C.Misc, "Bright")

UIS.InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode==Enum.KeyCode.RightShift then main.Visible=not main.Visible end
end)

Notify("[rivals.pro]", "XENO build загружен | RightShift — меню")
print("[rivals.pro] xeno build ok")
