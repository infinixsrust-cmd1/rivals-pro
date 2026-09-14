-- rivals.pro NL | ui/imgui.lua
-- Dear ImGui / CS-style menu: dark window, accent bar, tabs, checkboxes,
-- sliders, combos, child groups. Toggle: INSERT (like CS cheats).
-- usage: local ImGui = loadModule("nl/ui/imgui.lua")(Common, C, Mods)

local Common, C, Mods = ...
assert(Common and C and Mods, "imgui: args missing")

local Im = {}
-- imgui palette (classic dark + blue accent, CS-like)
Im.ACC = Color3.fromRGB(90, 140, 255)
Im.BG = Color3.fromRGB(16, 16, 20)
Im.CHILD = Color3.fromRGB(24, 24, 30)
Im.ROW = Color3.fromRGB(30, 30, 38)
Im.TXT = Color3.new(1, 1, 1)
Im.DIM = Color3.fromRGB(150, 150, 160)

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

    -- main window (imgui style: title bar + body)
    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 560, 0, 380) win.Position = UDim2.new(0.5, -280, 0.5, -190)
    win.BackgroundColor3 = Im.BG win.BorderSizePixel = 1 win.BorderColor3 = Color3.fromRGB(45,45,55)
    win.Active = true win.Draggable = true win.Parent = gui
    Im.win = win

    -- accent top line (imgui title bar strip)
    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(1, 0, 0, 2) strip.BorderSizePixel = 0
    strip.BackgroundColor3 = Im.ACC strip.Parent = win
    Im.strip = strip

    local bar = Instance.new("TextLabel")
    bar.Size = UDim2.new(1, -8, 0, 26) bar.Position = UDim2.new(0, 8, 0, 4)
    bar.BackgroundTransparency = 1 bar.Text = "rivals.pro  |  cs gui  |  [ins] menu"
    bar.TextColor3 = Im.TXT bar.Font = Enum.Font.Code bar.TextSize = 13
    bar.TextXAlignment = Enum.TextXAlignment.Left bar.Parent = win

    -- tab row (imgui TabBar)
    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1, -16, 0, 28) tabs.Position = UDim2.new(0, 8, 0, 32)
    tabs.BackgroundTransparency = 1 tabs.Parent = win
    local tl = Instance.new("UIListLayout", tabs)
    tl.FillDirection = Enum.FillDirection.Horizontal tl.Padding = UDim.new(0, 4)

    -- content area: two child columns (imgui BeginChild)
    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, -16, 1, -68) body.Position = UDim2.new(0, 8, 0, 62)
    body.BackgroundTransparency = 1 body.Parent = win

    local left = Instance.new("ScrollingFrame")
    left.Size = UDim2.new(0.5, -3, 1, 0) left.BackgroundColor3 = Im.CHILD
    left.BorderSizePixel = 1 left.BorderColor3 = Color3.fromRGB(40,40,50)
    left.ScrollBarThickness = 3 left.CanvasSize = UDim2.new(0,0,0,900) left.Parent = body
    local ll = Instance.new("UIListLayout", left) ll.Padding = UDim.new(0, 4)
    local lp = Instance.new("UIPadding", left)
    lp.PaddingTop = UDim.new(0,6) lp.PaddingLeft = UDim.new(0,6) lp.PaddingRight = UDim.new(0,6)

    local right = Instance.new("ScrollingFrame")
    right.Size = UDim2.new(0.5, -3, 1, 0) right.Position = UDim2.new(0.5, 3, 0, 0)
    right.BackgroundColor3 = Im.CHILD
    right.BorderSizePixel = 1 right.BorderColor3 = Color3.fromRGB(40,40,50)
    right.ScrollBarThickness = 3 right.CanvasSize = UDim2.new(0,0,0,900) right.Parent = body
    local rl = Instance.new("UIListLayout", right) rl.Padding = UDim.new(0, 4)
    local rp = Instance.new("UIPadding", right)
    rp.PaddingTop = UDim.new(0,6) rp.PaddingLeft = UDim.new(0,6) rp.PaddingRight = UDim.new(0,6)

    Im.left, Im.right = left, right
    Im.pages = {}
    Im.tabBtns = {}

    -- INSERT toggle (CS style)
    Common.UIS.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.Insert then
            win.Visible = not win.Visible
        end
    end)

    -- watermark (imgui overlay style)
    local wm = Instance.new("TextLabel")
    wm.Size = UDim2.new(0, 250, 0, 20) wm.Position = UDim2.new(0, 10, 0, 10)
    wm.BackgroundColor3 = Im.BG wm.BorderSizePixel = 1 wm.BorderColor3 = Color3.fromRGB(45,45,55)
    wm.TextColor3 = Im.TXT wm.Font = Enum.Font.Code wm.TextSize = 12
    wm.TextXAlignment = Enum.TextXAlignment.Left wm.Parent = gui
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
                wm.Text = " rivals.pro | " .. tostring(fps) .. "fps | " .. tostring(tgt)
            end)
        end
    end)

    return Im
