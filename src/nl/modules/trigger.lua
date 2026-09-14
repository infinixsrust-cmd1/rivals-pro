-- rivals.pro NL | modules/trigger.lua (dedicated file: auto-fire on crosshair)
-- usage: local Trig = loadModule("trigger.lua", Common); Trig.start(C)

local Common = ...
assert(Common and Common.LP, "trigger: Common not injected")

local Trig = {down = false}

local function setMouseDown(v)
    if v == Trig.down then return end
    Trig.down = v
    pcall(function()
        if mouse1press and mouse1release then
            if v then mouse1press() else mouse1release() end
        end
    end)
end

function Trig.start(C)
    local T = C.Trig
    Common.RS.RenderStepped:Connect(function()
        local ok, err = pcall(function()
            if not T.Enabled then
                setMouseDown(false)
                return
            end
            -- hold key gate (optional): if Key set, require hold
            if T.Key then
                local held = false
                pcall(function()
                    held = Common.UIS:IsKeyDown(T.Key)
                        or Common.UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                end)
                if not held then setMouseDown(false) return end
            end
            local c = Common.cam()
            if not c then setMouseDown(false) return end
            local mp = Common.UIS:GetMouseLocation()
            local ray = c:ViewportPointToRay(mp.X, mp.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local myCh = Common.charOf(Common.LP)
            params.FilterDescendantsInstances = myCh and {myCh, c} or {c}
            params.IgnoreWater = true
            local res = workspace:Raycast(ray.Origin, ray.Direction * T.Dist, params)
            if not res or not res.Instance then setMouseDown(false) return end
            local mdl = res.Instance:FindFirstAncestorOfClass("Model")
            local hum = mdl and mdl:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then setMouseDown(false) return end
            local pl = Common.Players:GetPlayerFromCharacter(mdl)
            if pl and pl ~= Common.LP then
                if T.Team and Common.teammate(pl) then setMouseDown(false) return end
                -- delay gate (human-like reaction)
                local now = os.clock()
                Trig._seen = Trig._seen or 0
                if (now - Trig._seen) * 1000 < T.Delay then
                    return -- keep previous state during delay
                end
                setMouseDown(true)
            else
                Trig._seen = os.clock()
                setMouseDown(false)
            end
        end)
        if not ok then
            Trig._err = (Trig._err or 0) + 1
            if Trig._err < 5 then warn("[nl] trig frame: " .. tostring(err)) end
            setMouseDown(false)
        end
    end)
end

return Trig
