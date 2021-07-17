(local awful (require :awful))
(local beautiful (require :beautiful))
(local clj (require :cljlib))
(local gfs (require :gears.filesystem))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local {: terminal : cmds} (require :rc.common))

;; The theme has to be initialized before we create any of the widgets.
(beautiful.init (.. (gfs.get_configuration_dir) "/themes/p-himik/theme.lua"))

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

(fn mk-client-menu-toggle-fn [only-current-tag?]
  (var instance nil)
  (fn [_c]
    (if (and instance instance.wibox.visible)
      (do
        (instance:hide)
        (set instance nil))
      (let [filter-fn (if only-current-tag?
                        (let [s (awful.screen.focused)
                              tags (collect [_ t (ipairs s.selected_tags)]
                                     (values t true))]
                          (fn [c]
                            (clj.some (fn [t] (. tags t)) (c:tags))))
                        (fn [_c] true))
            items {}]
        (var key 0)
        (each [c (awful.client.iterate filter-fn)]
          (let [name (or c.name "")
                name (if (< key 10)
                       (do
                         (set key (+ key 1))
                         (.. "[&" key "] " name))
                       name)
                cmd (fn []
                      (when c.valid
                        (when (not (c:isvisible))
                          (awful.tag.viewmore (c:tags) c.screen))
                        (c:emit_signal "request::activate" "menu.clients" {:raise true})))]
            (table.insert items {:text name
                                 :cmd  cmd
                                 :icon c.icon})))
        (when (not= nil (next items))
          (set instance (awful.menu.new {:theme {:width 300}
                                         :items items}))
          (instance:show)
          (instance:item_enter 1))))))

{:main-menu (awful.menu {:items [["Awesome" awesome-menu beautiful.awesome_icon]
                                 ["Open terminal" terminal]]})
 : mk-client-menu-toggle-fn
 :pulse (require :pulseaudio_widget)}
