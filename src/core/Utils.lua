-- rivals.pro | core/Utils
-- общие хелперы: проверки, предикт, нотификации

-- Utils получает Services через ... (передаётся из main.lua)
-- порядок загрузки: Config -> Services -> Utils(Services)
local Services = ...
assert(Services and Services.Players, "[rivals.pro] Utils: Services not injected")

local Utils = {}

function Utils.Notify(title, text, dur)
    dur = dur or 3
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = dur,
        })
    end)
end

function Utils.IsAlive(player)
    local char = player and player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    return hum.Health > 0
end

function Utils.IsTeammate(player)
    local lp = Services.LocalPlayer
    -- в Rivals команд нет в лобби FFA, но есть team-моды
    if player.Team and lp.Team and player.Team == lp.Team then
        return true
    end
    return false
end

function Utils.IsVisible(targetPart, charToIgnore)
    local cam = Services.Camera
    local origin = cam.CFrame.Position
    local dir = (targetPart.Position - origin)
    local dist = dir.Magnitude

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        Services.LocalPlayer.Character,
        charToIgnore or targetPart.Parent,
        cam,
    }
    params.IgnoreWater = true

    local result = Services.Workspace:Raycast(origin, dir, params)
    if not result then return true end
    -- видима если хит близко к таргету (допуск ~4 стада)
    return (result.Position - targetPart.Position).Magnitude < 4
end

function Utils.GetHealth(player)
    local hum = Services:GetHumanoid(player)
    if not hum then return 0, 100 end
    return hum.Health, hum.MaxHealth
end

function Utils.PredictPosition(part, amount)
    -- линейный предикт по velocity, стандарт для Rivals (projectile ~ быстрый)
    local ok, vel = pcall(function() return part.Velocity end)
    if not ok or not vel then return part.Position end
    return part.Position + (vel * (amount or 0.135))
end

function Utils.ScreenPoint(worldPos)
    local cam = Services.Camera
    local vec, onScreen = cam:WorldToViewportPoint(worldPos)
    return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

function Utils.MouseDist(screenPos, mousePos)
    mousePos = mousePos or Services.UserInputService:GetMouseLocation()
    return (screenPos - mousePos).Magnitude
end

-- поиск Remote для silent aim (имена меняются от патча к патчу)
function Utils.FindShootRemote(remoteNames)
    for _, name in ipairs(remoteNames) do
        local found = Services.ReplicatedStorage:FindFirstChild(name, true)
        if found and (found:IsA("RemoteEvent") or found:IsA("RemoteFunction")) then
            return found
        end
    end
    -- fallback: ищем любой Remote с Gun/Shoot/Fire в имени
    for _, obj in ipairs(Services.ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = string.lower(obj.Name)
            if string.find(n, "shoot") or string.find(n, "fire") or string.find(n, "bullet") or string.find(n, "gun") or string.find(n, "damage") then
                return obj
            end
        end
    end
    return nil
end

function Utils.GetWeaponName(player)
    local char = player and player.Character
    if not char then return "?" end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then return tool.Name end
    end
    return "?"
end

return Utils
