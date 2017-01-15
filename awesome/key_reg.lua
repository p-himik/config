local keysyms = {}
local keycodes = {}
local xmodmap_cmd = "xmodmap -pke | awk '$4 != \"\" && $4 != \"NoSymbol\" {print $2, $4}'"
local xmodmap = io.popen(xmodmap_cmd)
for keycode, keysym in string.gmatch(xmodmap:read('*all'), '(%d+) (.+)') do
    keycode = '#' .. keycode
    keysyms[keycode] = keysym
    local cs = keycodes[keysym]
    if cs then
        table.insert(cs, keycode)
    else
        keycodes[keysym] = { keycode }
    end
end
xmodmap:close()

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function reg_keys(keys, action, description, group, data)
    if type(keys[1]) ~= "table" then
        keys = { keys }
    end

    data = data or {}
    data.description = description
    data.group = group

    local rets = {}
    for _, mk in pairs(keys) do
        local k = mk[#mk]
        table.remove(mk, #mk)

        local cs = keycodes[k]
        if cs then
            for _, c in pairs(cs) do
                local mk_copy = deepcopy(mk)
                local data_copy = deepcopy(data)
                print('registering ' .. table.concat(mk_copy, '/') .. ' ' .. c)
                table.insert(rets, awful.key(mk_copy, c, action, data_copy))
            end
        else
            local data_copy = deepcopy(data)
            print('registering ' .. table.concat(mk, '/') .. ' ' .. k)
            table.insert(rets, awful.key(mk, k, action, data_copy))
        end
    end
    return awful.util.table.join(unpack(rets))
end


