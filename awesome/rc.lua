local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local lain = require("lain")

-- Just to remove the warning about missing xrdb config
beautiful.xresources.get_current_theme = function()
    --@formatter:off
    return {
        color0 = '#000000', color8 = '#465457',  --black
        color1 = '#cb1578', color9 = '#dc5e86',  --red
        color2 = '#8ecb15', color10 = '#9edc60', --green
        color3 = '#cb9a15', color11 = '#dcb65e', --yellow
        color4 = '#6f15cb', color12 = '#7e5edc', --blue
        color5 = '#cb15c9', color13 = '#b75edc', --purple
        color6 = '#15b4cb', color14 = '#5edcb4', --cyan
        color7 = '#888a85', color15 = '#ffffff', --white
        background  = '#0e0021', foreground  = '#bcbcbc',
    }
    --@formatter:on
end

local hotkeys_popup = require("awful.hotkeys_popup").widget

-- When loaded, this module makes sure that there's always a client that will
-- have focus on events such as tag switching, client unmanaging, etc.
require("awful.autofocus")

package.path = package.path .. ';' .. awful.util.get_configuration_dir() ..
        '?.lua;' .. awful.util.get_configuration_dir() .. '?/init.lua'

local APW = require("apw4/widget")
local vicious = require("vicious")
local calendar_popup = require("awful.widget.calendar_popup")
local battery = require('battery')
local vpn = require('vpnwidget')

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(awful.util.get_configuration_dir() .. "themes/p-himik/theme.lua")
local apw = APW() -- must be after theme initialization

-- This is used later as the default terminal and editor to run.
local terminal = "terminator"
local editor = os.getenv("EDITOR") or "vim"
local editor_cmd = terminal .. " -x " .. editor

local lock_cmd = "physlock -dms"
local logout_cmd = "pkill -u " .. os.getenv("USER")
local suspend_cmd = 'dbus-send --system --print-reply --dest="org.freedesktop.login1" /org/freedesktop/login1 org.freedesktop.login1.Manager.Suspend boolean:true'
local hibernate_cmd = 'sudo pm-hibernate'
local screenshot_screen = 'shutter -f'
local screenshot_window = 'shutter -w'
local screenshot_selection = 'shutter -s'
local switch_dp_monitor_cmd = "switch_monitor.sh DP1"

local autostarts = {
    shell = {
        "kbdd",
    },
    noshell = {}
}

local function spawn_array(a)
    for i, e in ipairs(a.noshell) do
        awful.spawn(e)
    end
    for i, e in ipairs(a.shell) do
        awful.spawn.with_shell(e)
    end
end

spawn_array(autostarts)

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts = awful.layout.suit
awful.layout.layouts = {
    layouts.floating,
    lain.layout.centerwork,
    layouts.tile,
    layouts.tile.left,
    layouts.tile.bottom,
    layouts.tile.top,
    layouts.fair,
    layouts.fair.horizontal,
    -- layouts.spiral,
    -- layouts.spiral.dwindle,
    layouts.max,
    layouts.max.fullscreen,
    -- layouts.magnifier,
    -- layouts.corner.nw,
    -- layouts.corner.ne,
    -- layouts.corner.sw,
    -- layouts.corner.se,
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
local tags = { names = {}, layouts = {} }
local layout_by_tag = {
    { name = "cmd", layout = layouts.fair },
    { name = "www", layout = lain.layout.centerwork },
    { name = "dev", layout = layouts.tile },
    { name = "soc", layout = layouts.fair },
    { name = "db", layout = layouts.tile.left },
    { name = "txt", layout = layouts.tile.left },
    { name = "vnc", layout = layouts.tile.left },
    { name = "8", layout = layouts.tile.left },
    { name = "mail", layout = layouts.tile.left },
}
for _, nl in ipairs(layout_by_tag) do
    table.insert(tags.names, nl.name)
    table.insert(tags.layouts, nl.layout)
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
local myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end }
}

local mymainmenu = awful.menu({
    items = {
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "open terminal", terminal }
    }
})

local mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mymainmenu
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

local calendar_args = {
    position = 'tr',
    spacing = 3,
    week_numbers = true,
    long_weekdays = true
}
for _, cell in ipairs({ 'normal', 'weeknumber', 'weekday', 'header', 'month', 'focus' }) do
    calendar_args['style_' .. cell] = { border_width = 0 }
