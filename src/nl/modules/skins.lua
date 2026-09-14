-- rivals.pro NL | modules/skins.lua (dedicated file)
-- technique: CosmeticLibrary ownership patch + viewmodel inject (cf. Mandog23/voldstrap)

local Common = ...
assert(Common and Common.LP, "skins: Common not injected")

local Skin = {libs = false, equipped = {}, mods = {}, started = false}

function Skin.Clone(name, ctype)
    local CLB = Skin.mods.CLB
    if not CLB or not CLB.Cosmetics then return nil end
    local resolved = (CLB.RENAMED_COSMETICS and CLB.RENAMED_COSMETICS[name]) or name
    local base = CLB.Cosmetics[resolved]
    if not base then
        local lw = string.lower(tostring(resolved))
        for k, v in pairs(CLB.Cosmetics) do
            if string.lower(tostring(k)) == lw then base, resolved = v, k break end
        end
    end
    if not base then return nil end
    local d = {}
    for k, v in pairs(base) do d[k] = v end
    d.Name, d.Type, d.Seed = resolved, d.Type or ctype, math.random(1, 1000000)
    return d
end

function Skin.Weapons()
    local ILB = Skin.mods.ILB
    local out = {}
    if ILB and ILB.Items then
        for k in pairs(ILB.Items) do
            if not string.find(tostring(k), "MISSING_") then out[#out+1] = tostring(k) end
        end
        table.sort(out)
    else
        for _, w in ipairs({"Assault Rifle","SMG","Shotgun","Sniper","Pistol","Revolver","Knife","Katana","Scythe"}) do
            out[#out+1] = w
        end
    end
    return out
end

function Skin.Apply(C)
    if not Skin.libs then C.Skin.Status = "libs not ready" return end
    local wpn = C.Skin.Weapon
    if C.Skin.Skin ~= "" then
        local d = Skin.Clone(C.Skin.Skin, "Skin")
        if d then
            Skin.equipped[wpn] = Skin.equipped[wpn] or {}
            Skin.equipped[wpn].Skin = d
        else
            C.Skin.Status = "skin not found: " .. C.Skin.Skin
            return
        end
    end
    if C.Skin.Wrap ~= "" then
        local d = Skin.Clone(C.Skin.Wrap, "Wrap")
        if d then
            Skin.equipped[wpn] = Skin.equipped[wpn] or {}
            Skin.equipped[wpn].Wrap = d
        end
    end
    pcall(function() Skin.mods.DCC.CurrentData:Replicate("WeaponInventory") end)
    C.Skin.Status = "applied to " .. wpn .. " (re-equip weapon)"
end

function Skin.start(C)
    if Skin.started then return end
    Skin.started = true
    task.spawn(function()
        pcall(function()
            local LP = Common.LP
            local mods = Common.RSv:WaitForChild("Modules", 15)
            if not mods then C.Skin.Status = "no Modules" return end
            local cl = mods:WaitForChild("CosmeticLibrary", 10)
            local il = mods:WaitForChild("ItemLibrary", 10)
            local ps = LP:WaitForChild("PlayerScripts", 15)
            local ct = ps and ps:WaitForChild("Controllers", 10)
            local dc = ct and ct:WaitForChild("PlayerDataController", 10)
            if not (cl and il and dc) then C.Skin.Status = "no lib modules" return end
            local CLB, ILB, DCC = require(cl), require(il), require(dc)
            Skin.mods = {CLB=CLB, ILB=ILB, DCC=DCC}
            pcall(function()
                CLB.OwnsCosmeticNormally = function() return true end
                CLB.OwnsCosmeticUniversally = function() return true end
                CLB.OwnsCosmeticForSomething = function() return true end
                CLB.OwnsCosmeticForWeapon = function() return true end
                local oOwn = CLB.OwnsCosmetic
                CLB.OwnsCosmetic = function(self, inv, name, wpn)
                    if name and string.find(tostring(name), "MISSING_") then
                        return oOwn(self, inv, name, wpn)
                    end
                    return true
                end
            end)
            pcall(function()
                DCC.OwnsAllWeapons = function() return true end
                local oGWD = DCC.GetWeaponData
                DCC.GetWeaponData = function(self, wpn)
                    local d = {Unlocked=true, Level=100, XP=99999}
                    local ok, od = pcall(oGWD, self, wpn)
                    if ok and typeof(od) == "table" then
                        for k, v in pairs(od) do d[k] = v end
                    end
                    if Skin.equipped[wpn] then
                        for kt, vd in pairs(Skin.equipped[wpn]) do d[kt] = vd end
                    end
                    return d
                end
            end)
            pcall(function()
                local ciMod = ps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem
                local CI = require(ciMod)
                if CI and CI._CreateViewModel then
                    local orig = CI._CreateViewModel
                    CI._CreateViewModel = function(self, ref)
                        local wpn = self.Name
                        local pl = self.ClientFighter and self.ClientFighter.Player
                        if pl == LP and Skin.equipped[wpn] and Skin.equipped[wpn].Skin and ref then
                            pcall(function()
                                local dk = self:ToEnum("Data")
                                local sk = self:ToEnum("Skin")
                                local nk = self:ToEnum("Name")
                                if ref[dk] then
                                    ref[dk][sk] = Skin.equipped[wpn].Skin
                                    ref[dk][nk] = Skin.equipped[wpn].Skin.Name
                                end
                            end)
                        end
                        return orig(self, ref)
                    end
                end
            end)
            pcall(function()
                local vmMod = ps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
                if vmMod then
                    local CVM = require(vmMod)
                    if CVM.GetWrap then
                        local origW = CVM.GetWrap
                        CVM.GetWrap = function(self)
                            local wn = self.ClientItem and self.ClientItem.Name
                            local pl = self.ClientItem and self.ClientItem.ClientFighter
                                and self.ClientItem.ClientFighter.Player
                            if wn and pl == LP and Skin.equipped[wn] and Skin.equipped[wn].Wrap then
                                return Skin.equipped[wn].Wrap
                            end
                            return origW(self)
                        end
                    end
                end
            end)
            pcall(function()
                local rem = Common.RSv:WaitForChild("Remotes", 10)
                local dr = rem and rem:WaitForChild("Data", 10)
                local eq = dr and dr:WaitForChild("EquipCosmetic", 10)
                if eq and typeof(hookmetamethod) == "function" then
                    local old
                    old = hookmetamethod(game, "__namecall", function(self, ...)
                        if getnamecallmethod() == "FireServer" and self == eq and C.Skin.Enabled then
                            local wpn, ctype, cname = ...
                            if cname and cname ~= "" and cname ~= "None" then
                                local data = Skin.Clone(cname, ctype)
                                if data then
                                    Skin.equipped[wpn] = Skin.equipped[wpn] or {}
                                    Skin.equipped[wpn][ctype] = data
                                    C.Skin.Status = "equipped " .. tostring(cname)
                                    pcall(function()
                                        Skin.mods.DCC.CurrentData:Replicate("WeaponInventory")
                                    end)
                                    return
                                end
                            end
                        end
                        return old(self, ...)
                    end)
                end
            end)
            Skin.libs = true
            C.Skin.Status = "ready"
        end)
    end)
end

return Skin
