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
        local function set(s) C.Skin.Status = s end
        local ok, err = pcall(function()
            local LP = Common.LP
            set("searching libs...")
            -- DIRECT paths only. No deep scans: game:FindFirstChild(x,true)
            -- on Rivals hangs the thread for minutes. 6 quick tries max.
            local cl, il, dc = nil, nil, nil
            for i = 1, 6 do
                set("searching libs... " .. tostring(i) .. "/6")
                local mods = Common.RSv:FindFirstChild("Modules")
                if mods then
                    cl = cl or mods:FindFirstChild("CosmeticLibrary")
                    il = il or mods:FindFirstChild("ItemLibrary")
                end
                local ps = LP and LP:FindFirstChild("PlayerScripts")
                local ct = ps and ps:FindFirstChild("Controllers")
                dc = dc or (ct and ct:FindFirstChild("PlayerDataController"))
                if cl and il and dc then break end
                task.wait(0.5)
            end
            if not (cl and il and dc) then
                set("libs not found: patch moved?")
                return
            end
            set("loading libs...")
            local CLB, ILB, DCC = nil, nil, nil
            local okR, errR = pcall(function()
                CLB = require(cl)
                set("loading libs... 1/3")
                ILB = require(il)
                set("loading libs... 2/3")
                DCC = require(dc)
                set("loading libs... 3/3")
            end)
            if not okR then
                set("ERR require: " .. tostring(errR):sub(1, 60))
                return
            end
            Skin.mods = {CLB=CLB, ILB=ILB, DCC=DCC}
            -- SURGICAL: Owns* patches (safe, functions only) + GetWeaponData merge.
            -- NO inventory proxies: returning `true` where game expects tables
            -- spams "Missing description" x400 and breaks locker reads.
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
            -- EQUIP INTERCEPT (local visual only, server never sees it):
            -- locker locks stay, but our Skins UI equips straight into viewmodel
            -- data via GetWeaponData merge above. No viewmodel hooks, no replicate.
            pcall(function()
                local rem = Common.RSv:FindFirstChild("Remotes")
                local dr = rem and rem:FindFirstChild("Data")
                local eq = dr and dr:FindFirstChild("EquipCosmetic")
                if eq and typeof(hookmetamethod) == "function" and not Skin._eqHook then
                    Skin._eqHook = true
                    local old
                    old = hookmetamethod(game, "__namecall", function(self, ...)
                        if getnamecallmethod() == "FireServer" and self == eq then
                            local wpn, ctype, cname = ...
                            if C.Skin.Enabled and cname and cname ~= ""
                                and cname ~= "None" and cname ~= "RANDOM_COSMETIC" then
                                local data = Skin.Clone(cname, ctype)
                                if data then
                                    Skin.equipped[wpn] = Skin.equipped[wpn] or {}
                                    Skin.equipped[wpn][ctype] = data
                                    C.Skin.Status = "equipped " .. tostring(cname) .. " (local)"
                                    return -- swallow: server keeps legit state
                                end
                            end
                        end
                        return old(self, ...)
                    end)
                end
            end)
            -- VIEWMODEL inject: game snapshots weapon data at spawn, ignoring
            -- later GetWeaponData merges. Hook the constructor so our skin
            -- lands in the viewmodel at creation. No server calls at all.
            pcall(function()
                local LP2 = Common.LP
                local ps = LP2 and LP2:FindFirstChild("PlayerScripts")
                local ciMod = ps and ps:FindFirstChild("ClientItem", true)
                if ciMod then
                    local CI = require(ciMod)
                    if CI and CI._CreateViewModel and not Skin._vmHook then
                        Skin._vmHook = true
                        local orig = CI._CreateViewModel
                        CI._CreateViewModel = function(self, ref)
                            pcall(function()
                                local wpn = self.Name
                                local pl = self.ClientFighter and self.ClientFighter.Player
                                local eq = Skin.equipped[wpn]
                                if pl == LP2 and eq and eq.Skin and ref then
                                    local okD, dk = pcall(function() return self:ToEnum("Data") end)
                                    local okS, sk = pcall(function() return self:ToEnum("Skin") end)
                                    local okN, nk = pcall(function() return self:ToEnum("Name") end)
                                    if okD and okS and okN and ref[dk] then
                                        ref[dk][sk] = eq.Skin
                                        ref[dk][nk] = eq.Skin.Name
                                    elseif ref.Data then
                                        ref.Data.Skin = eq.Skin
                                        ref.Data.Name = eq.Skin.Name
                                    end
                                end
                            end)
                            return orig(self, ref)
                        end
                    end
                end
            end)
            Skin.libs = true
            set("unlocked: pick skin below")
        end)
        if not ok then
            set("ERR: " .. tostring(err):sub(1, 90))
        end
        -- reset started so user can retry the button
        if not Skin.libs then Skin.started = false end
    end)
end

-- Wear: fires the game's own equip remote; our intercept stores it locally
-- (server never sees it). Then re-equip the weapon in hand.
function Skin.Wear(C, sname)
    if not Skin.libs then
        C.Skin.Status = "press UNLOCK first"
        return
    end
    if not sname or sname == "" then
        C.Skin.Status = "empty name"
        return
    end
    C.Skin.Enabled = true
    local data = Skin.Clone(sname, "Skin")
    if not data then
        C.Skin.Status = "not found: " .. tostring(sname)
        return
    end
    local wpn = C.Skin.Weapon
    Skin.equipped[wpn] = Skin.equipped[wpn] or {}
    Skin.equipped[wpn].Skin = data
    C.Skin.Skin = sname
    -- also tell the game (intercepted -> local only)
    pcall(function()
        local rem = Common.RSv:FindFirstChild("Remotes")
        local dr = rem and rem:FindFirstChild("Data")
        local eq = dr and dr:FindFirstChild("EquipCosmetic")
        if eq then eq:FireServer(wpn, "Skin", sname, {}) end
    end)
    C.Skin.Status = "wearing " .. sname .. " (re-equip " .. wpn .. ")"
end

return Skin
