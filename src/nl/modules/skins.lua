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
    -- no server replicate in safe mode (it crashed). Ownership patch is enough:
    -- open locker, everything shows as owned, equip from there.
    C.Skin.Status = "owned-all: open locker, equip " .. wpn
end

function Skin.start(C)
    if Skin.started then return end
    Skin.started = true
    task.spawn(function()
        pcall(function()
            local LP = Common.LP
            C.Skin.Status = "searching libs..."
            -- FAST non-blocking find (WaitForChild chain = 60s freeze if names differ)
            local function fastFind(names)
                -- names: array of path arrays, e.g. {{"Modules","CosmeticLibrary"}}
                local t0 = os.clock()
                while os.clock() - t0 < 4 do
                    for _, path in ipairs(names) do
                        local cur = game
                        local okAll = true
                        for _, n in ipairs(path) do
                            if n == "PlayerScripts" then
                                cur = LP and LP:FindFirstChild("PlayerScripts")
                            elseif n == "Controllers" then
                                cur = cur and cur:FindFirstChild("Controllers")
                            else
                                cur = cur and (cur:FindFirstChild(n))
                            end
                            if not cur then okAll = false break end
                        end
                        if okAll and cur then return cur, path end
                    end
                    -- deep fallback once per second: scan ReplicatedStorage
                    local deep = Common.RSv:FindFirstChild(names[1][#names[1]], true)
                    if deep then return deep, {"deep"} end
                    task.wait(0.5)
                end
                return nil
            end
            local cl = fastFind({{"ReplicatedStorage","Modules","CosmeticLibrary"},{"Modules","CosmeticLibrary"}})
            if not cl then
                cl = Common.RSv:FindFirstChild("CosmeticLibrary", true)
            end
            local il = Common.RSv:FindFirstChild("ItemLibrary", true)
            local dc = (LP:FindFirstChild("PlayerScripts") or {})
            dc = dc and dc:FindFirstChild("Controllers", true)
            dc = dc and dc:FindFirstChild("PlayerDataController")
            if not dc then
                -- controllers may live elsewhere; deep scan once
                dc = game:FindFirstChild("PlayerDataController", true)
            end
            if not (cl and il and dc) then
                C.Skin.Status = "libs not found (ilichq)"
                return
            end
            C.Skin.Status = "patching..."
            local CLB, ILB, DCC = require(cl), require(il), require(dc)
            Skin.mods = {CLB=CLB, ILB=ILB, DCC=DCC}
            -- SAFE MODE: only ownership patches (read-path). No viewmodel hooks,
            -- no namecall hooks, no replicate-on-equip. Those crashed Rivals.
            -- Skins show via locker: game thinks you own everything.
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
            Skin.libs = true
            C.Skin.Status = "ready (safe mode: pick skins in locker)"
        end)
    end)
end

return Skin
