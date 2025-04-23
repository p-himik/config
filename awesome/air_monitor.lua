local awful = require('awful')
local gstring = require('gears.string')
local gtable = require('gears.table')
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

function zip(keys, vals)
    local result = {}
    for i, k in ipairs(keys) do
        result[k] = vals[i]
    end
    return result
end

function date_time_to_unix_ts(date, time)
    -- Unfortunately, AirVisual puts the timezone offset directly into the unix timestamp values,
    -- so we cannot use them directly. But at least it reports the right date and time if they're
    -- set to the right values in its UI.
    local year, month, day = table.unpack(gtable.map(tonumber, gstring.split(date, '/')))
    local hour, min, sec = table.unpack(gtable.map(tonumber, gstring.split(time, ':')))
    return os.time({year=year, month=month, day=day, hour=hour, min=min, sec=sec})
end

function parse_result(result)
    local json_line, csv_header, csv_values = table.unpack(gstring.split(result))
    -- Example:
    -- 2023/09/23;14:19:22;638;55;25.4
    local json_data = json_line ~= '' and zip({'date', 'time', 'co2', 'humidity', 'temp'}, gstring.split(json_line, ';')) or nil
    -- Example:
    -- Date;Time;Timestamp;PM2_5(ug/m3);AQI(US);AQI(CN);PM10(ug/m3);PM1(ug/m3);Outdoor AQI(US);Outdoor AQI(CN);Temperature(C);Temperature(F);Humidity(%RH);CO2(ppm)
    -- 2023/09/23;14:04:21;1695477861;1.0;4;1;1.0;1.0;0;0;25.4;77.7;54;652;
    local csv_data = csv_header ~= '' and zip(gstring.split(csv_header, ';'), gstring.split(csv_values, ';')) or nil

    -- No clue how there can be no date in the CSV data, but it happened once
    -- after the network got down and then back up.
    if not json_data and (not csv_data or not csv_data['Date']) then
        return nil
    end

    local csv_ts = csv_data and date_time_to_unix_ts(csv_data['Date'], csv_data['Time']) or 0
    local json_ts = json_data and date_time_to_unix_ts(json_data.date, json_data.time) or 0

    local data
    if csv_ts > json_ts then
        data = {date = csv_data['Date'],
                time = csv_data['Time'],
                timestamp = csv_ts,
                co2 = csv_data['CO2(ppm)'],
                humidity = csv_data['Humidity(%RH)'],
                temp = csv_data['Temperature(C)']}
    else
        data = json_data
        data.timestamp = json_ts
    end
    data.co2 = tonumber(data.co2)
    data.humidity = tonumber(data.humidity)
    data.temp = tonumber(data.temp)
    return data
end

function color_span(text, fg, bg)
    return '<span background="' .. bg .. '" foreground="' .. fg .. '">' .. text .. '</span>'
end

function warn(text)
    local p = cst.config.presets.warn
    return color_span(text, p.fg, p.bg)
end

function err(text)
    local p = cst.config.presets.critical
    return color_span(text, p.fg, p.bg)
end

function err_if_bad(text, bad)
    return bad and err(text) or text
end

function mk_get_file_via_samba_cmd(config, path, exptected_lines_n, postprocessing)
    local smb_cmd = 'prompt; get "' .. path .. '" -'
    local cmd = ('smbclient \\\\\\\\' .. config.ip .. '\\\\airvisual ' .. config.password .. ' -p ' .. config.port
                 .. ' -U ' .. config.username
                 .. ' -c \'' .. smb_cmd .. '\'')
    if postprocessing then
        cmd = cmd .. ' | ' .. postprocessing
    end
    return '(' .. cmd .. ') || echo -n "' .. string.rep('\\n', exptected_lines_n) .. '"'
end

function air_monitor.new(config)
    config.port = config.port or 445
    config.co2_max = config.co2_max or 800
    config.humidity_min = humidity_min or 40
    config.humidity_max = humidity_max or 60
    -- Extract the required fields from the first record (for some reason, the first is the most recent one), print all the data in a single line separated with semicolons.
    local json_postprocessing = 'jq \'.date_and_time["date","time"],.measurements[0]["co2_ppm","humidity_RH","temperature_C"]\' | tr -d \'"\' | paste -sd ";" -'
    local json_cmd = mk_get_file_via_samba_cmd(config, 'latest_config_measurements.json', 1, json_postprocessing)
    -- Remove potential empty line at the end, return only the first line (header) and the last line (the most recent data).
    local csv_postprocessing = 'grep -v "^$" | sed \'1p;$!d\''
    local csv_cmd = mk_get_file_via_samba_cmd(config, os.date("%Y%m_AirVisual_values.txt"), 2, csv_postprocessing)
    local cmd = json_cmd .. ';' .. csv_cmd

    local tooltip
    local widget = awful.widget.watch({ awful.util.shell, '-c', cmd }, 60, function(widget, stdout, _stderr, _exitreason, exitcode)
        if stdout == nil or exitcode ~= 0 then
            notify_error('Unable to query air monitor')
        else
            hide_error()
            local data = parse_result(stdout)
            local pieces = {}
            if not data then
                table.insert(pieces, err('No AirVisual data'))
            else
                if data.co2 then
                    local co2_bad = handle_co2_value(data.co2, config)
                    table.insert(pieces, 'CO2: ' .. err_if_bad(data.co2, co2_bad) .. ' ppm')
                end
                if data.humidity then
                    local humidity_bad = handle_humidity_value(data.humidity, config)
                    table.insert(pieces, 'RH: ' .. err_if_bad(data.humidity, humidity_bad) .. '%')
                end
                if data.temp then
                    table.insert(pieces, data.temp .. ' °C')
                end
            end
            local mkup = ''
            if #pieces > 0 then
                mkup = table.concat(pieces, ' | ')
                if data and os.time() - data.timestamp > 30 * 60 then
                    mkup = warn(mkup)
                end
            end
            widget:set_markup(mkup)
            if data and data.date and data.time then
                tooltip.text = 'Measurement taken at: ' .. data.date .. ' ' .. data.time
            else
                tooltip.text = ''
            end
        end
    end)
    tooltip = awful.tooltip {
        objects = {widget},
        text = ''
    }
    return widget
end

function air_monitor.mt.__call(_, ...)
    return air_monitor.new(...)
end

return setmetatable(air_monitor, air_monitor.mt)
