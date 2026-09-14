-- rivals.pro | modules/GunMods
-- отдача / разброс / скорострельность через перехват weapon-модулей
-- Rivals хранит настройки стволов в ReplicatedStorage / PlayerGui,
-- поэтому идём по двум путям: 1) патч таблиц 2) hook FireServer cadence

local GunMods = {}
GunMods._patched = {}
GunMods._oldNamecall = nil

function GunMods.Init(Config, Services, Utils)
    GunMods.C = Config.GunMods
    GunMods.S = Services
    GunMods.U = Utils

    -- фоновый патчер: раз в 2 сек пробегаем по модулям оружия
    task.spawn(function()
        while true do
            task.wait(2)
            pcall(GunMods.PatchWeaponTables, GunMods)
        end
    end)

    return GunMods
end

function GunMods.PatchWeaponTables(self)
    self = self or GunMods
    local C = self.C
    if not (C.NoRecoil or C.NoSpread or C.RapidFire or C.InfiniteAmmo) then return end

    -- ищем weapon-конфиги: ModuleScript / таблицы с Recoil/Spread/FireRate
    for _, obj in ipairs(self.S.ReplicatedStorage:GetDescendants()) do
        if obj:IsA("ModuleScript") then
            local ok, tbl = pcall(require, obj)
            if ok and typeof(tbl) == "table" then
                local touched = false
                if C.NoRecoil and tbl.Recoil ~= nil then
                    tbl.Recoil = C.RecoilAmount
                    touched = true
                end
                for _, key in ipairs({"RecoilX", "RecoilY", "CameraKick", "Kickback"}) do
                    if C.NoRecoil and tbl[key] ~= nil then tbl[key] = 0; touched = true end
                end
                if C.NoSpread and tbl.Spread ~= nil then tbl.Spread = 0; touched = true end
                if C.NoSpread and tbl.Accuracy ~= nil then tbl.Accuracy = 100; touched = true end
                if C.RapidFire and tbl.FireRate ~= nil and typeof(tbl.FireRate) == "number" then
                    if not self._patched[obj] then
                        tbl.FireRate = tbl.FireRate * C.FireRateMult
                        self._patched[obj] = true
                    end
                    touched = true
                end
                if C.InfiniteAmmo then
                    if tbl.Ammo ~= nil then tbl.Ammo = 999; touched = true end
                    if tbl.MagSize ~= nil then tbl.MagSize = 999; touched = true end
                    if tbl.Reserve ~= nil then tbl.Reserve = 999; touched = true end
                end
                -- не спамим, просто патчим молча
            end
        end
    end

    -- instant reload: обнуляем ReloadTime в Tool-атрибутах
    if C.InstantReload then
        local char = self.S.LocalPlayer.Character
        if char then
            for _, tool in ipairs(char:GetDescendants()) do
                if tool:IsA("NumberValue") and string.lower(tool.Name) == "reloadtime" then
                    tool.Value = 0.01
                end
            end
        end
    end
end

return GunMods
