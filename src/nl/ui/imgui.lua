-- rivals.pro NL | ui/imgui.lua
-- MEDUSA clickgui style: near-black, purple accent, logo header,
-- top icon bar (pulse icons), left category list, rows with
-- right-side purple checkboxes, pill dropdowns, purple sliders.
-- Toggle: INSERT. Icons: assets/icons/*.png via getcustomasset (fallback: text).
-- usage: local Im = loadModule("nl/ui/imgui.lua")(Common, C, Mods)

local Common, C, Mods = ...
assert(Common and C and Mods, "imgui: args missing")

local Im = {}
-- medusa palette
Im.ACC = Color3.fromRGB(168, 130, 255)
Im.BG = Color3.fromRGB(13, 13, 17)
Im.PANEL = Color3.fromRGB(19, 19, 25)
Im.ROW = Color3.fromRGB(26, 26, 33)
Im.TXT = Color3.fromRGB(235, 235, 240)
Im.DIM = Color3.fromRGB(130, 130, 142)
Im.OFF = Color3.fromRGB(45, 45, 55)

-- icon helper: tries executor file first, else nil (text fallback)
function Im.icon(name, size)
    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.Size = UDim2.new(0, size or 18, 0, size or 18)
    img.ImageColor3 = Im.DIM
    local ok, path = pcall(function()
        if getcustomasset then
            return getcustomasset("rivals-pro/assets/icons/" .. name .. ".png")
        end
        return nil
    end)
    if ok and path then
        img.Image = path
    else
        -- fallback glyphs (ASCII only)
        local glyphs = {home="H", modules="M", visuals="V", loot="L", utilities="U",
            configs="C", friends="F", hud="D", search="S", shield="*", bell="!",
            key="K", save=">", load="<", trash="X", play=">", pause="||"}
        local t = Instance.new("TextLabel")
        t.Size = img.Size t.BackgroundTransparency = 1
        t.Text = glyphs[name] or "o" t.TextColor3 = Im.DIM
        t.Font = Enum.Font.GothamBold t.TextSize = 12 t.Parent = img
        img.Image = ""
    end
    return img
end

function Im.build()
    local parent
    do
        local okH, h = pcall(function() return gethui and gethui() end)
        if okH and h then parent = h
        else
            local okC, cg = pcall(function() return game:GetService("CoreGui") end)
            local probe = Instance.new("ScreenGui")
            local okP = pcall(function() probe.Parent = cg probe:Destroy() end)
            parent = (okC and okP) and cg or Common.LP:WaitForChild("PlayerGui")
        end
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "rivalspro" gui.ResetOnSpawn = false gui.Parent = parent
    Im.gui = gui

    -- main window
    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 620, 0, 400) win.Position = UDim2.new(0.5, -310, 0.5, -200)
    win.BackgroundColor3 = Im.BG win.BorderSizePixel = 0
    win.Active = true win.Draggable = true win.Parent = gui
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)
    Im.win = win

    -- header: logo + name + build date (medusa top-left)
    local head = Instance.new("Frame")
    head.Size = UDim2.new(1, 0, 0, 52) head.BackgroundTransparency = 1 head.Parent = win
    local logo = Im.icon("pulse_ico", 26)
    logo.Position = UDim2.new(0, 14, 0, 8) logo.ImageColor3 = Im.ACC logo.Parent = head
    local ttl = Instance.new("TextLabel")
    ttl.Position = UDim2.new(0, 46, 0, 6) ttl.Size = UDim2.new(0, 200, 0, 22)
    ttl.BackgroundTransparency = 1 ttl.Text = "MEDUSA" ttl.TextColor3 = Im.TXT
    ttl.Font = Enum.Font.GothamBlack ttl.TextSize = 16
    ttl.TextXAlignment = Enum.TextXAlignment.Left ttl.Parent = head
    local sub = Instance.new("TextLabel")
    sub.Position = UDim2.new(0, 47, 0, 26) sub.Size = UDim2.new(0, 200, 0, 14)
    sub.BackgroundTransparency = 1 ttl.Text = "MEDUSA"
    sub.Text = "Build date: Sep 14 2026" sub.TextColor3 = Im.DIM
    sub.Font = Enum.Font.Gotham sub.TextSize = 10
    sub.TextXAlignment = Enum.TextXAlignment.Left sub.Parent = head

    -- top icon bar (medusa top-right): home/modules/visuals/loot/utilities/configs
    local iconbar = Instance.new("Frame")
    iconbar.Size = UDim2.new(0, 260, 0, 30) iconbar.Position = UDim2.new(1, -270, 0, 12)
    iconbar.BackgroundColor3 = Im.PANEL iconbar.BorderSizePixel = 0 iconbar.Parent = head
    Instance.new("UICorner", iconbar).CornerRadius = UDim.new(0, 6)
    local il = Instance.new("UIListLayout", iconbar)
    il.FillDirection = Enum.FillDirection.Horizontal il.Padding = UDim.new(0, 2)
    il.HorizontalAlignment = Enum.HorizontalAlignment.Center
    il.VerticalAlignment = Enum.VerticalAlignment.Center
    Im.iconBtns = {}
    local icons = {"home", "modules", "visuals", "hud", "utilities", "configs", "search"}
    for _, n in ipairs(icons) do
        local b = Instance.new("ImageButton")
        b.Size = UDim2.new(0, 26, 0, 24) b.BackgroundTransparency = 1
        b.ImageColor3 = Im.DIM b.AutoButtonColor = false b.Parent = iconbar
        local ok, path = pcall(function()
            if getcustomasset then return getcustomasset("rivals-pro/assets/icons/" .. n .. ".png") end
            return nil
        end)
        if ok and path then b.Image = path else b.Text = "" end
        b.MouseEnter:Connect(function() b.ImageColor3 = Im.ACC end)
        b.MouseLeave:Connect(function() b.ImageColor3 = Im.DIM end)
        Im.iconBtns[n] = b
    end

    -- tab row is driven by init.lua (finds Frame at Y=32 area); keep compatible:
    -- medusa has no text tabs; we keep a slim tab strip under header for init.lua hooks
    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1, -16, 0, 28) tabs.Position = UDim2.new(0, 8, 0, 56)
    tabs.BackgroundTransparency = 1 tabs.Parent = win
    local tl = Instance.new("UIListLayout", tabs)
    tl.FillDirection = Enum.FillDirection.Horizontal tl.Padding = UDim.new(0, 4)

    -- content: left category list + right single panel (medusa: list left, settings right)
    local cat = Instance.new("Frame")
    cat.Size = UDim2.new(0, 150, 1, -96) cat.Position = UDim2.new(0, 8, 0, 88)
    cat.BackgroundColor3 = Im.PANEL cat.BorderSizePixel = 0 cat.Parent = win
    Instance.new("UICorner", cat).CornerRadius = UDim.new(0, 6)
    local cl = Instance.new("UIListLayout", cat) cl.Padding = UDim.new(0, 2)
    local cp = Instance.new("UIPadding", cat)
    cp.PaddingTop = UDim.new(0, 6) cp.PaddingLeft = UDim.new(0, 6) cp.PaddingRight = UDim.new(0, 6)
    Im.cat = cat

    local body = Instance.new("ScrollingFrame")
    body.Size = UDim2.new(1, -174, 1, -96) body.Position = UDim2.new(0, 166, 0, 88)
    body.BackgroundColor3 = Im.PANEL body.BorderSizePixel = 0
    body.ScrollBarThickness = 3 body.CanvasSize = UDim2.new(0, 0, 0, 900) body.Parent = win
    Instance.new("UICorner", body).CornerRadius = UDim.new(0, 6)
    local bl = Instance.new("UIListLayout", body) bl.Padding = UDim.new(0, 6)
    local bp = Instance.new("UIPadding", body)
    bp.PaddingTop = UDim.new(0, 10) bp.PaddingLeft = UDim.new(0, 12) bp.PaddingRight = UDim.new(0, 12)
    -- compat: init.lua writes into Im.left / Im.right; map both to body columns
    local left = Instance.new("Frame")
    left.Size = UDim2.new(1, 0, 0, 0) left.BackgroundTransparency = 1 left.AutomaticSize = Enum.AutomaticSize.Y
    left.Parent = body
    local ll = Instance.new("UIListLayout", left) ll.Padding = UDim.new(0, 6)
    local right = Instance.new("Frame")
    right.Size = UDim2.new(1, 0, 0, 0) right.BackgroundTransparency = 1 right.AutomaticSize = Enum.AutomaticSize.Y
    right.Parent = body
    local rl = Instance.new("UIListLayout", right) rl.Padding = UDim.new(0, 6)
    Im.left, Im.right = left, right
    Im.pages = {}
    Im.tabBtns = {}

    Common.UIS.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.Insert then
            win.Visible = not win.Visible
        end
    end)

    -- watermark
    local wm = Instance.new("TextLabel")
    wm.Size = UDim2.new(0, 260, 0, 20) wm.Position = UDim2.new(0, 10, 0, 10)
    wm.BackgroundColor3 = Im.BG wm.BorderSizePixel = 0
    wm.TextColor3 = Im.TXT wm.Font = Enum.Font.Gotham wm.TextSize = 12
    wm.TextXAlignment = Enum.TextXAlignment.Left wm.Parent = gui
    Instance.new("UICorner", wm).CornerRadius = UDim.new(0, 5)
    task.spawn(function()
        local last = os.clock() local frames = 0
        Common.RS.RenderStepped:Connect(function() frames = frames + 1 end)
        while true do
            task.wait(1)
            pcall(function()
                local now = os.clock()
                local fps = (now - last) > 0 and math.floor(frames / (now - last) + 0.5) or 60
                frames, last = 0, now
                local tgt = (Mods.Aimbot and Mods.Aimbot.targetName) or "none"
                wm.Text = " medusa | " .. tostring(fps) .. "fps | " .. tostring(tgt)
            end)
        end
    end)

    return Im
end

-- ---- medusa widgets ----
-- row: label left, purple checkbox right (like screenshot)
function Im.checkbox(parent, label, tbl, key, cb)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 26) row.BackgroundTransparency = 1
    row.Text = "" row.AutoButtonColor = false row.Parent = parent
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -30, 1, 0) t.BackgroundTransparency = 1
    t.Text = label t.Font = Enum.Font.Gotham t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = row
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 16, 0, 16) box.Position = UDim2.new(1, -20, 0.5, -8)
    box.BorderSizePixel = 0 box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    local mark = Instance.new("TextLabel")
    mark.Size = UDim2.new(1, 0, 1, 0) mark.BackgroundTransparency = 1
    mark.Text = "+" mark.Font = Enum.Font.GothamBold mark.TextSize = 12
    mark.TextColor3 = Color3.new(1,1,1) mark.Parent = box
    local function rf()
        t.TextColor3 = tbl[key] and Im.TXT or Im.DIM
        box.BackgroundColor3 = tbl[key] and Im.ACC or Im.OFF
        mark.Text = tbl[key] and "+" or ""
    end
    rf()
    row.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        if cb then pcall(cb, tbl[key]) end
        rf()
    end)
    return row
end

-- medusa slider: label + value right, purple bar with knob
function Im.slider(parent, label, tbl, key, mn, mx, sp)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 40) f.BackgroundTransparency = 1 f.Parent = parent
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0.6, 0, 0, 16) t.BackgroundTransparency = 1
    t.Text = label t.TextColor3 = Im.DIM t.Font = Enum.Font.Gotham t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = f
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.4, 0, 0, 16) v.Position = UDim2.new(0.6, 0, 0, 0)
    v.BackgroundTransparency = 1
    v.TextColor3 = Im.TXT v.Font = Enum.Font.Gotham v.TextSize = 12
    v.TextXAlignment = Enum.TextXAlignment.Right v.Parent = f
    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 6) bar.Position = UDim2.new(0, 0, 0, 26)
    bar.BackgroundColor3 = Im.OFF bar.BorderSizePixel = 0
    bar.Text = "" bar.AutoButtonColor = false bar.Parent = f
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.5, 0, 1, 0) fill.BorderSizePixel = 0
    fill.BackgroundColor3 = Im.ACC fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12) knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Color3.new(1,1,1) knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local function rf()
        local val = tbl[key]
        local fr = (val - mn) / math.max(mx - mn, 1e-6)
        fr = math.clamp(fr, 0, 1)
        fill.Size = UDim2.new(fr, 0, 1, 0)
        knob.Position = UDim2.new(fr, -6, 0.5, -6)
        local disp = val
        if sp < 1 then disp = math.floor(val / sp + 0.5) * sp end
        if sp >= 1 then disp = string.format("%d", math.floor(disp + 0.5))
        else disp = tostring(disp) end
        v.Text = disp
    end
    rf()
    local function setFromX(x)
        local ax = bar.AbsolutePosition.X
        local aw = math.max(bar.AbsoluteSize.X, 1)
        local fr = math.clamp((x - ax) / aw, 0, 1)
        local steps = math.floor(((mx - mn) / sp) + 0.5)
        tbl[key] = mn + math.floor(fr * steps + 0.5) * sp
        rf()
    end
    bar.MouseButton1Down:Connect(function(x) setFromX(x) end)
    Common.UIS.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
            and Common.UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local m = Common.UIS:GetMouseLocation()
            local p = bar.AbsolutePosition
            local s = bar.AbsoluteSize
            if m.Y >= p.Y - 8 and m.Y <= p.Y + s.Y + 8 then
                setFromX(m.X)
            end
        end
    end)
    return f
end

-- medusa dropdown: label left + pill right
function Im.combo(parent, label, tbl, key, opts)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26) row.BackgroundTransparency = 1 row.Parent = parent
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0.35, 0, 1, 0) t.BackgroundTransparency = 1
    t.Text = label t.TextColor3 = Im.DIM t.Font = Enum.Font.Gotham t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = row
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.65, 0, 0, 22) b.Position = UDim2.new(0.35, 0, 0.5, -11)
    b.BackgroundColor3 = Im.ROW b.BorderSizePixel = 0
    b.TextColor3 = Im.DIM b.Font = Enum.Font.Gotham b.TextSize = 11
    b.AutoButtonColor = false b.Parent = row
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local function rf() b.Text = tostring(tbl[key]) .. "  v" end
    rf()
    b.MouseButton1Click:Connect(function()
        local i = 1
        for k, vv in ipairs(opts) do if vv == tbl[key] then i = k break end end
        tbl[key] = opts[(i % #opts) + 1]
        rf()
    end)
    return row
end

function Im.group(parent, title)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18) l.BackgroundTransparency = 1
    l.Text = title l.TextColor3 = Im.DIM
    l.Font = Enum.Font.Gotham l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = parent
end

function Im.button(parent, label, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28) b.BackgroundColor3 = Im.ACC
    b.BorderSizePixel = 0
    b.Text = label b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold b.TextSize = 12 b.AutoButtonColor = false b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(function() pcall(fn) end)
    return b
end

function Im.textbox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 24) box.BackgroundColor3 = Im.ROW
    box.BorderSizePixel = 0
    box.TextColor3 = Im.TXT box.Font = Enum.Font.Gotham box.TextSize = 12
    box.PlaceholderText = placeholder or "" box.PlaceholderColor3 = Im.DIM box.Text = ""
    box.TextXAlignment = Enum.TextXAlignment.Left box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    return box
end

function Im.status(parent, h)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, h or 40) l.BackgroundColor3 = Im.ROW
    l.BorderSizePixel = 0
    l.TextColor3 = Im.DIM l.Font = Enum.Font.Gotham l.TextSize = 11
    l.TextWrapped = true l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top l.Parent = parent
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 5)
    return l
end

return Im
