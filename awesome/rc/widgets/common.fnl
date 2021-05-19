(local awful (require :awful))
(local beautiful (require :beautiful))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local {: terminal : cmds} (require :rc.common))
(local {: config-path} (require :rc.util))
(local APW (require :apw4.widget))

;; The theme has to be initialized before we create any of the widgets.
(beautiful.init (.. (config-path) "/themes/p-himik/theme.lua"))

(fn beautiful.xresources.get_current_theme []
  ;; This function is needed just to remove the warning about missing xrdb config.
  {:color0 "#000000" :color8 "#465457"  ;; black
   :color1 "#cb1578" :color9 "#dc5e86"  ;; red
   :color2 "#8ecb15" :color10 "#9edc60" ;; green
   :color3 "#cb9a15" :color11 "#dcb65e" ;; yellow
   :color4 "#6f15cb" :color12 "#7e5edc" ;; blue
   :color5 "#cb15c9" :color13 "#b75edc" ;; purple
   :color6 "#15b4cb" :color14 "#5edcb4" ;; cyan
   :color7 "#888a85" :color15 "#ffffff" ;; white
   :background  "#0e0021" :foreground  "#bcbcbc"})

(local awesome-menu [
  ["Hotkeys" (fn [] (values false hotkeys-popup.show_help))]
  ["Manual" (.. terminal " -e man awesome")]
  ["Edit config" (.. cmds.editor " " awesome.conffile)]
  ["Restart" awesome.restart]
  ["Quit" awesome.quit]
])

{:main-menu (awful.menu {:items [["Awesome" awesome-menu beautiful.awesome_icon]
                                 ["Open terminal" terminal]]})
 :apw (APW {:tooltip false})}