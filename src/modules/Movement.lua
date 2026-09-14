-- rivals.pro | modules/Movement
-- спид / флай / ноклип / инфинити джамп

local Movement = {}
Movement._flyConn = nil
Movement._noclipConn = nil
Movement._flying = false

function Movement.Init(Config, Services, Utils)
    Movement.C = Config.Movement
    Movement.S = Services
    Movement.U = Utils

    -- speed loop
    Services.RunService.Heartbeat:Connect(function()
        if Movement.C.SpeedEnabled then
            local hum = Services:GetHumanoid()
            if hum and hum.Health > 0 then
                hum.WalkSpeed = Movement.C.Speed
            end
        end
        if Movement.C.NoKnockback then
            local root = Services:GetRoot()
            if root then
                -- гасим отброс: держим velocity в разумных пределах по XZ
                local v = root.AssemblyLinearVelocity
                if v.Magnitude > 60 then
                    root.AssemblyLinearVelocity = Vector3.new(
                        math.clamp(v.X, -30, 30), v.Y, math.clamp(v.Z, -30, 30)
                    )
                end
            end
        end
    end)

    -- fly toggle
    Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Movement.C.FlyKey and Movement.C.FlyEnabled then
            Movement._flying = not Movement._flying
            if Movement._flying then Movement:StartFly() else Movement:StopFly() end
        end
        -- infinite jump
        if input.KeyCode == Enum.KeyCode.Space and Movement.C.InfiniteJump then
            local hum = Services:GetHumanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    -- noclip loop
    Services.RunService.Stepped:Connect(function()
        if Movement.C.Noclip then
            local char = Services.LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end)

    return Movement
end

function Movement:StartFly()
    local S = self.S
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Name = "rivalspro_fly"
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = S.Camera.CFrame
    bg.Name = "rivalspro_gyro"

    self._flyConn = S.RunService.Heartbeat:Connect(function()
        local root = S:GetRoot()
        if not root then return end
        if not bv.Parent then bv.Parent = root end
        if not bg.Parent then bg.Parent = root end
        bg.CFrame = S.Camera.CFrame

        local dir = Vector3.zero
        local cam = S.Camera.CFrame
        local uis = S.UserInputService
        if uis:IsKeyDown(Enum.KeyCode.W) then dir += cam.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then dir -= cam.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then dir += cam.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then dir -= cam.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then
            bv.Velocity = dir.Unit * self.C.FlySpeed
        else
            bv.Velocity = Vector3.zero
        end
    end)
    self._bv, self._bg = bv, bg
end

function Movement:StopFly()
    if self._flyConn then self._flyConn:Disconnect() self._flyConn = nil end
    if self._bv then pcall(function() self._bv:Destroy() end) self._bv = nil end
    if self._bg then pcall(function() self._bg:Destroy() end) self._bg = nil end
end

return Movement
