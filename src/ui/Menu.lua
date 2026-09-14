-- rivals.pro | ui/Menu
-- лёгкое меню на чистом Roblox GUI (без Rayfield — работает в любом executor)
-- вкладки: Aim / Visuals / Gun / Move / Misc

local Menu = {}
Menu._built = false

function Menu.Init(Config, Services, Utils, Modules)
    Menu.C = Config
    Menu.S = Services
    Menu.U = Utils
    Menu.M = Modules

    local gui = Instance.new("ScreenGui")
    gui.Name = "rivalspro"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if not gui.Parent then
        gui.Parent = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    -- окно
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 440, 0, 340)
    main.Position = UDim2.new(0.5, -220, 0.5, -170)
    main.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(255, 0, 60)
    stroke.Thickness = 1.5

    -- шапка
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundTransparency = 1
    title.Text = "  rivals.pro  v1.0.0  |  RightShift — скрыть"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    -- контейнер вкладок
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -16, 0, 30)
    tabBar.Position = UDim2.new(0, 8, 0, 38)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -16, 1, -84)
    content.Position = UDim2.new(0, 8, 0, 72)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.CanvasSize = UDim2.new(0, 0, 0, 600)
    content.Parent = main
    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0, 4)

    Menu._gui = gui
    Menu._main = main
    Menu._content = content

    -- тоггл видимости
    Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Config.UI.ToggleKey then
            main.Visible = not main.Visible
        end
    end)

    Menu:BuildTab("Aim", {
        {"toggle", "Aimbot", Config.Aimbot, "Enabled"},
        {"toggle", "Silent Aim", Config.SilentAim, "Enabled"},
        {"slider", "Smoothness", Config.Aimbot, "Smoothness", 1, 20, 1},
        {"slider", "FOV", Config.Aimbot, "FOV", 20, 400, 5},
        {"slider", "HitChance %", Config.SilentAim, "HitChance", 1, 100, 1},
        {"slider", "Prediction", Config.Aimbot, "Prediction", 0, 0.3, 0.005},
        {"toggle", "Show FOV", Config.Aimbot, "ShowFOV"},
        {"toggle", "Wall Check", Config.Aimbot, "WallCheck"},
        {"toggle", "Team Check", Config.Aimbot, "TeamCheck"},
        {"toggle", "Sticky Target", Config.Aimbot, "StickyTarget"},
    })
    Menu:BuildTab("Visuals", {
        {"toggle", "ESP", Config.ESP, "Enabled"},
        {"toggle", "Box", Config.ESP, "Box"},
        {"toggle", "Name", Config.ESP, "Name"},
        {"toggle", "Health Bar", Config.ESP, "HealthBar"},
        {"toggle", "Distance", Config.ESP, "Distance"},
        {"toggle", "Tracers", Config.ESP, "Tracers"},
        {"toggle", "Fullbright", Config.Misc, "Fullbright"},
        {"toggle", "FPS Boost (применить)", Config.Misc, "FPSBoost", function(v)
            if v and Modules.Misc then Modules.Misc:ApplyFPSBoost() end
        end},
    })
    Menu:BuildTab("Gun", {
        {"toggle", "No Recoil", Config.GunMods, "NoRecoil"},
        {"toggle", "No Spread", Config.GunMods, "NoSpread"},
        {"toggle", "Rapid Fire", Config.GunMods, "RapidFire"},
        {"toggle", "Infinite Ammo", Config.GunMods, "InfiniteAmmo"},
        {"toggle", "Instant Reload", Config.GunMods, "InstantReload"},
        {"slider", "FireRate x", Config.GunMods, "FireRateMult", 1, 5, 0.1},
    })
    Menu:BuildTab("Move", {
        {"toggle", "Speed", Config.Movement, "SpeedEnabled"},
        {"slider", "Speed", Config.Movement, "Speed", 16, 100, 1},
        {"toggle", "Fly (F)", Config.Movement, "FlyEnabled"},
        {"slider", "Fly Speed", Config.Movement, "FlySpeed", 10, 150, 5},
        {"toggle", "Noclip", Config.Movement, "Noclip"},
        {"toggle", "Infinite Jump", Config.Movement, "InfiniteJump"},
        {"toggle", "No Knockback", Config.Movement, "NoKnockback"},
        {"toggle", "No Cam Shake", Config.Misc, "NoCameraShake"},
    })

    -- показываем первую вкладку
    Menu:ShowTab("Aim")
    Menu._built = true
    return Menu
end

Menu._tabs = {}

function Menu:BuildTab(name, rows)
    -- кнопка вкладки
    local idx = #self._tabs
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Position = UDim2.new(0, idx * 104, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = name
    btn.Parent = self._main:FindFirstChildOfClass("Frame") or self._main
    -- ищем tabBar: второй Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() self:ShowTab(name) end)

    -- строки
    local frame = Instance.new("Frame")
    frame.Name = "Tab_" .. name
    frame.Size = UDim2.new(1, -4, 0, #rows * 32)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = self._content

    local l = Instance.new("UIListLayout", frame)
    l.Padding = UDim.new(0, 2)

    for _, row in ipairs(rows) do
        local kind, label, tbl, key, a, b, step = row[1], row[2], row[3], row[4], row[5], row[6], row[7]
        local cb = row[8]
        if kind == "toggle" then
            self:RowToggle(frame, label, tbl, key, cb)
        elseif kind == "slider" then
            self:RowSlider(frame, label, tbl, key, a, b, step)
        end
    end

    self._tabs[name] = {btn = btn, frame = frame}
end

function Menu:ShowTab(name)
    for n, t in pairs(self._tabs) do
        local active = (n == name)
        t.frame.Visible = active
        t.btn.BackgroundColor3 = active and Color3.fromRGB(255, 0, 60) or Color3.fromRGB(24, 24, 30)
    end
end

function Menu:RowToggle(parent, label, tbl, key, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

    local function refresh()
        b.Text = string.format("  %s  [%s]", label, tbl[key] and "ON" or "OFF")
        b.BackgroundColor3 = tbl[key] and Color3.fromRGB(60, 10, 20) or Color3.fromRGB(22, 22, 28)
    end
    refresh()
    b.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        if cb then pcall(cb, tbl[key]) end
        refresh()
    end)
end

function Menu:RowSlider(parent, label, tbl, key, min, max, step)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 28)
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -70, 1, 0)
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.Gotham
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = f

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 30, 1, 0)
    minus.Position = UDim2.new(1, -62, 0, 0)
    minus.Text = "-"
    minus.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
    minus.TextColor3 = Color3.new(1, 1, 1)
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 14
    minus.Parent = f

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 30, 1, 0)
    plus.Position = UDim2.new(1, -30, 0, 0)
    plus.Text = "+"
    plus.BackgroundColor3 = Color3.fromRGB(255, 0, 60)
    plus.TextColor3 = Color3.new(1, 1, 1)
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 14
    plus.Parent = f

    local function refresh()
        t.Text = string.format("  %s: %s", label, tostring(tbl[key]))
    end
    refresh()
    minus.MouseButton1Click:Connect(function()
        tbl[key] = math.clamp((tbl[key] - step), min, max)
        -- округление под шаг
        tbl[key] = math.floor(tbl[key] / step + 0.5) * step
        refresh()
    end)
    plus.MouseButton1Click:Connect(function()
        tbl[key] = math.clamp((tbl[key] + step), min, max)
        tbl[key] = math.floor(tbl[key] / step + 0.5) * step
        refresh()
    end)
end

return Menu
