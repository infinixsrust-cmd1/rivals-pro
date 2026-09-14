-- rivals.pro | modules/ESP
-- боксы + хп + дистанция + трейсеры на Drawing API

local ESP = {}
ESP._drawings = {} -- [player] = {box, outline, hpBack, hpFront, name, dist, tracer}

function ESP.Init(Config, Services, Utils)
    ESP.C = Config.ESP
    ESP.S = Services
    ESP.U = Utils

    Services.RunService.RenderStepped:Connect(function()
        if ESP.C.Enabled then
            ESP:Update()
        else
            ESP:HideAll()
        end
    end)

    Services.Players.PlayerRemoving:Connect(function(plr)
        ESP:Clear(plr)
    end)

    return ESP
end

function ESP:Get(plr)
    if not self._drawings[plr] then
        local function new(class, props)
            local d = Drawing.new(class)
            for k, v in pairs(props) do d[k] = v end
            d.Visible = false
            return d
        end
        self._drawings[plr] = {
            outline = new("Square", {Thickness = 3, Color = Color3.new(0,0,0), Filled = false, Transparency = 0.6}),
            box     = new("Square", {Thickness = 1.5, Filled = false, Transparency = 1}),
            hpBack  = new("Square", {Filled = true, Color = Color3.new(0,0,0), Transparency = 0.7}),
            hpFront = new("Square", {Filled = true, Color = Color3.new(0,1,0), Transparency = 1}),
            name    = new("Text", {Size = 13, Center = true, Outline = true, Transparency = 1}),
            dist    = new("Text", {Size = 12, Center = true, Outline = true, Transparency = 1}),
            tracer  = new("Line", {Thickness = 1.5, Transparency = 0.9}),
        }
    end
    return self._drawings[plr]
end

function ESP:Clear(plr)
    local set = self._drawings[plr]
    if set then
        for _, d in pairs(set) do pcall(function() d:Remove() end) end
        self._drawings[plr] = nil
    end
end

function ESP:HideAll()
    for _, set in pairs(self._drawings) do
        for _, d in pairs(set) do d.Visible = false end
    end
end

function ESP:Update()
    local cam = self.S.Camera
    local vpX, vpY = cam.ViewportSize.X, cam.ViewportSize.Y

    for _, plr in ipairs(self.S.Players:GetPlayers()) do
        local set = self:Get(plr)
        local show = true

        if plr == self.S.LocalPlayer then show = false end
        if show and self.C.TeamCheck and self.U.IsTeammate(plr) then show = false end
        if show and not self.U.IsAlive(plr) then show = false end

        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if show and (not root or not head) then show = false end

        if not show then
            for _, d in pairs(set) do d.Visible = false end
            continue
        end

        local myRoot = self.S:GetRoot()
        local distStuds = myRoot and (myRoot.Position - root.Position).Magnitude or 0
        if distStuds > self.C.MaxDistance then
            for _, d in pairs(set) do d.Visible = false end
            continue
        end

        -- проекция: верх головы / низ ног
        local top3d = head.Position + Vector3.new(0, 0.7, 0)
        local bot3d = root.Position - Vector3.new(0, 3, 0)
        local topV, topOn = cam:WorldToViewportPoint(top3d)
        local botV, botOn = cam:WorldToViewportPoint(bot3d)
        if not (topOn and botOn) then
            for _, d in pairs(set) do d.Visible = false end
            continue
        end

        local h = math.abs(botV.Y - topV.Y)
        local w = h * 0.55
        local x = topV.X - w / 2
        local y = topV.Y

        local hp, maxHp = self.U.GetHealth(plr)
        local frac = math.clamp(hp / math.max(maxHp, 1), 0, 1)

        -- box
        set.outline.Visible = self.C.Box
        set.box.Visible = self.C.Box
        if self.C.Box then
            set.outline.Size = Vector2.new(w, h)
            set.outline.Position = Vector2.new(x, y)
            set.box.Size = Vector2.new(w, h)
            set.box.Position = Vector2.new(x, y)
            set.box.Color = self.C.BoxColor
        end

        -- hp bar слева
        set.hpBack.Visible = self.C.HealthBar
        set.hpFront.Visible = self.C.HealthBar
        if self.C.HealthBar then
            local bw = 3
            set.hpBack.Size = Vector2.new(bw, h)
            set.hpBack.Position = Vector2.new(x - bw - 3, y)
            local fh = h * frac
            set.hpFront.Size = Vector2.new(bw, fh)
            set.hpFront.Position = Vector2.new(x - bw - 3, y + (h - fh))
            set.hpFront.Color = Color3.fromRGB(255 - math.floor(255 * frac), math.floor(255 * frac), 0)
        end

        -- имя
        set.name.Visible = self.C.Name
        if self.C.Name then
            set.name.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
            set.name.Position = Vector2.new(topV.X, y - 16)
            set.name.Color = Color3.new(1, 1, 1)
        end

        -- дистанция
        set.dist.Visible = self.C.Distance
        if self.C.Distance then
            set.dist.Text = string.format("[%dm]", math.floor(distStuds))
            set.dist.Position = Vector2.new(topV.X, y + h + 1)
            set.dist.Color = Color3.new(1, 1, 1)
        end

        -- трейсер
        set.tracer.Visible = self.C.Tracers
        if self.C.Tracers then
            local from
            if self.C.TracerFrom == "Mouse" then
                from = self.S.UserInputService:GetMouseLocation()
            elseif self.C.TracerFrom == "Top" then
                from = Vector2.new(vpX / 2, 0)
            else
                from = Vector2.new(vpX / 2, vpY)
            end
            set.tracer.From = from
            set.tracer.To = Vector2.new(topV.X, y + h / 2)
            set.tracer.Color = self.C.BoxColor
        end
    end
end

return ESP
