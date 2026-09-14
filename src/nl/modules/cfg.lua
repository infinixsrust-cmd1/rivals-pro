-- rivals.pro NL | modules/cfg.lua (dedicated file: save/load settings)
-- executor file funcs: writefile/readfile/isfile/isfolder/makefolder

local Common = ...
assert(Common and Common.LP, "cfg: Common not injected")

local Cfg = {folder = "rivals-pro", cur = "default"}

local function enc(v)
    local t = typeof(v)
    if t == "boolean" or t == "number" then return tostring(v) end
    if t == "string" then return string.format("%q", v) end
    if t == "EnumItem" then return "ENUM:" .. tostring(v) end
    return nil
end

local function flat(C)
    local o = {}
    for sect, tbl in pairs(C) do
        if typeof(tbl) == "table" then
            for k, v in pairs(tbl) do
                local e = enc(v)
                if e then o[sect .. "." .. k] = e end
            end
        end
    end
    return o
end

local function serTable(o)
    local parts = {"{"}
    for k, v in pairs(o) do
        parts[#parts+1] = string.format("[%q]=%s,", k, v)
    end
    parts[#parts+1] = "}"
    return table.concat(parts)
end

local function deser(src)
    local fn, err = loadstring("return " .. src)
    if not fn then return nil, err end
    local ok, t = pcall(fn)
    if not ok or typeof(t) ~= "table" then return nil, "bad cfg" end
    return t
end

function Cfg.save(C, name)
    if not writefile then return false, "no writefile" end
    name = (name and #name > 0) and name or Cfg.cur
    Cfg.cur = name
    pcall(function() if not isfolder(Cfg.folder) then makefolder(Cfg.folder) end end)
    local ok, err = pcall(function()
        writefile(Cfg.folder .. "/" .. name .. ".lua", serTable(flat(C)))
    end)
    if not ok then return false, tostring(err) end
    return true
end

function Cfg.load(C, name)
    if not (readfile and isfile) then return false, "no readfile" end
    name = (name and #name > 0) and name or Cfg.cur
    local path = Cfg.folder .. "/" .. name .. ".lua"
    if not isfile(path) then return false, "not found: " .. name end
    local src = readfile(path)
    local t, err = deser(src)
    if not t then return false, tostring(err) end
    local n = 0
    for k, v in pairs(t) do
        local sect, key = k:match("^([^.]+)%.(.+)$")
        if sect and key and C[sect] ~= nil then
            if v == "true" then C[sect][key] = true n = n + 1
            elseif v == "false" then C[sect][key] = false n = n + 1
            elseif tonumber(v) then C[sect][key] = tonumber(v) n = n + 1
            elseif type(v) == "string" and v:sub(1, 5) ~= "ENUM:" then
                C[sect][key] = v n = n + 1
            end
        end
    end
    Cfg.cur = name
    return true, tostring(n) .. " values"
end

return Cfg
