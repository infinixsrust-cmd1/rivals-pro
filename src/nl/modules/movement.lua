-- rivals.pro NL | modules/movement.lua (dedicated file: speed/fly/noclip/jump/knock)
-- fly rewritten: survives respawn, no error spam (BodyVelocity locked-parent fix)

local Common = ...
assert(Common and Common.LP, "movement: Common not injected")

local Move = {flyConn = nil, flyOn = false, fail = 0}

local function flyOff()
    Move.flyOn = false
    if Move.flyConn then
        pcall(function() Move.flyConn:Disconnect() end)
        Move.flyConn = nil
    end
    -- destroy physics movers wherever they live now
    pcall(function()
        local ch = Common.charOf(Common.LP)
        if ch then
            for _, o in ipairs(ch:GetDescendants()) do
                if o.Name == "rp_fly_bv" or o.Name == "rp_fly_bg" then
                    pcall(function() o:Destroy() end)
                end
            end
        end
    end)
    Move.fail = 0
end

local function flyEnsure(r)
    -- find alive movers under current root, else create fresh (no stale refs)
    local bv, bg = nil, nil
    pcall(function()
        bv = r:FindFirstChild("rp_fly_bv")
        bg = r:FindFirstChild("rp_fly_bg")
    end)
    if not (bv and bg and bv.Parent and bg.Parent) then
        pcall(function() if bv then bv:Destroy() end end)
        pcall(function() if bg then bg:Destroy() end end)
        bv = Instance.new("BodyVelocity")
        bv.Name = "rp_fly_bv"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bg = Instance.new("BodyGyro")
        bg.Name = "rp_fly_bg"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        -- parent IMMEDIATELY (never leave parentless across frames)
        bv.Parent = r
        bg.Parent = r
    end
    return bv, bg
end

function Move.start(C)
    local M = C.Move
    Common.RS.Heartbeat:Connect(function()
        pcall(function()
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
    end)
    Common.RS.Stepped:Connect(function()
        pcall(function()
            if M.Noclip then
                local ch = Common.charOf(Common.LP)
                if ch then
                    for _, pt in ipairs(ch:GetDescendants()) do
                        if pt:IsA("BasePart") then pt.CanCollide = false end
                    end
                end
            end
        end)
    end)
    Common.UIS.InputBegan:Connect(function(i, g)
        pcall(function()
            if g then return end
            if i.KeyCode == Enum.KeyCode.Space and M.InfJump then
                local h = Common.humOf(Common.LP)
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
            if i.KeyCode == Enum.KeyCode.F and M.Fly then
                Move.flyOn = not Move.flyOn
                if Move.flyOn then
                    Move.fail = 0
                    if Move.flyConn then pcall(function() Move.flyConn:Disconnect() end) end
                    Move.flyConn = Common.RS.Heartbeat:Connect(function()
                        local ok = pcall(function()
                            if not Move.flyOn then return end
                            local r = Common.rootOf(Common.LP)
                            local c = Common.cam()
                            if not r or not c then return end
                            local bv, bg = flyEnsure(r)
                            if not (bv and bg) then return end
                            bg.CFrame = c.CFrame
                            local d = Vector3.zero
                            if Common.UIS:IsKeyDown(Enum.KeyCode.W) then d = d + c.CFrame.LookVector end
                            if Common.UIS:IsKeyDown(Enum.KeyCode.S) then d = d - c.CFrame.LookVector end
                            if Common.UIS:IsKeyDown(Enum.KeyCode.D) then d = d + c.CFrame.RightVector end
                            if Common.UIS:IsKeyDown(Enum.KeyCode.A) then d = d - c.CFrame.RightVector end
                            if Common.UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
                            if Common.UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
                            bv.Velocity = d.Magnitude > 0 and (d.Unit * M.FlyV) or Vector3.zero
                        end)
                        if not ok then
                            Move.fail = Move.fail + 1
                            if Move.fail > 10 then flyOff() end
                        else
                            Move.fail = 0
                        end
                    end)
                else
                    flyOff()
                end
            end
        end)
    end)
    -- auto-off on respawn (fresh character = fresh physics)
    pcall(function()
        Common.LP.CharacterAdded:Connect(function()
            if Move.flyOn then
                task.wait(1)
            end
        end)
    end)
end

return Move