end
local calendarwidget = wibox.widget.textclock()
local cal_box = calendar_popup.month(calendar_args)
cal_box:attach(calendarwidget, 'tr')

local cpuwidget = wibox.widget.graph()
vicious.register(cpuwidget, vicious.widgets.cpu, "$1", 0.5)

local memwidget = wibox.widget.progressbar()
vicious.register(memwidget, vicious.widgets.mem, "$1", 2)

local batwidget = battery()
-- vicious battery widget doesn't work and requires manual configuration

local vpnwidget = vpn()

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance

    return function()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end

-- }}}

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end))

local tasklist_buttons = awful.util.table.join(awful.button({}, 1, function(c)
    if c == client.focus then
        c.minimized = true
    else
        -- Without this, the following
        -- :isvisible() makes no sense
        c.minimized = false
        if not c:isvisible() and c.first_tag then
            c.first_tag:view_only()
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
    end
end),
    awful.button({}, 3, client_menu_toggle_fn()),
    awful.button({}, 4, function()
        awful.client.focus.byidx(1)
    end),
    awful.button({}, 5, function()
        awful.client.focus.byidx(-1)
    end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local kbd_dbus_next_cmd = "dbus-send --dest=ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.next_layout"
local kbd_img_path = "/usr/local/share/icons/flags/"
local kbd_images = {
    [0] = kbd_img_path .. "us.png",
    [1] = kbd_img_path .. "ru.png"
}
dbus.request_name("session", "ru.gentoo.kbdd")
dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")

-- {{{ Wibar
awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag(tags.names, s, tags.layouts)

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    --noinspection ArrayElementZero
    local kbdwidget = wibox.widget.imagebox(kbd_images[0], true)
    dbus.connect_signal("ru.gentoo.kbdd", function(...)
        local data = { ... }
        local layout = data[2]
        kbdwidget:set_image(kbd_images[layout])
    end)

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        {
            -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            spacing = 5,
            {
                widget = cpuwidget,
                color = {
                    type = "linear",
                    from = { 0, 0 },
                    to = { 0, 40 },
                    stops = { { 0, "#FF5656" }, { 0.5, "#88A175" }, { 1, "#AECF96" } }
                },
                background_color = "#494B4F",
                forced_width = 50
            },
            wibox.widget {
                {
                    widget = memwidget,
                    color = {
                        type = "linear",
                        from = { 0, 0 },
                        to = { 20, 0 },
                        stops = { { 0, "#AECF96" }, { 0.5, "#88A175" }, { 1, "#FF5656" } }
                    },
                    background_color = "#494B4F"
                },
                border_color = nil,
                forced_width = 8,
                direction = 'east',
                layout = wibox.container.rotate
            },
            wibox.widget {
                forced_width = 40,
                widget = apw.progressbar
            },
            batwidget,
            vpnwidget,
            kbdwidget,
            wibox.widget.systray(),
            calendarwidget,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(awful.button({}, 3, function() mymainmenu:toggle() end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)))
-- }}}

-- {{{ Key bindings
--@formatter:off
local globalkeys = awful.util.table.join(
    awful.key({}, "#126", function() awful.util.spawn_with_shell(switch_dp_monitor_cmd) end,
        { description = "Switch monitor (plus-minus sign, Fn+F5)", group = "awesome" }),

    awful.key({}, "XF86AudioRaiseVolume", apw.up),
    awful.key({}, "XF86AudioLowerVolume", apw.down),
    awful.key({}, "XF86AudioMute", apw.togglemute),
    awful.key({ modkey }, "Left", apw.down),
    awful.key({ modkey }, "Right", apw.up),

    awful.key({ modkey, }, "s", hotkeys_popup.show_help,
        { description = "show help", group = "awesome" }),
    --awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
    --          {description = "view previous", group = "tag"}),
    --awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
    --          {description = "view next", group = "tag"}),
    awful.key({ modkey, }, "Escape", awful.tag.history.restore,
        { description = "go back", group = "tag" }),

    awful.key({}, "#107", function() -- PrtSc
        awful.util.spawn(screenshot_screen)
    end),

    awful.key({ "Shift" }, "#107", function() -- PrtSc
        awful.util.spawn(screenshot_window)
    end),

    awful.key({ "Control", "Shift" }, "#107", function() -- PrtSc
        awful.util.spawn(screenshot_selection)
    end),

    awful.key({ modkey, "Control" }, "#46", function()
        awful.util.spawn(lock_cmd)
    end),

    awful.key({ modkey, "Control", "Shift" }, "#46", function() -- l
        awful.util.spawn(logout_cmd)
    end),

    awful.key({ modkey, "Control" }, "#39", function() -- s
        awful.util.spawn_with_shell(suspend_cmd)
    end),

    awful.key({ modkey, "Control" }, "#43", function() -- h
        awful.util.spawn(hibernate_cmd)
    end),

    awful.key({ modkey, }, "j",
        function()
            awful.client.focus.byidx(1)
        end,
        { description = "focus next by index", group = "client" }),
    awful.key({ modkey, }, "k",
        function()
            awful.client.focus.byidx(-1)
        end,
        { description = "focus previous by index", group = "client" }),
    awful.key({ modkey, }, "w", function() mymainmenu:show() end,
        { description = "show main menu", group = "awesome" }),

    -- Layout manipulation
    awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.byidx(1) end,
        { description = "swap with next client by index", group = "client" }),
    awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.byidx(-1) end,
        { description = "swap with previous client by index", group = "client" }),
    awful.key({ modkey, "Control" }, "j", function() awful.screen.focus_relative(1) end,
        { description = "focus the next screen", group = "screen" }),
    awful.key({ modkey, "Control" }, "k", function() awful.screen.focus_relative(-1) end,
        { description = "focus the previous screen", group = "screen" }),
    awful.key({ modkey, }, "u", awful.client.urgent.jumpto,
        { description = "jump to urgent client", group = "client" }),
    awful.key({ modkey, }, "Tab",
        function()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        { description = "go back", group = "client" }),

    -- Standard program
    awful.key({ modkey, }, "Return", function() awful.spawn(terminal) end,
        { description = "open a terminal", group = "launcher" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
        { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "q", awesome.quit,
        { description = "quit awesome", group = "awesome" }),

    awful.key({ modkey, }, "l", function() awful.tag.incmwfact(0.05) end,
        { description = "increase master width factor", group = "layout" }),
    awful.key({ modkey, }, "h", function() awful.tag.incmwfact(-0.05) end,
        { description = "decrease master width factor", group = "layout" }),
    awful.key({ modkey, "Shift" }, "h", function() awful.tag.incnmaster(1, nil, true) end,
        { description = "increase the number of master clients", group = "layout" }),
    awful.key({ modkey, "Shift" }, "l", function() awful.tag.incnmaster(-1, nil, true) end,
        { description = "decrease the number of master clients", group = "layout" }),
    awful.key({ modkey, "Control" }, "h", function() awful.tag.incncol(1, nil, true) end,
        { description = "increase the number of columns", group = "layout" }),
    awful.key({ modkey, "Control" }, "l", function() awful.tag.incncol(-1, nil, true) end,
        { description = "decrease the number of columns", group = "layout" }),
    awful.key({ modkey, }, "space", function() awful.layout.inc(1) end,
        { description = "select next", group = "layout" }),
    awful.key({ modkey, "Shift" }, "space", function() awful.layout.inc(-1) end,
        { description = "select previous", group = "layout" }),

    awful.key({ modkey, "Control" }, "n",
        function()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                client.focus = c
                c:raise()
            end
        end,
        { description = "restore minimized", group = "client" }),

    -- Prompt
    awful.key({ modkey }, "r", function() awful.screen.focused().mypromptbox:run() end,
        { description = "run prompt", group = "launcher" }),

    awful.key({ modkey }, "x",
        function()
            awful.prompt.run {
                prompt = "Run Lua code: ",
                textbox = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval"
            }
        end,
        { description = "lua execute prompt", group = "awesome" }),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
        { description = "show the menubar", group = "launcher" })
)
--@formatter:on

local function show_client_under_mouse_properties(c)
    local f = io.popen('xdotool getmouselocation --shell | grep WINDOW |cut -d= -f2')
    local id = f:read("*n")
    f:close()
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "ID",
        text = id
    })
    f = io.popen('xprop -id ' .. id .. ' | grep -v "^\t[^\t]"')
    local r = {}
    for l in f:lines() do
        table.insert(r, l)
    end
    f:close()
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "CLIENT INFO",
        text = table.concat(r, '\n')
    })
