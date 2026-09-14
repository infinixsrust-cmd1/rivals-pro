-- rivals.pro NL | modules/movement.lua (dedicated file: speed/fly/noclip/jump/knock)

local Common = ...
assert(Common and Common.LP, "movement: Common not injected")

local Move = {flyConn = nil, flyBV = nil, flyBG = nil}

local function flyOff()
    if Move.flyConn then Move.flyConn:Disconnect() Move.flyConn = nil end
    pcall(function() if Move.flyBV then Move.flyBV:Destroy() end end)
    pcall(function() if Move.flyBG then Move.flyBG:Destroy() end end)
    Move.flyBV, Move.flyBG = nil, nil
end

function Move.start(C)
    local M = C.Move
    Common.RS.Heartbeat:Connect(function()
        if M.Speed then
            local h = Common.humOf(Common.LP)
            if h and h.Health > 0 then h.WalkSpeed = M.SpeedV end
        end
        if M.Knock then
            local r = Common.rootOf(Common.LP)
            if r then
                local v = r.AssemblyLinearVelocity
                if v.Magnitude > 60 then
                    r.AssemblyLinearVelocity = Vector3.new(math.clamp(v.X,-30,30), v.Y, math.clamp(v.Z,-30,30))
                end
            end
        end
    end)
    Common.RS.Stepped:Connect(function()
        if M.Noclip then
            local ch = Common.charOf(Common.LP)
            if ch then
                for _, pt in ipairs(ch:GetDescendants()) do
                    if pt:IsA("BasePart") then pt.CanCollide = false end
                end
            end
        end
    end)
    Common.UIS.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.Space and M.InfJump then
            local h = Common.humOf(Common.LP)
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
        if i.KeyCode == Enum.KeyCode.F and M.Fly then
            getgenv()._fly = not getgenv()._fly
            if getgenv()._fly then
                Move.flyBV = Instance.new("BodyVelocity")
                Move.flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9) Move.flyBV.Velocity = Vector3.zero
                Move.flyBG = Instance.new("BodyGyro")
                Move.flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                Move.flyConn = Common.RS.Heartbeat:Connect(function()
                    local r = Common.rootOf(Common.LP)
                    local c = Common.cam()
                    if not r or not c then return end
                    if not Move.flyBV.Parent then Move.flyBV.Parent = r end
                    if not Move.flyBG.Parent then Move.flyBG.Parent = r end
                    Move.flyBG.CFrame = c.CFrame
                    local d = Vector3.zero
                    if Common.UIS:IsKeyDown(Enum.KeyCode.W) then d = d + c.CFrame.LookVector end
                    if Common.UIS:IsKeyDown(Enum.KeyCode.S) then d = d - c.CFrame.LookVector end
                    if Common.UIS:IsKeyDown(Enum.KeyCode.D) then d = d + c.CFrame.RightVector end
                    if Common.UIS:IsKeyDown(Enum.KeyCode.A) then d = d - c.CFrame.RightVector end
                    if Common.UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
                    if Common.UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
                    Move.flyBV.Velocity = d.Magnitude > 0 and (d.Unit * M.FlyV) or Vector3.zero
                end)
            else
                flyOff()
            end
        end
    end)
end

return Move
