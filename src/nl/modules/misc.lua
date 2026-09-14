-- rivals.pro NL | modules/misc.lua (dedicated file)

local Common = ...
assert(Common and Common.LP, "misc: Common not injected")

local Misc = {}

function Misc.start(C)
    if C.Misc.AFK then
        pcall(function()
            local vu = game:GetService("VirtualUser")
            Common.LP.Idled:Connect(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end)
    end
    Common.RS.RenderStepped:Connect(function()
        if C.Misc.NoShake then
            local h = Common.humOf(Common.LP)
            if h then h.CameraOffset = Vector3.zero end
        end
        if C.Misc.Bright then
            Common.Lighting.Brightness = 2 Common.Lighting.ClockTime = 14
            Common.Lighting.FogEnd = 1e5 Common.Lighting.GlobalShadows = false
        end
    end)
end

return Misc
