local wibox = require("wibox")
local awful = require("awful")
 
volume_widget = wibox.widget.textbox()
volume_widget:set_align("right")
 
function update_volume(widget)
    local amix_out = awful.util.pread("amixer sget Master | tail -n 1 | awk '{print $4, $6}' | tr -d '[]\n'")
 
    -- local volume = tonumber(string.match(status, "(%d?%d?%d)%%")) / 100
    local volume, status = string.match(amix_out, "(%d?%d?%d%%)%s*(o..?)")
    if not volume then
        volume = '0%'
    end
    if not status then
        status = "on"
    end

    if status == 'off' then
        -- For the mute button
        volume = volume .. "M"
    end
    widget:set_markup(volume)
end
 
update_volume(volume_widget)
 
mytimer = timer({ timeout = 2 })
mytimer:connect_signal("timeout", function () update_volume(volume_widget) end)
mytimer:start()

