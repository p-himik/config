--{{{ Main
local gfs = require("gears.filesystem")

local debug = debug
local os = os
local ipairs = ipairs

local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

local themedir      = script_path()

local shared        = "/usr/share/awesome"
if not gfs.file_readable(shared .. "/icons/awesome16.png") then
    shared    = "/usr/local/share/awesome"
end
local sharedicons   = shared .. "/icons"
local sharedthemes  = shared .. "/themes"
local theme_name    = "zenburn"
local shared_theme  = sharedthemes .. "/" .. theme_name
local awesome_dir   = themedir .. "/../.."

local theme = {}

local home_dir = os.getenv('HOME')
local supported_extensions = {'jpg', 'png' }
theme.wallpaper = function(_)
    local wp_path = os.getenv('AWESOME_WALLPAPER')
    if wp_path and gfs.file_readable(wp_path) then
        return wp_path
    end
    for _, ext in ipairs(supported_extensions) do
        wp_path = home_dir .. '.wallpaper.' .. ext
        if gfs.file_readable(wp_path) then
            return wp_path
        end
    end
    return themedir .. '/abstract_clouds.jpg'
end

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
--theme.border_focus  = "#1279bf"
theme.border_focus  = "#22a4ff"

theme.taglist_squares_sel         = themedir .. "/tasklist_f.png"
theme.taglist_squares_unsel       = themedir .. "/tasklist_u.png"
theme.tasklist_floating_icon      = themedir .. "/floating.png"

theme.titlebar_close_button_normal = shared_theme .. "/titlebar/close_normal.png"
theme.titlebar_close_button_focus  = shared_theme .. "/titlebar/close_focus.png"

theme.menu_submenu_icon = sharedthemes .. "/default/submenu.png"
theme.menu_height   = 15
theme.menu_width    = 100

local layouts_path = shared_theme .. "/layouts"
theme.layout_fairh = layouts_path .. "/fairh.png"
theme.layout_fairv = layouts_path .. "/fairv.png"
theme.layout_floating  = layouts_path .. "/floating.png"
theme.layout_magnifier = layouts_path .. "/magnifier.png"
theme.layout_max = layouts_path .. "/max.png"
theme.layout_fullscreen = layouts_path .."/fullscreen.png"
theme.layout_tilebottom = layouts_path .. "/tilebottom.png"
theme.layout_tileleft   = layouts_path .. "/tileleft.png"
theme.layout_tile = layouts_path .. "/tile.png"
theme.layout_tiletop = layouts_path .. "/tiletop.png"
theme.layout_spiral  = layouts_path .. "/spiral.png"
theme.layout_dwindle = layouts_path .. "/dwindle.png"

theme.layout_centerwork = awesome_dir .. "/lain/icons/layout/" .. theme_name .. "/centerwork.png"

theme.awesome_icon = sharedicons .. "/awesome16.png"

theme.notification_icon_size = 150

theme.apw_fg_color = '#698f1e'
theme.apw_bg_color = '#33450f'
theme.apw_mute_fg_color = '#be2a15'
theme.apw_mute_bg_color = '#532a15'

theme.icon_theme = 'oxygen/base'

return theme
