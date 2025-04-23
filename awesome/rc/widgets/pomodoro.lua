-- A more advanced version if some other features are needed:
-- https://github.com/streetturtle/awesome-wm-widgets/blob/master/pomodoroarc-widget/
-- https://github.com/nikolavp/awesome-pomodoro
-- https://github.com/optama/awmodoro

local awful        = require("awful")
local naughty      = require("naughty")
local beautiful    = require("beautiful")
local wibox        = require("wibox")
local gears        = require("gears")

local pomodoro_time_minutes = 15

local running_icon = beautiful.pomodoro_running_icon
local stopped_icon = beautiful.pomodoro_stopped_icon

local pomodoro = wibox.widget({
    image = stopped_icon,
    widget = wibox.widget.imagebox,
    resize = true,
    visible = true
})

local pomodoro_timer         = gears.timer({ timeout = pomodoro_time_minutes * 60 })
local pomodoro_tooltip_timer = gears.timer({ timeout = 1 })
local pomodoro_nbsec         = 0

pomodoro_tooltip = awful.tooltip({
    timer_function = function()
                         if pomodoro_timer.started then
                             total_seconds_left = (pomodoro_time_minutes * 60 - pomodoro_nbsec)
                             minutes = math.floor(total_seconds_left / 60)
                             seconds = total_seconds_left % 60
                             return 'Ends in ' .. minutes .. ':' .. seconds
                         else
                             return ''
                         end
                     end,
})

local function pomodoro_start()
    pomodoro_timer:start()
    pomodoro_tooltip_timer:start()
    pomodoro.bg = beautiful.bg_normal
    pomodoro.image = running_icon
    pomodoro_tooltip:add_to_object(pomodoro)
end

local function pomodoro_stop()
    pomodoro_timer:stop(pomodoro_timer)
    pomodoro_tooltip_timer:stop(pomodoro_tooltip_timer)
    pomodoro.image = stopped_icon
    -- pomodoro.bg = beautiful.bg_urgent
    pomodoro_nbsec = 0
    pomodoro_tooltip:remove_from_object(pomodoro)
    pomodoro_tooltip:set_visible(false)
end

local function pomodoro_notify(text)
   naughty.notify({ title = "Pomodoro", text = text, timeout = 3,
                    icon = stopped_icon, icon_size = 64,
                    width = 300,
                    category = 'p-himik'
                 })
end

pomodoro_timer:connect_signal("timeout",
    function(c)
        pomodoro_stop()
        pomodoro_notify('Ended')
    end
)

pomodoro_tooltip_timer:connect_signal("timeout",
    function(c)
        pomodoro_nbsec = pomodoro_nbsec + 1
    end
)

local function pomodoro_start_timer()
    if not pomodoro_timer.started then
        pomodoro_start()
    else
        pomodoro_stop()
    end
end

pomodoro:buttons(awful.util.table.join(
                    awful.button({ }, 1, pomodoro_start_timer)
              ))

return pomodoro
