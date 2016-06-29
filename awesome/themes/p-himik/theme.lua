--{{{ Main
local awful = require("awful")
awful.util = require("awful.util")

theme = {}

function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

shared        = "/usr/share/awesome"
if not awful.util.file_readable(shared .. "/icons/awesome16.png") then
    shared    = "/usr/local/share/awesome"
end
sharedicons   = shared .. "/icons"
sharedthemes  = shared .. "/themes"
themedir      = script_path()

theme.wallpaper = themedir .. '/abstract_clouds.jpg'

--}}}

theme.font    = "Fixed 8"

theme.bg_normal     = "#333333"
theme.bg_focus      = "#1279bf"
theme.bg_urgent     = "#00ff00"

theme.fg_normal     = "#999999"
theme.fg_focus      = "#ffffff"
theme.fg_urgent     = "#111111"

theme.border_width  = 3
-- theme.border_normal = "#333333"
theme.border_normal = "#4e4e4e"
theme.border_focus  = "#1279bf"

theme.taglist_squares_sel         = themedir .. "/tasklist_f.png"
theme.taglist_squares_unsel       = themedir .. "/tasklist_u.png"
theme.tasklist_floating_icon      = themedir .. "/floating.png"

theme.titlebar_close_button_normal = sharedthemes .. "/default/titlebar/close.png"
theme.titlebar_close_button_focus  = sharedthemes .. "/default/titlebar/closer.png"

theme.menu_submenu_icon = sharedthemes .. "/default/submenu.png"
theme.menu_height   = 15
theme.menu_width    = 100

theme.layout_fairh = "/usr/local/share/awesome/themes/default/layouts/fairhw.png"
theme.layout_fairv = "/usr/local/share/awesome/themes/default/layouts/fairvw.png"
theme.layout_floating  = "/usr/local/share/awesome/themes/default/layouts/floatingw.png"
theme.layout_magnifier = "/usr/local/share/awesome/themes/default/layouts/magnifierw.png"
theme.layout_max = "/usr/local/share/awesome/themes/default/layouts/maxw.png"
theme.layout_fullscreen = "/usr/local/share/awesome/themes/default/layouts/fullscreenw.png"
theme.layout_tilebottom = "/usr/local/share/awesome/themes/default/layouts/tilebottomw.png"
theme.layout_tileleft   = "/usr/local/share/awesome/themes/default/layouts/tileleftw.png"
theme.layout_tile = "/usr/local/share/awesome/themes/default/layouts/tilew.png"
theme.layout_tiletop = "/usr/local/share/awesome/themes/default/layouts/tiletopw.png"
theme.layout_spiral  = "/usr/local/share/awesome/themes/default/layouts/spiralw.png"
theme.layout_dwindle = "/usr/local/share/awesome/themes/default/layouts/dwindlew.png"

theme.awesome_icon = sharedicons .. "/awesome16.png"

return theme
