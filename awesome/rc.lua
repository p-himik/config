
-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")

-- In case we use symlink as rc.lua, we need to change paths
local posix = require("posix")
function get_real_config_dir()
    local c = awful.util.getdir('config')
    return posix.realpath(posix.dirname(posix.readlink(c .. '/rc.lua')))
end
local config_dir = get_real_config_dir()

package.path = package.path .. ';' .. config_dir .. '/?.lua;' .. config_dir .. '/?/init.lua'

--local timer = require("gears").timer
local timer = timer

local menubar = require("menubar")

local APW = require("apw/widget")


require("vpnwidget")
require("obvious.clock")
require("obvious.battery")

require("retrograde")

local blingbling = require('blingbling')

local scratch = require("scratch")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
--beautiful.init("/usr/local/share/awesome/themes/default/theme.lua")
beautiful.init(config_dir .. "/themes/p-himik/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "terminator"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -x " .. editor

obvious.clock.set_editor(editor_cmd)
obvious.clock.set_shortformat(" %a %b %d, %R ")
obvious.clock.set_longformat(" %a %b %d, %R ")

lock_cmd = "physlock -dms"
logout_cmd = "pkill -u " .. os.getenv("USER")
suspend_cmd = 'dbus-send --system --print-reply --dest="org.freedesktop.login1" /org/freedesktop/login1 org.freedesktop.login1.Manager.Suspend boolean:true'
xbindkeys_reset = "killall xbindkeys"
xbindkeys_init = "xbindkeys"
scrot_cmd = "scrot"
switch_dp_monitor_cmd = "switch_monitor.sh DP1"

autostarts = {
    shell = {
        "kbdd",
    },
    noshell = {
    }
}

function spawn_array(a)
    for i, e in ipairs(a.noshell) do
        awful.util.spawn(e)
    end
    for i, e in ipairs(a.shell) do
        awful.util.spawn_with_shell(e)
    end
end

spawn_array(autostarts)

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
awful.layout.layouts = layouts
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {
    names  = { "cmd", "www", "dev", "soc", "db", "st", "vb", 8, "mail" },
    layout = { layouts[6], layouts[3], layouts[8], layouts[6], layouts[3],
               layouts[3], layouts[3], layouts[3],  layouts[3], layouts[3] }
           }
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag(tags.names, s, tags.layout)
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a wibox for each screen and add it
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

kbd_dbus_next_cmd = "dbus-send --dest=ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.next_layout"
kbd_img_path = "/usr/local/share/icons/flags/"
kbd_images = {[0] = kbd_img_path .. "us.png",
              [1] = kbd_img_path .. "ru.png"}
dbus.request_name("session", "ru.gentoo.kbdd")
dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")


local function print_events_from_remind(day_widget, month, year, info_cell)
	local day = day_widget._layout.text
	local month = month
	local year = year
	local remind_conf = '~/.config/remind/reminders.rem'
	-- Not that it must be lighter to read the file directly and parse it
	local day_events = awful.util.pread('remind -k\'echo %s\' '..remind_conf ..' ' .. day .. " " .. os.date("%B",os.time{year=year, month=month, day=day}) .." " .. year)
	day_events = string.gsub(day_events,"\n\n+","\n")
	day_events  =string.gsub(day_events,"\n*$","")
	day_events="Remind:\n" .. day_events

	info_cell:set_text(day_events)
end

local function print_info_leave(widget, month, year, info_cell)
    info_cell:set_text("")
end

calendar = blingbling.calendar(obvious.clock())
calendar:set_link_to_external_calendar(true)


for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    kbdwidget = wibox.widget.imagebox(kbd_images[0], true)
    dbus.connect_signal("ru.gentoo.kbdd", function(...)
            local data = {...}
            local layout = data[2]
            kbdwidget:set_image(kbd_images[layout])
        end
    )

    -- Create the wibox
    awful.wibox({ position = "top", screen = s }):set_widgets {
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            mytaglist[s],
            mypromptbox[s]
        },
        mytasklist[s],
        {
            layout = wibox.layout.fixed.horizontal,
            APW,
            wibox.layout.margin(obvious.battery(), 5, 5),
            wibox.layout.margin(vpnwidget, 5, 5),
            kbdwidget,
            s == screen.count() and wibox.widget.systray() or nil,
            calendar,
            mylayoutbox[s]
        }
    }
