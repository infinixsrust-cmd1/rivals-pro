-- rivals.pro | core/Services
-- кэш сервисов + локальный игрок, чтоб не дёргать GetService везде

local Services = {}

Services.Players = game:GetService("Players")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.Workspace = game:GetService("Workspace")
Services.RunService = game:GetService("RunService")
Services.UserInputService = game:GetService("UserInputService")
Services.TweenService = game:GetService("TweenService")
Services.Lighting = game:GetService("Lighting")
Services.HttpService = game:GetService("HttpService")
Services.Stats = game:GetService("Stats")

Services.LocalPlayer = Services.Players.LocalPlayer
Services.Camera = Services.Workspace.CurrentCamera
Services.Mouse = Services.LocalPlayer:GetMouse()

function Services:GetCharacter(player)
    player = player or self.LocalPlayer
    return player and player.Character or nil
end

function Services:GetRoot(player)
    local char = self:GetCharacter(player)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function Services:GetHumanoid(player)
    local char = self:GetCharacter(player)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

return Services
