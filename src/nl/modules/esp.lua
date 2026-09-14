-- rivals.pro NL | modules/esp.lua (dedicated file)

local Common = ...
assert(Common and Common.LP, "esp: Common not injected")

local ESP = {objs = {}}

function ESP.get(p)
    if ESP.objs[p] then return ESP.objs[p] end
    local box = Common.mkDraw("Square", {Thickness=1.5, Filled=false, Transparency=1})
    local hp = Common.mkDraw("Square", {Filled=true, Transparency=1})
    local nm = Common.mkDraw("Text", {Size=13, Center=true, Outline=true, Transparency=1})
    local ds = Common.mkDraw("Text", {Size=12, Center=true, Outline=true, Transparency=1})
    local tr = Common.mkDraw("Line", {Thickness=1.5, Transparency=0.9})
    if not (box and hp and nm and ds and tr) then return nil end
    ESP.objs[p] = {box=box, hp=hp, nm=nm, ds=ds, tr=tr}
    return ESP.objs[p]
end

function ESP.start(C)
    local E = C.ESP
    Common.Players.PlayerRemoving:Connect(function(p)
        local s = ESP.objs[p]
        if s then for _, d in pairs(s) do pcall(function() d.Visible = false end) end ESP.objs[p] = nil end
    end)
    Common.RS.RenderStepped:Connect(function()
        local ok, err = pcall(function()
        for _, p in ipairs(Common.Players:GetPlayers()) do
            local s = ESP.get(p)
            if not s then continue end
            local show = E.Enabled and p ~= Common.LP and Common.alive(p)
                and not Common.shielded(p) and not (E.Team and Common.teammate(p))
            local ch = Common.charOf(p)
            local rt = ch and ch:FindFirstChild("HumanoidRootPart")
            local hd = ch and ch:FindFirstChild("Head")
            if show and (not rt or not hd) then show = false end
            local myR = Common.rootOf(Common.LP)
            local dd = (myR and rt) and (myR.Position - rt.Position).Magnitude or 0
            if show and dd > E.MaxD then show = false end
            if not show then
                for _, d in pairs(s) do d.Visible = false end
                continue
            end
            local c = Common.cam()
            local tv, ton = c:WorldToViewportPoint(hd.Position + Vector3.new(0, 0.7, 0))
            local bv, bon = c:WorldToViewportPoint(rt.Position - Vector3.new(0, 3, 0))
            if not (ton and bon) then
                for _, d in pairs(s) do d.Visible = false end
                continue
            end
            local h = math.abs(bv.Y - tv.Y)
            if h < 4 or h > 2500 then
                for _, d in pairs(s) do d.Visible = false end
                continue
            end
            local w, x, y = h * 0.55, tv.X - (h * 0.55) / 2, tv.Y
            s.box.Visible = E.Box
            if E.Box then
                s.box.Size = Vector2.new(w, h) s.box.Position = Vector2.new(x, y)
                s.box.Color = E.Color
            end
            local hu = Common.humOf(p)
            local fr = hu and math.clamp(hu.Health / math.max(hu.MaxHealth, 1), 0, 1) or 1
            s.hp.Visible = E.HP
            if E.HP then
                local fh = h * fr
                s.hp.Size = Vector2.new(3, fh)
                s.hp.Position = Vector2.new(x - 6, y + (h - fh))
                s.hp.Color = Color3.fromRGB(255 - math.floor(255 * fr), math.floor(255 * fr), 0)
            end
            s.nm.Visible = E.Name
            if E.Name then
                s.nm.Text = p.Name s.nm.Position = Vector2.new(tv.X, y - 16)
                s.nm.Color = Color3.new(1, 1, 1)
            end
            s.ds.Visible = E.Dist
            if E.Dist then
                s.ds.Text = "[" .. math.floor(dd) .. "m]"
                s.ds.Position = Vector2.new(tv.X, y + h + 1)
                s.ds.Color = Color3.new(1, 1, 1)
            end
            s.tr.Visible = E.Tracer
            if E.Tracer then
                s.tr.From = Vector2.new(c.ViewportSize.X / 2, c.ViewportSize.Y)
                s.tr.To = Vector2.new(tv.X, y + h / 2)
                s.tr.Color = E.Color
            end
        end
        end)
        if not ok then
            ESP._err = (ESP._err or 0) + 1
            if ESP._err < 5 then warn("[nl] esp frame: " .. tostring(err)) end
        end
    end)
end

return ESP
