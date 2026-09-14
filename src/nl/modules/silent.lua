-- rivals.pro NL | modules/silent.lua (dedicated file)
-- usage: local Silent = loadModule("nl/modules/silent.lua")(Common, C)

local Common = ...
assert(Common and Common.LP, "silent: Common not injected")

local Silent = {}

function Silent.start(C)
    if typeof(hookmetamethod) ~= "function" or typeof(getnamecallmethod) ~= "function" then
        return false, "no hookmetamethod"
    end
    local S = C.Silent
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if S.Enabled and (m == "FireServer" or m == "InvokeServer") then
            local okN, nm = pcall(function() return tostring(self.Name) end)
            local n = okN and string.lower(nm) or ""
            if string.find(n, "shoot") or string.find(n, "fire") or string.find(n, "bullet") then
                if math.random(1, 100) <= S.Hit then
                    local mp = Common.UIS:GetMouseLocation()
                    local bp2, bd2 = nil, 420
                    local myR = Common.rootOf(Common.LP)
                    for _, p in ipairs(Common.Players:GetPlayers()) do
                        if p ~= Common.LP and Common.alive(p) and not Common.shielded(p)
                            and not (S.Team and Common.teammate(p)) then
                            local ch = Common.charOf(p)
                            local pt = ch and (ch:FindFirstChild(S.Part) or ch:FindFirstChild("Head"))
                            if pt then
                                local skip = false
                                if myR and (myR.Position - pt.Position).Magnitude > S.Dist then skip = true end
                                if not skip and S.Wall and not Common.visible(pt) then skip = true end
                                if not skip then
                                    local sp, on = Common.toScreen(pt.Position)
                                    if on then
                                        local d = (sp - mp).Magnitude
                                        if d < bd2 then bp2, bd2 = pt, d end
                                    end
                                end
                            end
                        end
                    end
                    if bp2 then
                        local args = {...}
                        local pr2 = Common.predict(bp2, 0.12)
                        for i, v in ipairs(args) do
                            if typeof(v) == "Vector3" then args[i] = pr2
                            elseif typeof(v) == "CFrame" then args[i] = CFrame.new(pr2) end
                        end
                        return old(self, unpack(args))
                    end
                end
            end
        end
        return old(self, ...)
    end)
    return true
end

return Silent
