-- rivals.pro NL | modules/gunmods.lua (dedicated file, throttled)

local Common = ...
assert(Common and Common.LP, "gunmods: Common not injected")

local Gun = {cache = nil, cacheAt = 0}

function Gun.start(C)
    task.spawn(function()
        while true do
            task.wait(8)
            pcall(function()
                local G = C.Gun
                if not (G.NoRecoil or G.NoSpread or G.Rapid or G.InfAmmo or G.Reload) then return end
                local now = os.clock()
                if not Gun.cache or (now - Gun.cacheAt) > 60 then
                    Gun.cache = {}
                    for _, o in ipairs(Common.RSv:GetDescendants()) do
                        if o:IsA("ModuleScript") then
                            Gun.cache[#Gun.cache+1] = o
                            if #Gun.cache > 600 then break end
                        end
                    end
                    Gun.cacheAt = now
                end
                local budget = 40
                for _, o in ipairs(Gun.cache) do
                    if budget <= 0 then break end
                    budget = budget - 1
                    local ok, t = pcall(require, o)
                    if ok and typeof(t) == "table" then
                        if G.NoRecoil then
                            if t.Recoil ~= nil then t.Recoil = 0 end
                            for _, k in ipairs({"RecoilX","RecoilY","CameraKick","Kickback"}) do
                                if t[k] ~= nil then t[k] = 0 end
                            end
                        end
                        if G.NoSpread and t.Spread ~= nil then t.Spread = 0 end
                        if G.Rapid and typeof(t.FireRate) == "number" and not t._rp then
                            t.FireRate = t.FireRate * G.RapidX t._rp = true
                        end
                        if G.InfAmmo and t.Ammo ~= nil then t.Ammo = 999 end
                    end
                    if budget % 10 == 0 then task.wait() end
                end
                if G.Reload then
                    local ch = Common.charOf(Common.LP)
                    if ch then
                        for _, v in ipairs(ch:GetDescendants()) do
                            if v:IsA("NumberValue") and string.lower(v.Name) == "reloadtime" then
                                v.Value = 0.01
                            end
                        end
                    end
                end
            end)
        end
    end)
end

return Gun
