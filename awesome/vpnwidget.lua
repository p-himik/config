local wibox = require("wibox")
--local timer = require("gears").timer
local timer = timer

vpnwidget = wibox.widget.textbox()
vpnwidget:set_text("VPN: N/A")
local openvpn_conf = io.open("/etc/openvpn/client.conf", "r")
local dev = nil
if openvpn_conf then
    for line in openvpn_conf:lines() do
        local d = line:match('dev%s+(%a+)')
        if d then
            dev = d
            break
        end
    end
    openvpn_conf:close()
end

if dev then
    local vpnwidgettimer = timer({ timeout = 5 })
    vpnwidgettimer:connect_signal("timeout",
        function()
            if os.execute("test ! -z `find /sys/class/net -maxdepth 1 -name " .. dev .. "*`") then
                vpnwidget:set_markup(" <span color='#00FF00'>VPN: ON</span> ")
            else
                vpnwidget:set_markup(" <span color='#FF0000'>VPN: OFF</span> ")
            end
        end
    )
    vpnwidgettimer:start()
end