end

-- ---- widgets (imgui look) ----
function Im.tab(name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 90, 1, 0) b.BackgroundColor3 = Im.ROW
    b.Text = name b.TextColor3 = Im.TXT b.Font = Enum.Font.Code b.TextSize = 12
    b.AutoButtonColor = false b.Parent = Im.gui and Im.win and Im.win:FindFirstChildOfClass("Frame")
    -- parent fix: tabs container is 2nd Frame
    return b
end

function Im.checkbox(parent, label, tbl, key, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 22) b.BackgroundTransparency = 1
    b.TextXAlignment = Enum.TextXAlignment.Left b.AutoButtonColor = false b.Parent = parent
    b.TextColor3 = Im.TXT b.Font = Enum.Font.Code b.TextSize = 12
    local function rf()
        b.Text = (tbl[key] and "[x] " or "[  ] ") .. label
        b.TextColor3 = tbl[key] and Im.TXT or Im.DIM
    end
    rf()
    b.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        if cb then pcall(cb, tbl[key]) end
        rf()
    end)
    return b
end

function Im.slider(parent, label, tbl, key, mn, mx, sp)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 34) f.BackgroundTransparency = 1 f.Parent = parent
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, 14) t.BackgroundTransparency = 1
    t.TextColor3 = Im.DIM t.Font = Enum.Font.Code t.TextSize = 11
    t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = f
    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 14) bar.Position = UDim2.new(0, 0, 0, 18)
    bar.BackgroundColor3 = Im.ROW bar.BorderSizePixel = 0
    bar.Text = "" bar.AutoButtonColor = false bar.Parent = f
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.5, 0, 1, 0) fill.BorderSizePixel = 0
    fill.BackgroundColor3 = Im.ACC fill.Parent = bar
    local function rf()
        local v = tbl[key]
        local fr = (v - mn) / math.max(mx - mn, 1e-6)
        fill.Size = UDim2.new(math.clamp(fr, 0, 1), 0, 1, 0)
        local disp = v
        if sp < 1 then disp = math.floor(v / sp + 0.5) * sp end
        t.Text = label .. ": " .. tostring(disp)
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
            if m.Y >= p.Y - 6 and m.Y <= p.Y + s.Y + 6 then
                setFromX(m.X)
            end
        end
    end)
    return f
end

function Im.combo(parent, label, tbl, key, opts)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 24) b.BackgroundColor3 = Im.ROW
    b.BorderSizePixel = 1 b.BorderColor3 = Color3.fromRGB(45,45,55)
    b.TextColor3 = Im.TXT b.Font = Enum.Font.Code b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left b.AutoButtonColor = false b.Parent = parent
    local function rf() b.Text = " " .. label .. ": < " .. tostring(tbl[key]) .. " >" end
    rf()
    b.MouseButton1Click:Connect(function()
        local i = 1
        for k, v in ipairs(opts) do if v == tbl[key] then i = k break end end
        tbl[key] = opts[(i % #opts) + 1]
        rf()
    end)
    return b
end

function Im.group(parent, title)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18) l.BackgroundTransparency = 1
    l.Text = "-- " .. string.upper(title) .. " --"
    l.TextColor3 = Im.ACC l.Font = Enum.Font.Code l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = parent
end

function Im.button(parent, label, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 26) b.BackgroundColor3 = Im.ACC
    b.Text = label b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Code b.TextSize = 12 b.AutoButtonColor = false b.Parent = parent
    b.MouseButton1Click:Connect(function() pcall(fn) end)
    return b
end

function Im.textbox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 24) box.BackgroundColor3 = Im.ROW
    box.BorderSizePixel = 1 box.BorderColor3 = Color3.fromRGB(45,45,55)
    box.TextColor3 = Im.TXT box.Font = Enum.Font.Code box.TextSize = 12
    box.PlaceholderText = placeholder or "" box.Text = ""
    box.TextXAlignment = Enum.TextXAlignment.Left box.Parent = parent
    return box
end

function Im.status(parent, h)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, h or 40) l.BackgroundColor3 = Im.ROW
    l.BorderSizePixel = 1 l.BorderColor3 = Color3.fromRGB(45,45,55)
    l.TextColor3 = Im.DIM l.Font = Enum.Font.Code l.TextSize = 11
    l.TextWrapped = true l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top l.Parent = parent
    return l
end

return Im
