local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local gfs = require('gears.filesystem')
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local lain = require("lain")

local default_inspect = require('inspect')
function inspect(v)
    local process = function(item, path)
        if type(item) == 'key' then
            return {key = item.key, keysym = item.keysym, modifiers = item.modifiers}
        end
        return item
    end
    return default_inspect(v, {process=process})
end

local hotkeys_popup = require("awful.hotkeys_popup").widget

local APW = require("apw4/widget")
local vicious = require("vicious")
local calendar_popup = require("awful.widget.calendar_popup")
--local battery = require('battery')
local vpn = require('vpnwidget')

-- When loaded, this module makes sure that there's always a client that will
-- have focus on events such as tag switching, client unmanaging, etc.
require("awful.autofocus")

local awesome = awesome
local client = client
local dbus = dbus
local dofile = dofile
local screen = screen
local mouse = mouse
local tostring = tostring
local os = os
local ipairs = ipairs
local pairs = pairs
local table = table
local type = type
local next = next
local debug = debug
local math = math
local string = string

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

local function send_text_to_clipboard(text)
    io.popen('xclip -selection clipboard', 'w'):write(text):close()
end

local function not_empty_str(s)
    if s == nil or s == '' then
        return nil
    end
    return s
end

local default_timeout = 60
naughty.config.defaults.timeout = default_timeout

local rnotification = require("ruled.notification")
rnotification.connect_signal('request::rules', function()
    rnotification.append_rule {
        rule = { urgency = 'low',
                 app_name = 'Solaar'},
        properties = { ignore = true }
    }
    local copy_notif_text_action = naughty.action {
        name = 'Copy',
    }
    copy_notif_text_action:connect_signal('invoked', function (_action, notif)
        local title = not_empty_str(notif.title)
        local message = not_empty_str(notif.message)
        send_text_to_clipboard(title and message and (title .. '\n' .. message) or title or message)
    end)
    rnotification.append_rule {
        rule = {},
        properties = {
            append_actions = {
                copy_notif_text_action
            },
            callback = function (args)
                -- Timeout 0 means no timeout, which is used for critical notifications.
                if args.timeout > 0 and args.timeout < default_timeout then
                    args.timeout = default_timeout
                end
            end
        }
    }
end)

local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

local sensitive_config_path = script_path() .. '/sensitive_config.lua'
local sensitive_config = {}
if gfs.file_readable(sensitive_config_path) then
    sensitive_config = dofile(sensitive_config_path)
end

local air_monitor
if sensitive_config.air_monitor then
    local am = require('air_monitor')
    air_monitor = am(gears.table.join(sensitive_config.air_monitor, { notify_co2 = true }))
end

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(script_path() .. "/themes/p-himik/theme.lua")
local apw = APW({tooltip = false}) -- must be after theme initialization

-- This is used later as the default terminal and editor to run.
local terminal = "terminator"
local editor = os.getenv("EDITOR") or "vim"
local editor_cmd = terminal .. " -x " .. editor

local lock_cmd = "physlock -dms"
local logout_cmd = "pkill -u " .. os.getenv("USER")
local suspend_cmd = 'dbus-send --system --print-reply --dest="org.freedesktop.login1" /org/freedesktop/login1 org.freedesktop.login1.Manager.Suspend boolean:true'
local hibernate_cmd = 'sudo pm-hibernate'
local screenshot_screen = 'spectacle -f'
local screenshot_window = 'spectacle -a'
local screenshot_selection = 'spectacle -r'
local switch_dp_monitor_cmd = "switch_monitor.sh DP-1"
local jetbrains_toolbox_cmd = '/home/p-himik/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox'

