local awful = require('awful')
local setmetatable = setmetatable

local vpnwidget = { mt = {} }

function vpnwidget.new(timeout)
    local cmd = {awful.util.shell, '-c', 'ip tuntap show 2>/dev/null | grep -v ^vir' }
    return awful.widget.watch(cmd, timeout or 5, function(widget, result)
        if result ~= '' then
            widget:set_markup(" <span color='#00FF00'>VPN: ON</span> ")
        else
            widget:set_markup(" <span color='#FF0000'>VPN: OFF</span> ")
        end
    end)
end

function vpnwidget.mt.__call(_, ...)
    return vpnwidget.new(...)
end

return setmetatable(vpnwidget, vpnwidget.mt)
