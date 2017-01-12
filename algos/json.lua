-- By Rahkiin

-- returns: isArray, size (if size is 0 can also be object)
local function isArray(table)
    local max = 0
    local count = 0

    for k, v in pairs(table) do
        if type(k) == "number" then
            if k > max then max = k end
            count = count + 1
        else
            return false, nil
        end
    end

    if max > count * 2 then
        return false, nil
    end

    return true, max
end


function jsonEncode(t, indent, cache)
    if indent == nil then indent = ""; end
    local newIndent = indent .. "  ";

    if cache == nil then cache = {}; end

    if (type(t) == "table") then
        -- Assume everything is an object (will change later, see if it is an arrya)

        for _, value in pairs(cache) do
            if value == t then
                return "[Cyclic]";
            end
        end
        table.insert(cache, 1, t);

        if isArray(t) then
            local str = "[";
            local first = true;

            for pos, val in pairs(t) do
                if not first then
                    str = str .. ",";
                end
                first = false;

                str = str .. "\n" .. newIndent .. jsonEncode(val, newIndent, cache);
            end

            return str .. "\n" .. indent .. "]";
        else
            local str = "{";
            local first = true;

            for pos, val in pairs(t) do
                if not first then
                    str = str .. ",";
                end
                first = false;

                str = str .. "\n" .. newIndent .. jsonEncode(pos, newIndent, cache) .. ": " .. jsonEncode(val, newIndent, cache);
            end

            return str .. "\n" .. indent .. "}";
        end
    elseif type(t) == "string" then
        return "\"" .. t .. "\"";
    elseif type(t) == "function" then
        return "Function(){}";
    else
        return tostring(t);
    end

    return nil;
end

local x = {
    ["hello"] = "world",
    ["goodbye"] = { "hello", "world", {"a", "n"} }
}

print(jsonEncode(x))