local autostarts = {
    shell = {
        "restart_xbindkeys.sh",
        "restart_compton.sh"
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
    layouts.magnifier,
    layouts.max,
    layouts.max.fullscreen,
    -- layouts.corner.nw,
    -- layouts.corner.ne,
    -- layouts.corner.sw,
    -- layouts.corner.se,
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
local all_tags = { names = {}, layouts = {} }
local layout_by_tag = {
    { name = "cmd", layout = layouts.fair },
    { name = "www", layout = lain.layout.centerwork },
    { name = "dev", layout = layouts.tile },
    { name = "soc", layout = layouts.fair },
    { name = "db", layout = layouts.tile.left },
    { name = "@", layout = layouts.tile.left },
    { name = "vb", layout = layouts.tile.left },
    { name = "8", layout = layouts.tile.left },
    { name = "9", layout = layouts.max.fullscreen },
}
for _, nl in ipairs(layout_by_tag) do
    table.insert(all_tags.names, nl.name)
    table.insert(all_tags.layouts, nl.layout)
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

-- {{{ Manual timezone handling
-- TODO: Remove when glib is updated at least to 2.59.0
-- For the details, see https://github.com/GNOME/glib/commit/2ceb48dfc28f619b1bfe6037e5799ec9d0a0ab31

-- Remove leading and trailing spaces from the string.
-- trim5 from http://lua-users.org/wiki/StringTrim
function trim(s)
   return s:match'^%s*(.*%S)' or ''
end

-- Return a timezone string in ISO 8601:2000 standard form (+hhmm or -hhmm)
-- The recipe at http://lua-users.org/wiki/TimeZone does not work, probably
-- because of the bug in glib.
local function get_tzoffset()
    local handle = io.popen("date +%z")
    local result = handle:read("*a")
    handle:close()
    return trim(result)
end
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
local calendarwidget = wibox.widget.textclock(nil, nil, get_tzoffset())
local cal_box = calendar_popup.month(calendar_args)
cal_box:attach(calendarwidget, 'tr')

local cpuwidget = wibox.widget.graph()
vicious.register(cpuwidget, vicious.widgets.cpu, "$1", 0.5)

local memwidget = wibox.widget.progressbar()
vicious.register(memwidget, vicious.widgets.mem, "$1", 2)

--local batwidget = battery()
-- vicious battery widget doesn't work and requires manual configuration

local vpnwidget = vpn()

-- {{{ Helper functions
local function client_menu_toggle_fn(only_current_tag)
    local instance

    return function()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            local filter_fn
            if only_current_tag then
                local s = awful.screen.focused()
                local tags = {}
                for _, t in ipairs(s.selected_tags) do
                    tags[t] = true
                end

                filter_fn = function(c)
                    for _, t in ipairs(c:tags()) do
                        if tags[t] then return true end
                    end
                end
            else
                filter_fn = function(c) return true end
            end

            local items = {}
            local key = 0;
            for c in awful.client.iterate(filter_fn) do
                local name = c.name or ""
                if key < 10 then
                    name = "[&" .. key .. "] " .. name
                    key = key + 1
                end
                table.insert(items, {
                    text = name,
                    cmd = function()
                        if not c.valid then return end
                        if not c:isvisible() then
                            awful.tag.viewmore(c:tags(), c.screen)
                        end
                        c:emit_signal("request::activate", "menu.clients", { raise = true })
                    end,
                    icon = c.icon
                })
            end

            if next(items) ~= nil then
                instance = awful.menu.new({
                    theme = { width = 300 },
                    items = items
                })
                instance:show()
                -- Highlight currently focused client
                instance:item_enter(1)
            end
        end
    end
end

-- }}}

local function refocus_centerwork_layout_main_client(screen, cb)
    for _, t in pairs(screen.tags) do
        -- Do not do anything when switching _to_ a tag.
        if t.selected and t.layout.name == 'centerwork' then
            local find_client = function ()
                local tag_first_client
                for _, c in pairs(client.get(screen)) do
                    if c.sticky then
                        return c
                    elseif awful.client.focus.filter(c) then
                        for _, v in ipairs(c:tags()) do
                            if v == t then
                                if c.maximized then
                                    -- Only use the maximized window if it's the one focused.
                                    -- Otherwise, maximized windows from the back of the stack
                                    -- will be brought forward.
                                    if c == client.focus then return c end
                                elseif tag_first_client == nil and not c.minimized then
                                    tag_first_client = c
                                end
                            end
                        end
                    end
                end
                return tag_first_client
            end
            local chosen_client = find_client()
            -- Cannot use `awful.layout.parameters` because it returns
            -- an empty list of clients if the tag is not selected.
            if chosen_client and chosen_client.focusable then
                chosen_client:emit_signal("request::activate", "refocus_centerwork_layout_main_client")
            end
        end
    end
    -- Note that just directly calling `cb` or even wrapping it in `gears.timer.delayed_call`
    -- will not work because changing focus is lazy while changing a tag is not.
    -- Some discussion and more details: https://github.com/awesomeWM/awesome/issues/3153
    gears.timer.start_new(0.01, cb)
end

local function switch_to_tag(tag)
    refocus_centerwork_layout_main_client(tag.screen, function() tag:view_only() end)
end

-- {{{ Based on https://github.com/awesomeWM/awesome/issues/2518#issuecomment-500389134.
local function update_borders(s)
    if s and s.selected_tag then
        local ln = s.selected_tag.layout.name
        local max = (ln == "max" or ln == 'fullscreen')
        -- Use tiled_clients so that other floating windows don't affect the count.
        local only_one = #s.tiled_clients == 1
        -- But iterate over clients instead of tiled_clients as tiled_clients doesn't include maximized windows.
        for _, c in pairs(s.clients) do
            if c.maximized or ((max or only_one) and not c.floating) then
                c.border_width = 0
            else
                c.border_width = beautiful.border_width
            end
        end
    end
end

local function connect_props_signals(lib, props, f)
    for _, prop in ipairs(props) do
        lib.connect_signal('property::' .. prop, f)
    end
end

local function update_borders_by_client(c)
    if c then
        update_borders(c.screen)
    end
end
connect_props_signals(client,
                      { 'floating', 'fullscreen', 'maximized_vertical',
                        'maximized_horizontal', 'maximized', 'minimized', 'hidden' },
                      update_borders_by_client)
for _, sg in pairs({'list', 'manage'}) do
    client.connect_signal(sg, update_borders_by_client)
end
client.connect_signal("property::screen", function(c, old_screen)
    update_borders_by_client(c)
    update_borders(old_screen)
end)

connect_props_signals(tag,
                      { 'selected', 'activated', 'tagged' },
                      function(t) update_borders(t.screen) end)
-- }}}

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) switch_to_tag(t) end),
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

local tasklist_buttons = gears.table.join(awful.button({}, 1, function(c)
    if c == client.focus then
        c.minimized = true
    else
        c:emit_signal("request::activate", "tasklist", {raise = true})
    end
end),
    awful.button({}, 3, client_menu_toggle_fn(false)),
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

-- From https://cgit.kde.org/plasma-workspace.git/tree/components/keyboardlayout/org.kde.KeyboardLayouts.xml
local kbd_interface = 'org.kde.KeyboardLayouts'
local kbd_signal = 'currentLayoutChanged'
local kbd_getter = 'getCurrentLayout'
-- From https://cgit.kde.org/plasma-workspace.git/tree/components/keyboardlayout/keyboardlayout.cpp
local kbd_path = '/Layouts'

local function kbd_layout_to_img(layout)
    -- Requires `famfamfam-flag-png` package to be installed.
    return '/usr/share/flags/countries/16x11/' .. layout .. ".png"
end

local function get_current_kbd_layout()
    local kbd_current_layout_cmd = 'dbus-send --print-reply=literal --dest=org.kde.kded5 ' .. kbd_path .. ' ' .. kbd_interface .. '.' .. kbd_getter
    local handle = io.popen(kbd_current_layout_cmd)
    local result = handle:read('*a')
    handle:close()
    return trim(result)
end

local kbd_initial_image = kbd_layout_to_img(get_current_kbd_layout())
dbus.add_match('session', "interface='" .. kbd_interface .. "',member='" .. kbd_signal .. "'")

-- {{{ Wibar
awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag(all_tags.names, s, all_tags.layouts)

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })
    local size = s.mywibox.height;

    local kbdwidget = wibox.widget {
        widget = wibox.widget.imagebox,
        image = kbd_initial_image,
        resize = true
    }
    dbus.connect_signal(kbd_interface, function(data, layout)
        if data.member == kbd_signal and data.path == kbd_path then
            kbdwidget:set_image(kbd_layout_to_img(layout))
        end
    end)

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            -- TODO: Remove when https://github.com/awesomeWM/awesome/issues/3089 is fixed.
            fill_space = true,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        {
            -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            spacing = math.ceil(size / 5),
            {
                widget = cpuwidget,
                color = {
                    type = "linear",
                    from = { 0, 0 },
                    to = { 0, 40 },
                    stops = { { 0, "#FF5656" }, { 0.5, "#88A175" }, { 1, "#AECF96" } }
                },
                background_color = "#494B4F",
                forced_width = size * 2;
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
                forced_width = math.ceil(size / 3),
                direction = 'east',
                layout = wibox.container.rotate
            },
            wibox.widget {
                forced_width = math.ceil(size * 1.5),
                widget = apw.progressbar
            },
            --batwidget,
            air_monitor,
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
root.buttons(gears.table.join(awful.button({}, 3, function() mymainmenu:toggle() end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)))
-- }}}

-- {{{ Key bindings
--@formatter:off
local globalkeys = gears.table.join(
    awful.key({}, "#126", function() awful.spawn.with_shell(switch_dp_monitor_cmd) end,
        { description = "Switch monitor (plus-minus sign, Fn+F5)", group = "awesome" }),

    awful.key({ modkey, "Control" }, "t", function() awful.spawn(jetbrains_toolbox_cmd) end,
        { description = "Launch JetBrains Toolbox", group = "launcher" }),

    awful.key({ modkey }, "Tab", function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        { description = "go back", group = "client" }),
    awful.key({ modkey }, "c", client_menu_toggle_fn(true),
        { description = "select client", group = "client" }),

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

    awful.key({}, "Print", function()
        awful.spawn(screenshot_screen)
    end),

    awful.key({ "Shift" }, "Print", function()
        awful.spawn(screenshot_window)
    end),

    awful.key({ "Control", "Shift" }, "Print", function()
        awful.spawn(screenshot_selection)
    end),

    awful.key({ modkey }, "q", function()
        awful.spawn(lock_cmd)
    end),

    awful.key({ modkey, "Mod1" }, "q", function()  -- Alt
        awful.spawn(logout_cmd)
    end),

    awful.key({ modkey, "Control" }, "q", function()
        awful.spawn.with_shell(suspend_cmd)
    end),

    awful.key({ modkey, "Control", "Shift" }, "q", function()
        awful.spawn(hibernate_cmd)
    end),

    awful.key({ modkey, }, "w", function() mymainmenu:show() end,
        { description = "show main menu", group = "awesome" }),

    -- Layout manipulation
    awful.key({ modkey, "Control" }, "j", function() awful.screen.focus_relative(1) end,
        { description = "focus the next screen", group = "screen" }),
    awful.key({ modkey, "Control" }, "k", function() awful.screen.focus_relative(-1) end,
        { description = "focus the previous screen", group = "screen" }),
    awful.key({ modkey, }, "u", awful.client.urgent.jumpto,
        { description = "jump to urgent client", group = "client" }),

    -- Standard program
    awful.key({ modkey, }, "Return", function() awful.spawn(terminal) end,
        { description = "open a terminal", group = "launcher" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
        { description = "reload awesome", group = "awesome" }),

    awful.key({ modkey }, ".", function() awful.tag.incmwfact(0.05) end,
        { description = "increase master width factor", group = "layout" }),
    awful.key({ modkey }, ",", function() awful.tag.incmwfact(-0.05) end,
        { description = "decrease master width factor", group = "layout" }),
    awful.key({ modkey, "Control", "Shift" }, "h", function() awful.tag.incnmaster(1, nil, true) end,
        { description = "increase the number of master clients", group = "layout" }),
    awful.key({ modkey, "Control", "Shift" }, "l", function() awful.tag.incnmaster(-1, nil, true) end,
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

local client_direction_keys = {
    { key = "j", dir = "down", desc = "below" },
    { key = "k", dir = "up", desc = "above" },
    { key = "h", dir = "left", desc = "on the left" },
    { key = "l", dir = "right", desc = "on the right" }
}
for _, k_desc in pairs(client_direction_keys) do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, k_desc.key,
            function()
                awful.client.focus.bydirection(k_desc.dir)
                if client.focus then client.focus:raise() end
            end,
            { description = "focus a client " .. k_desc.desc, group = "client" }),
        awful.key({ modkey, "Shift" }, k_desc.key,
            function()
                awful.client.swap.bydirection(k_desc.dir)
            end,
            { description = "swap with a client " .. k_desc.desc, group = "client" }))
end

local clientkeys = gears.table.join(awful.key({ modkey, }, "f",
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

            -- TODO: Remove when https://github.com/awesomeWM/awesome/issues/1692 is fixed.
            if client.focus and not client.focus.fullscreen and not c.maximized then
                client.focus.ignore_border_width = false
                client.focus.border_width = beautiful.border_width
            end

            c:raise()
        end,
        { description = "maximize", group = "client" }))

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                          switch_to_tag(tag)
                      end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        if c.focusable then
            c:emit_signal("request::activate", "mouse_click", {raise = true})
        end
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
--awful.ewmh.add_activate_filter(function(c)
--    return false
--end)
-- Use `xprop WM_STATE WM_HINTS WM_TRANSIENT_FOR WM_PROTOCOLS WM_CLASS WM_CLIENT_LEADER WM_NAME WM_NORMAL_HINTS`
-- to extract common useful properties.
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
                "xtightvncviewer",
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

    -- Ad-hoc rules
    {
        rule = {
            class = "Pavucontrol",
        },
        properties = {
            floating = true,
            delayed_placement = awful.placement.centered,
        }
    },

    {
        rule = {
            class = "factorio",
        },
        properties = {
            floating = true,
            width = 1280,
            height = 1280,
            delayed_placement = awful.placement.centered,
        }
    },

    {
        rule = {
            name = "Export Image as JPEG",
        },
        properties = {
            placement = awful.placement.centered,
        }
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
        -- IDEA starting splash screen.
        rule = {
            -- For some reason, using `^$` does not work here in Awesome v4.3-219.
            -- But it works in other places *shrug*.
            class = "jetbrains-idea",
            name = "^win"
        },
        properties = {
            floating = true,
            focusable = false,
        }
    },

    {
        rule = {
            class = "^insync",
            name = "^Insync$"
        },
        properties = {
            prevent_auto_unfocus = true,
            floating = true,
            maximized = false,
            placement = awful.placement.top_right
        },
    },

    {
        rule = {
            -- The main Slack window is named like "Slack | %channel/user% | %server%".
            -- The call popup is named just "Slack | mini panel", and it requests to skip taskbar.
            -- The other difference is that it has
            -- `NET_WM_WINDOW_TYPE(ATOM) = _NET_WM_WINDOW_TYPE_CALLS-MINI-PANEL`
            -- where the main window has
            -- `NET_WM_WINDOW_TYPE(ATOM) = _NET_WM_WINDOW_TYPE_NORMAL`
            -- but I'm not sure how to use it.
            name = "Slack | mini panel",
        },
        properties = {
            skip_taskbar = true,
            focusable = false,
            floating = true,
            ontop = true,
        }
    },

    {
        rule = {
            class = "GoldenDict"
        },
        properties = {
            floating = true,
            placement = awful.placement.bottom,
        },
    },
}

-- Taken from https://github.com/alfunx/.dotfiles/blob/master/.config/awesome/config/rules.lua
-- placement, that should be applied after setting x/y/width/height/geometry
-- TODO: Check and remove after https://github.com/awesomeWM/awesome/issues/2497 is fixed
function awful.rules.delayed_properties.delayed_placement(c, value, props)
    if props.delayed_placement then
        awful.rules.extra_properties.placement(c, props.delayed_placement, props)
    end
end

-- NOTE: Use `xprop WM_CLASS` to get the value and use the last item in the list.
--       To spy on the classes of newly opened windows, you can try using
--       `xprop -spy -root _NET_ACTIVE_WINDOW | stdbuf -oL cut -f5 -d' ' | xargs -I{} xprop -id {} WM_CLASS`.
--  The values are case-sensitive.
local tag_rules = {
    ["www"] = {},
    ["dev"] = { "^jetbrains-", "java-lang-Thread" },
    ["soc"] = { "Skype", "Telegram", "Slack", "discord", "Zulip" },
    ["db"] = { "com-install4j-runtime-launcher-Launcher", "Cherrytree", "calibre" },
    ["@"] = { "Thunderbird" },
    ["vb"] = { "VirtualBox" },
    ["8"] = { "Deadbeef" },
    ["9"] = { "Steam" }
}

for tag_name, classes in pairs(tag_rules) do
    for _, c in pairs(classes) do
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
    gears.timer { timeout = 0.01,
                  autostart = true,
                  callback = function()
                      t:stop()
                      local c = mouse.current_client
                      if c then
                          refocus_client(c)
                      end
                  end }
end

--screen.connect_signal("tag::history::update", delay_refocus_client_under_mouse)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- this adds the default 3.5 behavior when adding/removing a screen
-- see https://github.com/awesomeWM/awesome/issues/1382
screen.connect_signal("removed", awesome.restart)
screen.connect_signal("added", awesome.restart)

-- }}}
