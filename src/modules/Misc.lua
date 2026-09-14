-- rivals.pro | modules/Misc
-- анти-афк, фпс-буст, фулбрайт, анти-шейк, spectator warn

local Misc = {}

function Misc.Init(Config, Services, Utils)
    Misc.C = Config.Misc
    Misc.S = Services
    Misc.U = Utils

    -- anti afk
    if Misc.C.AntiAFK then
        pcall(function()
            local vu = game:GetService("VirtualUser")
            Services.Players.LocalPlayer.Idled:Connect(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end)
    end

    -- no camera shake: глушим CameraOffset каждый кадр
    Services.RunService.RenderStepped:Connect(function()
        if Misc.C.NoCameraShake then
            local hum = Services:GetHumanoid()
            if hum then hum.CameraOffset = Vector3.zero end
        end
        if Misc.C.Fullbright then
            Services.Lighting.Brightness = 2
            Services.Lighting.ClockTime = 14
            Services.Lighting.FogEnd = 1e5
            Services.Lighting.GlobalShadows = false
        end
    end)

    -- spectator warning
    if Misc.C.SpectatorWarning then
        task.spawn(function()
            while true do
                task.wait(5)
                Misc:CheckSpectators()
            end
        end)
    end

    return Misc
end

function Misc:ApplyFPSBoost()
    local light = self.S.Lighting
    light.GlobalShadows = false
    light.FogEnd = 9e9
    for _, v in ipairs(light:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") then
            v.Enabled = false
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Enabled = false
        elseif obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
        end
    end
end

function Misc:CheckSpectators()
    -- в Rivals спектаторы сидят без Character или с CameraSubject чужим
    local count = 0
    for _, plr in ipairs(self.S.Players:GetPlayers()) do
        if plr ~= self.S.LocalPlayer and not plr.Character then
            count += 1
        end
    end
    if count > 0 then
        -- тихий вывод в консоль executor, не спамим нотифами
        print(string.format("%s spectators: %d", "[rivals.pro]", count))
    end
end

return Misc
