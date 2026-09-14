-- rivals.pro MIN ASCII | Xeno probe, english only
print("min start")
local LP = game:GetService("Players").LocalPlayer
local pg = LP:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "rivalspro_min"
gui.ResetOnSpawn = false
gui.Parent = pg
local f = Instance.new("TextButton")
f.Size = UDim2.new(0, 250, 0, 60)
f.Position = UDim2.new(0.5, -125, 0.5, -30)
f.Text = "rivals.pro ALIVE - press"
f.BackgroundColor3 = Color3.fromRGB(255, 0, 60)
f.TextColor3 = Color3.new(1, 1, 1)
f.Font = Enum.Font.GothamBold
f.TextSize = 16
f.Parent = gui
f.MouseButton1Click:Connect(function()
    f.Text = "WORKS"
end)
print("min ok")
