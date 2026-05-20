-- Carbonite | Util / Tables
-- Table helpers shared by every module. Old Nx code had open-coded
-- copies of these scattered across NxUI / NxMap / NxOptions.

local Carbonite = _G.Carbonite
local Tables = {}
Carbonite.Util.Tables = Tables

function Tables.Count(t)
    if not t then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function Tables.IsEmpty(t)
    if not t then return true end
    return next(t) == nil
end

function Tables.ShallowCopy(src)
    if not src then return nil end
    local out = {}
    for k, v in pairs(src) do out[k] = v end
    return out
end

function Tables.DeepCopy(src, seen)
    if type(src) ~= "table" then return src end
    seen = seen or {}
    if seen[src] then return seen[src] end
    local out = {}
    seen[src] = out
    for k, v in pairs(src) do
        out[Tables.DeepCopy(k, seen)] = Tables.DeepCopy(v, seen)
    end
    return out
end

-- Deep merge of `src` into `dst`. Tables get recursed; scalars are
-- overwritten by `src`. Used for option merges where the user's
-- existing settings should win.
function Tables.Merge(dst, src)
    if type(src) ~= "table" then return dst end
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            Tables.Merge(dst[k], v)
        else
            dst[k] = v
        end
    end
    return dst
end

-- Concatenates arrays into one. Optionally tags each item with its
-- source list index via a `_type` field; preserved from legacy
-- Nx.ArrayConcat which was used by the menu builder.
function Tables.Concat(arrays, tagSource)
    local out = {}
    for i, arr in ipairs(arrays) do
        for _, v in ipairs(arr or {}) do
            if tagSource and type(v) == "table" then v._type = i end
            out[#out + 1] = v
        end
    end
    return out
end

-- Returns sorted keys for stable iteration order.
function Tables.SortedKeys(t, cmp)
    local keys = {}
    for k in pairs(t or {}) do keys[#keys + 1] = k end
    table.sort(keys, cmp)
    return keys
end

function Tables.Filter(arr, pred)
    local out = {}
    for _, v in ipairs(arr or {}) do
        if pred(v) then out[#out + 1] = v end
    end
    return out
end

function Tables.Map(arr, fn)
    local out = {}
    for i, v in ipairs(arr or {}) do out[i] = fn(v, i) end
    return out
end
