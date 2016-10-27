local wibox = require("wibox")
--local timer = require("gears").timer
local timer = timer

vpnwidget = wibox.widget.textbox()
vpnwidget:set_text("VPN: N/A")

local check = function()
    if os.execute('test ! -z "`ip tuntap show | grep -v ^vir`"') then
        vpnwidget:set_markup(" <span color='#00FF00'>VPN: ON</span> ")
    else
        vpnwidget:set_markup(" <span color='#FF0000'>VPN: OFF</span> ")
    end
end

check()
local vpnwidgettimer = timer({ timeout = 5 })
vpnwidgettimer:connect_signal("timeout", check)
vpnwidgettimer:start()

