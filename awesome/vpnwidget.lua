local textbox = require("wibox.widget.textbox")
local timer = require("gears.timer")
local execute = os.execute

local vpnwidget = { mt = {} }

function vpnwidget.new(timeout)
    local widget = textbox("VPN: N/A")
    local t = timer { timeout = timeout or 5 }

    t:connect_signal("timeout", function()
        local _, _, exit_code = execute('test ! -z "`ip tuntap show 2>/dev/null | grep -v ^vir`"')
        if exit_code == 0 then
            widget:set_markup(" <span color='#00FF00'>VPN: ON</span> ")
        else
            widget:set_markup(" <span color='#FF0000'>VPN: OFF</span> ")
        end
    end)
    t:start()
    t:emit_signal("timeout")
    return widget
end

function vpnwidget.mt.__call(_, ...)
    return vpnwidget.new(...)
end

return setmetatable(vpnwidget, vpnwidget.mt)
