-- rivals.pro | modules/Aimbot
-- легитный aimbot: FOV + сглаживание + предикт + wall/team check

local Aimbot = {}
Aimbot._holding = false
Aimbot._toggled = false
Aimbot._target = nil
Aimbot._fovCircle = nil

function Aimbot.Init(Config, Services, Utils)
    Aimbot.C = Config.Aimbot
    Aimbot.S = Services
    Aimbot.U = Utils

    -- FOV круг
    local circle = Drawing.new("Circle")
    circle.Thickness = 1.5
    circle.NumSides = 64
    circle.Filled = false
    circle.Transparency = 1
    Aimbot._fovCircle = circle

    -- инпут
    Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Aimbot.C.Key or input.UserInputType == Enum.UserInputType.MouseButton2 then
            if Aimbot.C.Toggle then
                Aimbot._toggled = not Aimbot._toggled
            else
                Aimbot._holding = true
            end
        end
    end)
    Services.UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Aimbot.C.Key or input.UserInputType == Enum.UserInputType.MouseButton2 then
            Aimbot._holding = false
        end
    end)

    Services.RunService.RenderStepped:Connect(function()
        Aimbot:UpdateFOV()
        if not Aimbot:IsActive() then
            Aimbot._target = nil
            return
        end
        Aimbot:Run()
    end)

    return Aimbot
end

function Aimbot:IsActive()
    if not self.C.Enabled then return false end
    if self.C.Toggle then return self._toggled end
    return self._holding or self.S.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

function Aimbot:GetTargetPart(char, partName)
    partName = partName or self.C.TargetPart
    if partName == "Head" then
        return char:FindFirstChild("Head")
    elseif partName == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    end
    return char:FindFirstChild("HumanoidRootPart")
end

function Aimbot:IsValidTarget(player)
    if player == self.S.LocalPlayer then return false end
    if self.C.TeamCheck and self.U.IsTeammate(player) then return false end
    if self.C.AliveCheck and not self.U.IsAlive(player) then return false end
    local char = player.Character
    if not char then return false end
    local part = self:GetTargetPart(char)
    if not part then return false end
    return true, char, part
end

function Aimbot:GetClosest()
    local mousePos = self.S.UserInputService:GetMouseLocation()
    local best, bestDist, bestPart = nil, self.C.FOV, nil

    -- sticky: сначала проверяем старый таргет
    if self.C.StickyTarget and self._target then
        local ok, char, part = self:IsValidTarget(self._target)
        if ok then
            local predicted = self.U.PredictPosition(part, self.C.Prediction)
            local sp, onScreen = self.U.ScreenPoint(predicted)
            if onScreen then
                local d = self.U.MouseDist(sp, mousePos)
                if d < self.C.FOV then
                    if self.C.WallCheck and not self.U.IsVisible(part) then
                        -- за стеной -> сбрасываем sticky
                    else
                        return self._target, part
                    end
                end
            end
        end
        self._target = nil
    end

    for _, player in ipairs(self.S.Players:GetPlayers()) do
        local ok, char, part = self:IsValidTarget(player)
        if ok then
            if self.C.WallCheck and not self.U.IsVisible(part) then
                continue
            end
            local predicted = self.U.PredictPosition(part, self.C.Prediction)
            local sp, onScreen = self.U.ScreenPoint(predicted)
            if onScreen then
                local d = self.U.MouseDist(sp, mousePos)
                if d < bestDist then
                    best, bestDist, bestPart = player, d, part
                end
            end
        end
    end
    if best then self._target = best end
    return best, bestPart
end

function Aimbot:Run()
    local _, part = self:GetClosest()
    if not part then return end
    local cam = self.S.Camera
    local predicted = self.U.PredictPosition(part, self.C.Prediction)
    -- сглаживание через Lerp CFrame
    local cur = cam.CFrame
    local goal = CFrame.new(cur.Position, predicted)
    local alpha = math.clamp(1 / math.max(self.C.Smoothness, 1), 0.05, 1)
    cam.CFrame = cur:Lerp(goal, alpha)
end

function Aimbot:UpdateFOV()
    local c = self._fovCircle
    if not c then return end
    c.Visible = self.C.Enabled and self.C.ShowFOV
    if c.Visible then
        local mp = self.S.UserInputService:GetMouseLocation()
        c.Position = mp
        c.Radius = self.C.FOV
        c.Color = self.C.FOVColor
    end
end

function Aimbot:Destroy()
    if self._fovCircle then
        pcall(function() self._fovCircle:Remove() end)
        self._fovCircle = nil
    end
end

return Aimbot
