-- rivals.pro NL | modules/common.lua
-- shared context: services + helpers (ASCII only)
-- loaded as: local Common = loadModule("nl/modules/common.lua")()

local Common = {}

Common.Players = game:GetService("Players")
Common.RS = game:GetService("RunService")
Common.UIS = game:GetService("UserInputService")
Common.Lighting = game:GetService("Lighting")
Common.StarterGui = game:GetService("StarterGui")
Common.RSv = game:GetService("ReplicatedStorage")
Common.LP = Common.Players.LocalPlayer

function Common.cam() return workspace.CurrentCamera end

function Common.notify(t, s)
    pcall(function()
        Common.StarterGui:SetCore("SendNotification", {Title = t, Text = s, Duration = 4})
    end)
end

function Common.charOf(p) return p and p.Character end
function Common.humOf(p)
    local ch = Common.charOf(p)
    return ch and ch:FindFirstChildOfClass("Humanoid")
end
function Common.rootOf(p)
    local ch = Common.charOf(p)
    return ch and ch:FindFirstChild("HumanoidRootPart")
end
function Common.alive(p)
    local h = Common.humOf(p)
    return h ~= nil and h.Health > 0
end
function Common.shielded(p)
    local ch = Common.charOf(p)
    return ch and ch:FindFirstChildOfClass("ForceField") ~= nil
end
function Common.teammate(p)
    local LP = Common.LP
    if not (p and LP) or p == LP then return p == LP end
    local ok, t = pcall(function() return p.Team end)
    if not ok or t == nil then return false end
    local ok2, mine = pcall(function() return LP.Team end)
    if not ok2 or mine == nil then return false end
    return t == mine
end
function Common.partOf(ch, name)
    if not ch then return nil end
    if name == "Head" then
        return ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
    elseif name == "Chest" then
        return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
            or ch:FindFirstChild("HumanoidRootPart")
    elseif name == "Legs" then
        return ch:FindFirstChild("LowerTorso") or ch:FindFirstChild("HumanoidRootPart")
    elseif name == "Random" then
        local pool = {}
        for _, n in ipairs({"Head","UpperTorso","HumanoidRootPart","LowerTorso"}) do
            local pt = ch:FindFirstChild(n)
            if pt then pool[#pool+1] = pt end
        end
        if #pool == 0 then return nil end
        return pool[math.random(1, #pool)]
    end
    return ch:FindFirstChild("HumanoidRootPart")
end
function Common.visible(part)
    if not part then return false end
    local c = Common.cam()
    if not c then return false end
    local myCh = Common.charOf(Common.LP)
    local org = c.CFrame.Position
    local dir = part.Position - org
    if dir.Magnitude < 1 then return true end
    local pr = RaycastParams.new()
    pr.FilterType = Enum.RaycastFilterType.Exclude
    local filt = {c}
    if myCh then filt[#filt+1] = myCh end
    if part.Parent then filt[#filt+1] = part.Parent end
    pr.FilterDescendantsInstances = filt
    pr.IgnoreWater = true
    local ok, r = pcall(function() return workspace:Raycast(org, dir, pr) end)
    if not ok or not r then return true end
    return (r.Position - part.Position).Magnitude < 5
end
function Common.predict(part, k)
    local ok, v = pcall(function() return part.Velocity end)
    if not ok or typeof(v) ~= "Vector3" then return part.Position end
    if v.Magnitude > 200 then return part.Position end
    return part.Position + v * math.clamp(k or 0, 0, 0.3)
end
function Common.toScreen(pos)
    local c = Common.cam()
    if not c then return Vector2.new(0,0), false end
    local v, on = c:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), on
end
function Common.mkDraw(cls, props)
    local ok, d = pcall(function() return Drawing.new(cls) end)
    if not ok or not d then return nil end
    for k, v in pairs(props) do pcall(function() d[k] = v end) end
    d.Visible = false
    getgenv()._rp_draw = getgenv()._rp_draw or {}
    getgenv()._rp_draw[#getgenv()._rp_draw+1] = d
    return d
end

return Common
