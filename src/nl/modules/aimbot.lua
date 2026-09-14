-- rivals.pro NL | modules/aimbot.lua (dedicated file)
-- usage: local Aimbot = loadModule("nl/modules/aimbot.lua")(Common, C)

local Common = ...
assert(Common and Common.LP, "aimbot: Common not injected")

local Aimbot = {}
Aimbot.holding, Aimbot.toggled, Aimbot.target, Aimbot.targetName = false, false, nil, "none"
Aimbot.FOVc = Common.mkDraw("Circle", {Thickness=1.5, NumSides=64, Filled=false, Transparency=1})
Aimbot.FOVdot = Common.mkDraw("Circle", {Radius=3, Filled=true, Transparency=1})

function Aimbot.valid(p, A)
    if p == Common.LP then return false end
    if A.Team and Common.teammate(p) then return false end
    if A.Dead and not Common.alive(p) then return false end
    if Common.shielded(p) then return false end
    local ch = Common.charOf(p)
    if not ch then return false end
    return Common.partOf(ch, A.Part) ~= nil
end

function Aimbot.pick(A)
    local mp = Common.UIS:GetMouseLocation()
    if A.Sticky and Aimbot.target and Aimbot.valid(Aimbot.target, A) then
        local pt = Common.partOf(Common.charOf(Aimbot.target), A.Part)
        if pt then
            local sp, on = Common.toScreen(Common.predict(pt, A.Pred))
            if on and (sp - mp).Magnitude < A.FOV then
                if not (A.Wall and not Common.visible(pt)) then
                    Aimbot.targetName = Aimbot.target.Name
                    return Aimbot.target, pt
                end
            end
        end
        Aimbot.target, Aimbot.targetName = nil, "none"
    else
        Aimbot.target = nil
    end
    local best, bd, bp = nil, A.FOV, nil
    for _, p in ipairs(Common.Players:GetPlayers()) do
        if Aimbot.valid(p, A) then
            local pt = Common.partOf(Common.charOf(p), A.Part)
            if pt and not (A.Wall and not Common.visible(pt)) then
                local sp, on = Common.toScreen(Common.predict(pt, A.Pred))
                if on then
                    local d = (sp - mp).Magnitude
                    if d < bd then best, bd, bp = p, d, pt end
                end
            end
        end
    end
    Aimbot.target = best
    Aimbot.targetName = best and best.Name or "none"
    return best, bp
end

function Aimbot.start(C)
    local A = C.Aim
    Common.UIS.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == A.Key or i.UserInputType == Enum.UserInputType.MouseButton2 then
            if A.Mode == "Toggle" then Aimbot.toggled = not Aimbot.toggled
            else Aimbot.holding = true end
        end
    end)
    Common.UIS.InputEnded:Connect(function(i)
        if i.KeyCode == A.Key or i.UserInputType == Enum.UserInputType.MouseButton2 then
            Aimbot.holding = false
        end
    end)
    Common.RS.RenderStepped:Connect(function(dt)
        if Aimbot.FOVc then
            local show = A.Enabled and A.ShowFOV
            Aimbot.FOVc.Visible = show and true or false
            if show then
                Aimbot.FOVc.Position = Common.UIS:GetMouseLocation()
                Aimbot.FOVc.Radius = A.FOV
                Aimbot.FOVc.Color = (Aimbot.targetName ~= "none")
                    and Color3.fromRGB(255,0,60) or Color3.fromRGB(255,255,255)
            end
        end
        local on = A.Enabled and ((A.Mode == "Toggle" and Aimbot.toggled)
            or Aimbot.holding or Common.UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
        if not on then
            Aimbot.target, Aimbot.targetName = nil, "none"
            if Aimbot.FOVdot then Aimbot.FOVdot.Visible = false end
            return
        end
        local _, pt = Aimbot.pick(A)
        if Aimbot.FOVdot then
            if A.Dot and pt then
                local sp, os = Common.toScreen(pt.Position)
                Aimbot.FOVdot.Visible = os
                if os then Aimbot.FOVdot.Position = sp Aimbot.FOVdot.Color = Color3.fromRGB(255,0,60) end
            else
                Aimbot.FOVdot.Visible = false
            end
        end
        if not pt then return end
        local c = Common.cam()
        if not c then return end
        local goal = CFrame.new(c.CFrame.Position, Common.predict(pt, A.Pred))
        local s = math.clamp(A.Smooth, 1, 20)
        local alpha = math.clamp(1 - math.exp(-dt * (30 / s) * 2), 0.02, 1)
        c.CFrame = c.CFrame:Lerp(goal, alpha)
    end)
end

return Aimbot
