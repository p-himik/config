local grid = require("grid")
local textbox = require('wibox.widget.textbox')
local background = require('wibox.container.background')
local awful = require("awful")
local util = awful.util
local ipairs = ipairs
local tonumber = tonumber
local os_date = os.date
local os_time = os.time
local io_popen = io.popen
local t_insert = table.insert

local calendar = { mt = {} }

local days_names = { 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' }
local prev_label = util.escape("<<")
local next_label = util.escape(">>")

local function current_month_year()
    return {
        month = tonumber(os_date("%m")),
        year = tonumber(os_date("%Y"))
    }
end

local function add_month(my, delta)
    my.month = my.month + delta
    if my.month < 1 then
        my.month = 12
        my.year = my.year - 1
    elseif my.month > 12 then
        my.month = 1
        my.year = my.year + 1
    end
    return my
end

local function first_day_op(year, month, fmt)
    return os_date(fmt, os_time { year = year, month = month, day = 01 })
end

local function last_day_op(year, month, fmt)
    local f = assert(io_popen('date -d "' .. year .. '-' .. month .. '-01 + 1 month - 1 day" "+' .. fmt .. '"', 'r'))
    local res = assert(f:read('*a'))
    f:close()
    return res
end

local function is_current_month(d)
    local cmy = current_month_year()
    return d.year == cmy.year and d.month == cmy.month
end

local function get_week_numbers(year, month)
    local first_week = tonumber(first_day_op(year, month, "%V"))
    local last_week = tonumber(last_day_op(year, month, "%V"))
    local res = {}
    if first_week < last_week then
        for i = first_week, last_week do
            t_insert(res, i)
        end
    else
        local mw = tonumber(last_day_op(year - 1, 12, "%V"))
        for i = first_week, mw do
            t_insert(res, i)
        end
        for i = 1, last_week do
            t_insert(res, i)
        end
    end
    return res
end

local function reset(d, my)
    local month = my.month
    local year = my.year
    d.year = year
    d.month = month

    --find the first week day of the month
    --it is the number used as start for displaying day in the
    --table days_of_month
    local day_1 = tonumber(first_day_op(year, month, "%u"))
    local day_n = tonumber(last_day_op(year, month, "%d"))

    local days = d.days_of_month

    for i = 1, 42 do
        local bg = days[i]
        local w = bg.widget
        if i < day_1 or i >= (day_n + day_1) then
            w:set_text("")
        else
            local day_number = i - day_1 + 1
            w:set_text(i - day_1 + 1)
            local current_day = tonumber(os_date("%d"))
            if is_current_month(d) and current_day == day_number then
                bg:set_bg("#494B4F")
            else
                bg:set_bg()
            end
        end
    end

    local week_numbers = get_week_numbers(year, month)
    for i, wn in ipairs(week_numbers) do
        d.weeks_numbers[i]:set_text(wn)
    end
    for i = #week_numbers + 1, 6 do
        d.weeks_numbers[i]:set_text("")
    end

    local month_name = os_date("%B", os_time { year = year, month = month, day = 01 })
    d.date:set_text(month_name .. " " .. year)
end

local function tb(text)
    local t = textbox(text)
    t:set_valign('center')
    t:set_align('center')
    return t
end

function calendar.new()
    local res = grid()
    local d = {}

    d.date = tb()
    res:add_child(d.date, 3, 1, 4, 1)
    d.date:buttons(awful.button({}, 1, function()
        reset(d, current_month_year())
    end))

    d.prev_month = tb(prev_label)
    res:add_child(d.prev_month, 1, 1, 1, 1)
    d.prev_month:buttons(awful.button({}, 1, function()
        reset(d, add_month(d, -1))
    end))

    d.next_month = tb(next_label)
    res:add_child(d.next_month, 8, 1, 1, 1)
    d.next_month:buttons(awful.button({}, 1, function()
        reset(d, add_month(d, 1))
    end))

    d.week_days = {}
    for i, n in ipairs(days_names) do
        local c = tb(n)
        d.week_days[i] = c
        res:add_child(c, i + 1, 2, 1, 1)
    end

    d.weeks_numbers = {}
    for i = 1, 6 do
        local c = tb()
        d.weeks_numbers[i] = c
        res:add_child(c, 1, 2 + i, 1, 1)
    end

    d.days_of_month = {}
    for y = 1, 6 do
        for x = 1, 7 do
            local index = x + ((y - 1) * 7)
            local c = background(tb())
            d.days_of_month[index] = c
            res:add_child(c, 1 + x, 2 + y, 1, 1)
        end
    end

    reset(d, current_month_year())

    return res
end

function calendar.mt:__call(...)
    return calendar.new(...)
end

return setmetatable(calendar, calendar.mt)
