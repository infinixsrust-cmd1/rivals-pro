-- rivals.pro | modules/SilentAim
-- тихий аим: перехватывает FireServer и подменяет точку попадания
-- палится меньше aimbot, но после патчей надо обновлять Remotes в Config
-- источники имён: github-ревёрсы Rivals (kiciahook, duckhub, nebora, solix)

local SilentAim = {}
SilentAim._oldNamecall = nil
SilentAim._remote = nil
SilentAim._target = nil

function SilentAim.Init(Config, Services, Utils)
    SilentAim.C = Config.SilentAim
    SilentAim.S = Services
    SilentAim.U = Utils

    SilentAim._remote = Utils.FindShootRemote(Config.SilentAim.Remotes)

    if not SilentAim._oldNamecall then
        SilentAim._oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local cfg = SilentAim.C

            if cfg.Enabled and (method == "FireServer" or method == "InvokeServer") then
                -- проверяем что это стрелковый remote
                local isShoot = (self == SilentAim._remote)
                if not isShoot then
                    local n = string.lower(tostring(self.Name or ""))
                    if string.find(n, "shoot") or string.find(n, "fire") or string.find(n, "bullet") then
                        isShoot = true
                    end
                end

                if isShoot then
                    -- hitchance ролл
                    if math.random(1, 100) > cfg.HitChance then
                        return SilentAim._oldNamecall(self, ...)
                    end
                    local target, part = SilentAim:GetTarget()
                    if target and part then
                        SilentAim._target = target
                        local args = {...}
                        local predicted = SilentAim.U.PredictPosition(part, 0.135)
                        -- подменяем Vector3-аргументы (позиция попадания) на предикт
                        for i, v in ipairs(args) do
                            if typeof(v) == "Vector3" then
                                args[i] = predicted
                            elseif typeof(v) == "CFrame" then
                                args[i] = CFrame.new(predicted)
                            end
                        end
                        if method == "FireServer" then
                            return SilentAim._oldNamecall(self, unpack(args))
                        else
                            return SilentAim._oldNamecall(self, unpack(args))
                        end
                    end
                end
            end

            return SilentAim._oldNamecall(self, ...)
        end)
    end

    -- фоновое обновление remote если игра пересоздала его
    task.spawn(function()
        while true do
            task.wait(10)
            if not SilentAim._remote or not SilentAim._remote.Parent then
                SilentAim._remote = SilentAim.U.FindShootRemote(SilentAim.C.Remotes)
            end
        end
    end)

    return SilentAim
end

function SilentAim:GetTarget()
    local mousePos = self.S.UserInputService:GetMouseLocation()
    local best, bestDist, bestPart = nil, self.C.MaxDistance, nil

    for _, player in ipairs(self.S.Players:GetPlayers()) do
        if player == self.S.LocalPlayer then continue end
        if self.C.TeamCheck and self.U.IsTeammate(player) then continue end
        if not self.U.IsAlive(player) then continue end

        local char = player.Character
        if not char then continue end
        local part = char:FindFirstChild(self.C.TargetPart)
            or char:FindFirstChild("Head")
            or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        if self.C.WallCheck and not self.U.IsVisible(part) then continue end

        local sp, onScreen = self.U.ScreenPoint(part.Position)
        if not onScreen then continue end

        -- дистанция в стадах + дистанция до мыши
        local charDist = (self.S.LocalPlayer.Character
            and self.S.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            and (self.S.LocalPlayer.Character.HumanoidRootPart.Position - part.Position).Magnitude)
            or 0
        if charDist > self.C.MaxDistance then continue end

        -- берём ближайшего к курсору (стандарт silent aim)
        local d = self.U.MouseDist(sp, mousePos)
        if d < 400 and (not best or d < bestDist) then
            best, bestDist, bestPart = player, d, part
        end
    end
    return best, bestPart
end

return SilentAim
