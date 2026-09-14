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
            -- locker reads inventory via DataController:Get("CosmeticInventory"):
            -- return all-true proxy so every skin shows as owned (read-path only)
            pcall(function()
                local oGet = DCC.Get
                local proxy = setmetatable({}, {
                    __index = function() return true end,
                    __newindex = function() end,
                })
                DCC.Get = function(self, key)
                    if key == "CosmeticInventory" then return proxy end
                    return oGet(self, key)
                end
            end)
            -- locker may read CurrentData.CosmeticInventory field directly:
            -- metatable the REAL table so missing keys read as owned
            task.spawn(function()
                for _ = 1, 20 do
                    local done = pcall(function()
                        local cd = DCC.CurrentData
                        local inv = cd and cd.CosmeticInventory
                        if typeof(inv) == "table" and not Skin._invPatched then
                            setmetatable(inv, {
                                __index = function() return true end,
                            })
                            Skin._invPatched = true
                        end
                        return Skin._invPatched
                    end)
                    if done and Skin._invPatched then break end
                    task.wait(1)
                end
            end)
            Skin.libs = true
            set("unlocked: open locker")
        end)
        if not ok then
            set("ERR: " .. tostring(err):sub(1, 90))
        end
        -- reset started so user can retry the button
        if not Skin.libs then Skin.started = false end
    end)
end

return Skin
