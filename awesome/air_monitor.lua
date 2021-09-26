local awful = require('awful')
local gears = require('gears')
local gstring = require('gears.string')
local naughty = require('naughty')
local cst = require('naughty.constants')
local setmetatable = setmetatable

local air_monitor = { mt = {},
                      prev_co2_value = nil,
                      prev_humidity_value = nil,
                      error_notification = nil,
                      co2_notification = nil,
                      humidity_notification = nil}

function notify(kind, text)
    local title = 'Air Monitor'
    local field = kind .. '_notification'
    hide_notification(kind)
    air_monitor[field] = naughty.notify { title = 'Air Monitor',
                                          timeout = 0,
                                          urgency = 'critical',
                                          text = text }
end

function notify_error(text) notify('error', text) end

function notify_co2(max_value)
    notify('co2', 'CO2 concentration is above ' .. max_value .. ' ppm.')
end

function notify_low_humidity(min_value)
    notify('humidity', 'Humidity is below ' .. min_value .. '%.')
end

function notify_high_humidity(max_value)
    notify('humidity', 'Humidity is above ' .. max_value .. '%.')
end

function hide_notification(kind)
    local field = kind .. '_notification'
    if air_monitor[field] then
        air_monitor[field]:destroy(cst.notification_closed_reason.dismissed_by_command)
        air_monitor[field] = nil
    end
end

function hide_error() hide_notification('error') end
function hide_co2() hide_notification('co2') end
function hide_humidity() hide_notification('humidity') end

function split_in_two(s, p)
    local result = gstring.split(s, p)
    return result[1], result[2]
end

function handle_co2_value(value, config)
    local max = config.co2_max
    local prev = air_monitor.prev_co2_value
    air_monitor.prev_co2_value = value
    if value > max then
        if config.notify_co2 and (prev == nil or prev <= max) then
            notify_co2(max)
        end
        return true
    end
    hide_co2()
end

function handle_humidity_value(value, config)
    local min = config.humidity_min
    local max = config.humidity_max
    local prev = air_monitor.prev_humidity_value
    air_monitor.prev_humidity_value = value
    if value < min then
        if config.notify_humidity and (prev == nil or prev >= min) then
            notify_low_humidity(min)
        end
        return true
    elseif value > max then
        if config.notify_humidity and (prev == nil or prev <= max) then
            notify_high_humidity(max)
        end
        return true
    end
    hide_humidity()
end

function parse_line(l)
    local field, value = split_in_two(l, ' ')
    value = tonumber(value)
    if field == 'co2_ppm' then
        return 'co2', value
    elseif field == 'humidity_RH' then
        return 'humidity', value
    elseif field == 'temperature_C' then
        return 'temp', value
    end
end

function parse_result(result)
    result = result:gsub('[":,]', ''):gsub('  +', '')
    local data = {}
    for _, line in ipairs(gstring.split(result)) do
        if line ~= '' then
            field, value = parse_line(line)
            data[field] = value
        end
    end
    return data
end

function red_if_bad(text, bad)
    if bad then
        return '<span color="#FF0000">' .. text .. '</span>'
    else
        return text
    end
end

function air_monitor.new(config)
    local port = config.port or 445
    config.co2_max = config.co2_max or 800
    config.humidity_min = humidity_min or 40
    config.humidity_max = humidity_max or 60
    local smb_cmd = 'prompt; get latest_config_measurements.json -'
    local cmd = ('smbclient \\\\\\\\' .. config.ip .. '\\\\airvisual ' .. config.password .. ' -p ' .. port
                 .. ' -U ' .. config.username
                 .. ' -c "' .. smb_cmd .. '" | grep -e co2_ppm -e humidity_RH -e temperature_C')
    return awful.widget.watch({ awful.util.shell, '-c', cmd }, 60, function(widget, stdout)
        if stdout == nil then
            notify_error('Unable to query air monitor')
        else
            hide_error()
            local data = parse_result(stdout)
            local pieces = {}
            if data.co2 then
                local co2_bad = handle_co2_value(data.co2, config)
                table.insert(pieces, 'CO2: ' .. red_if_bad(data.co2, co2_bad) .. ' ppm')
            end
            if data.humidity then
                local humidity_bad = handle_humidity_value(data.humidity, config)
                table.insert(pieces, 'RH: ' .. red_if_bad(data.humidity, humidity_bad) .. '%')
            end
            if data.temp then
                table.insert(pieces, data.temp .. ' °C')
            end
            if #pieces == 0 then
                widget:set_text('')
            else
                widget:set_markup(table.concat(pieces, ' | '))
            end
        end
    end)
end

function air_monitor.mt.__call(_, ...)
    return air_monitor.new(...)
end

return setmetatable(air_monitor, air_monitor.mt)
