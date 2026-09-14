-- rivals.pro | loader.lua
-- ═══════════════════════════════════════════
--  ЕДИНСТВЕННОЕ ЧТО ВСТАВЛЯЕШЬ В EXECUTOR
--  открой RIVALS -> вставь -> Execute
-- ═══════════════════════════════════════════

-- ВАРИАНТ 1: загрузка с github
getgenv().RIVALSPRO_BASE = "https://raw.githubusercontent.com/infinixsrust-cmd1/rivals-pro/main/src"
loadstring(game:HttpGet(getgenv().RIVALSPRO_BASE .. "/main.lua"))()

-- ───────────────────────────────────────────
-- ВАРИАНТ 2: локальный запуск (если executor умеет readfile, напр. Delta/Wave/Solara PC):
--[[
local function readLocal(path)
    return readfile("rivals-pro/src/" .. path)
end
local function loadLocal(path)
    return loadstring(readLocal(path))()
end
getgenv().RIVALSPRO_LOCAL = true
loadstring(readLocal("main.lua"))()
--]]