end

local clientkeys = awful.util.table.join(awful.key({ modkey, }, "f",
    function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end,
    { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey, "Shift" }, "c", function(c) c:kill() end,
        { description = "close", group = "client" }),
    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle,
        { description = "toggle floating", group = "client" }),
    awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end,
        { description = "move to master", group = "client" }),
    awful.key({ modkey, }, "o", function(c) c:move_to_screen() end,
        { description = "move to screen", group = "client" }),
    awful.key({ modkey, }, "t", function(c) c.ontop = not c.ontop end,
        { description = "toggle keep on top", group = "client" }),
    awful.key({ modkey, }, "n",
        function(c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end,
        { description = "minimize", group = "client" }),
    awful.key({ modkey, }, "m",
        function(c)
            c.maximized = not c.maximized

            -- workaround for #1692
            if client.focus then
                client.focus.ignore_border_width = false
                client.focus.border_width = beautiful.border_width
            end

            c:raise()
        end,
        { description = "maximize", group = "client" }))

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            { description = "view tag #" .. i, group = "tag" }),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            { description = "toggle tag #" .. i, group = "tag" }),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            { description = "move focused client to tag #" .. i, group = "tag" }),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            { description = "toggle focused client on tag #" .. i, group = "tag" }))
end

local clientbuttons = awful.util.table.join(awful.button({}, 1, function(c)
    if c.focusable then
        client.focus = c
        c:raise()
    end
end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
--awful.ewmh.add_activate_filter(function(c)
--    return false
--end)
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
            size_hints_honor = false
        }
    },

    -- Floating clients.
    {
        rule_any = {
            instance = {
                "DTA", -- Firefox addon DownThemAll.
                "copyq", -- Includes session name in class.
            },
            class = {
                "Arandr",
                "Gpick",
                "Kruler",
                "MessageWin", -- kalarm.
                "Sxiv",
                "Wpa_gui",
                "pinentry",
                "veromix",
                "xtightvncviewer"
            },
            name = {
                "Event Tester", -- xev.
            },
            role = {
                "AlarmWindow", -- Thunderbird's calendar.
                "gimp-toolbox",
                "gimp-dock",
                --"pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true }
    },

    -- On top clients
    {
        rule_any = {
            role = {
                "gimp-toolbox",
                "gimp-dock",
            }
        },
        properties = { ontop = true }
    },

    {
        rule = {
            class = "^jetbrains-",
            name = "^ $" -- find class or file dialog
        },
        properties = {
            prevent_auto_unfocus = true,
            placement = awful.placement.centered
        },
    },

    {
        rule = {
            class = "^Insync",
            name = "^-$" -- tray pop-up
        },
        properties = {
            prevent_auto_unfocus = true,
            floating = true,
            maximized = false,
            placement = awful.placement.top_right
        },
    }
}

local tag_rules = {
    ["www"] = { "Google-chrome", "Firefox" },
    ["dev"] = { "^jetbrains-" },
    ["soc"] = { "Skype", "Telegram", "Slack" },
    ["db"] = { "com-install4j-runtime-launcher-Launcher" },
    ["txt"] = { "Sublime_text" },
    ["vnc"] = { "VirtualBox" },
    ["mail"] = { "Thunderbird" }
}

for tag_name, tag_rules in pairs(tag_rules) do
    for _, c in pairs(tag_rules) do
        table.insert(awful.rules.rules, {
            rule = { class = c, type = "normal" },
            properties = { screen = 1, tag = tag_name }
        })
    end
end
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)


local focus_follows_mouse = true

-- Enable sloppy focus, so that focus follows mouse.
local function refocus_client(c)
    if focus_follows_mouse
            and awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
        client.focus = c
    end
end

client.connect_signal("mouse::enter", refocus_client)


-- Prevent mouse from leaving a marked client
local function check_prevent_auto_unfocus(c)
    focus_follows_mouse = not c.prevent_auto_unfocus
end

client.connect_signal("focus", check_prevent_auto_unfocus)
client.connect_signal("unfocus", check_prevent_auto_unfocus)

-- It's needed to focus a client that is under mouse right after we change a tag's layout
local function delay_refocus_client_under_mouse()
    local t = gears.timer { timeout = 0.01 }
    t:connect_signal("timeout", function()
        t:stop()
        local c = mouse.current_client
        if c then
            refocus_client(c)
        end
    end)
    t:start()
end

screen.connect_signal("tag::history::update", delay_refocus_client_under_mouse)


client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- this adds the default 3.5 behavior when adding/removing a screen
-- see https://github.com/awesomeWM/awesome/issues/1382
screen.connect_signal("removed", awesome.restart)
screen.connect_signal("added", awesome.restart)

-- }}}