end
-- }}}

-- {{{ Mouse bindings
volumebuttons = awful.util.table.join(
    --awful.button({ modkey }, 4, APW.Down),
    --awful.button({ modkey }, 5, APW.Up)
    )

clientbuttons = awful.util.table.join(
    volumebuttons,
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

globalbuttons = awful.util.table.join(
    volumebuttons,
    awful.button({ }, 3, function () mymainmenu:toggle() end))

root.buttons(globalbuttons)
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ }, "#126",                  function() -- plus-minus sign, Fn+F5
        awful.util.spawn_with_shell(switch_dp_monitor_cmd)
    end),

    awful.key({ }, "XF86AudioRaiseVolume",  APW.Up),
    awful.key({ }, "XF86AudioLowerVolume",  APW.Down),
    awful.key({ }, "XF86AudioMute",         APW.ToggleMute),
    awful.key({ modkey }, "Left",           APW.Down),
    awful.key({ modkey }, "Right",          APW.Up),

    awful.key({ }, "#107", function()
        awful.util.spawn(scrot_cmd)
    end),

    awful.key({ modkey, "Control" }, "#46", function()
        awful.util.spawn(lock_cmd)
    end),

    awful.key({ modkey, "Control", "Shift" }, "#46", function() -- l
        awful.util.spawn(logout_cmd)
    end),

    awful.key({ modkey, "Control" }, "#39", function() -- s
        awful.util.spawn(suspend_cmd)
    end),

    --awful.key({ modkey }, "Left",   awful.tag.viewprev       ),
    --awful.key({ modkey }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey }, "Escape", awful.tag.history.restore),

    awful.key({ modkey }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    --awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    -- Dropdown terminal
    --awful.key({ modkey,           }, "z", function () drop(terminal) end),
    awful.key({ modkey,           }, "z", function () scratch.pad.toggle() end),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
)

function show_client_under_mouse_properties(c)
    f = io.popen('xdotool getmouselocation --shell | grep WINDOW |cut -d= -f2')
    id = f:read("*n")
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "ID",
                     text = id })
    f:close()
    f = io.popen('xprop -id ' .. id .. ' | grep -v "^\t[^\t]"')
    r = ''
    for l in f:lines() do
        r = r .. '\n' .. l
    end
    f:close()
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "CLIENT INFO",
                     text = r })
end

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "s",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey, "Shift"   }, "n",
        function (c)
            c.minimized = true
            c.minimized = false
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     size_hints_honor = false } },
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinetry",
          "veromix",
          "xtightvncviewer"
        },
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
    }, properties = { floating = true }},
}

tag_rules = {
    [2] = { "Google-chrome", "Firefox" },
    [3] = { "jetbrains-idea", "jetbrains-pycharm", "XMP SDK" },
    [4] = { "Skype" },
    [5] = { "com-install4j-runtime-launcher-Launcher" },
    [6] = { "Sublime_text" },
    [7] = { "VirtualBox" },
    [9] = { "Thunderbird" }
}

for i, r in pairs(tag_rules) do
    for _, c in pairs(r) do
        table.insert(awful.rules.rules, {
            rule = { class = c, type = "normal" },
            properties = { tag = tags[screen.count()][i] }
        })
    end
end
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)

    if not awesome.startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

-- Enable sloppy focus
function refocus_client(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end
client.connect_signal("mouse::enter", refocus_client)

function delay_refocus_client_under_mouse()
    local t = timer { timeout = 0.01 }
    t:connect_signal("timeout", function()
        t:stop()
        local c = awful.mouse.client_under_pointer()
        if c then
            refocus_client(c)
        end
    end)
    t:start()
end

for s = 1, screen.count() do
    screen[s]:connect_signal("tag::history::update", delay_refocus_client_under_mouse)
end


client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- Override awesome.quit when we're using GNOME
--_awesome.quit = awesome.quit
--awesome.quit = function ()
--    if os.getenv("DESKTOP_SESSION") == "awesome-gnome" then
--        os.execute("/usr/bin/gnome-session-quit")
--    else
--        _awesome.quit()
--    end
--end

