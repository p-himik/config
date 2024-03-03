(local {: trim : file-exists? : rotate-table-in-place} (require :rc.util))
(local awful (require :awful))
(local button (require :awful.button))
(local spawn (require :awful.spawn))
(local wibox (require :wibox))
(local gears (require :gears))
(local gdebug (require :gears.debug))
(local keyboardlayout (require :awful.widget.keyboardlayout))

(fn set-text [ctx txt]
  (ctx.text-widget:set_visible true)
  (ctx.img-widget:set_visible false)
  (ctx.text-widget:set_text txt))

(fn set-img [ctx img]
  (ctx.text-widget:set_visible false)
  (ctx.img-widget:set_visible true)
  (ctx.img-widget:set_image img))

(fn layout-name [v]
  (if (= v.section nil)
      v.file
      (.. v.file "(" v.section ")")))

(fn layout-icon [v]
  ;; Requires `famfamfam-flag-png` package to be installed.
  (.. :/usr/share/flags/countries/16x11/ v.file :.png))

(fn update-status [ctx]
  (tset ctx :_current (awesome.xkb_get_layout_group))
  (let [layout (when (> (length ctx._layout) 0)
                 (. ctx._layout (+ ctx._current 1)))]
    (if layout
        (let [img-path (layout-icon layout)]
          (if (file-exists? img-path)
              (set-img ctx img-path)
              (set-text ctx (.. " " (layout-name layout) " "))))
        (set-text ctx ""))))

(fn set-layout [ctx group-number]
  (if (or (< group-number 0) (> group-number (length ctx._layout)))
      (error (.. "Invalid group number: " group-number
                 ". Expected number from 0 to " (length ctx._layout)))
      (awesome.xkb_set_layout_group group-number)))

(fn rotate-layouts [ctx shift]
  (let [files (icollect [_ v (pairs ctx._layout)]
                v.file)
        files (rotate-table-in-place files shift)]
    (spawn.spawn [:setxkbmap (table.concat files ",")])))

(fn clear-menu [menu]
  (for [idx (length menu.items) 1 -1]
    (menu:delete idx)))

(fn update-layout [ctx]
  (tset ctx :_layout [])
  (let [layouts (keyboardlayout.get_groups_from_group_names (awesome.xkb_get_group_names))]
    (clear-menu ctx.menu)
    (if (or (= layouts nil) (= (. layouts 1) nil))
        (do
          (gdebug.print_error "Failed to get list of keyboard groups")
          nil)
        (do
          (when (= (length layouts) 1)
            (tset (. layouts 1) :group_idx 1))
          (each [idx v (ipairs layouts)]
            (ctx.menu:add {:text (layout-name v)
                           :icon (layout-icon v)
                           :cmd (fn []
                                  (rotate-layouts ctx (- 1 idx))
                                  false)})
            (tset ctx._layout v.group_idx v))
          (update-status ctx)))))

(fn create-widget []
  (let [text-widget (wibox.widget {:widget wibox.widget.textbox
                                   :resize true
                                   :visible true})
        img-widget (wibox.widget {:widget wibox.widget.imagebox
                                  :resize true
                                  :visible false})
        menu (awful.menu {:items []})
        ctx {: text-widget : img-widget : menu}]
    (img-widget:add_button (button [] 1 nil #(menu:toggle)))
    (update-layout ctx)
    (awesome.connect_signal "xkb::map_changed" (fn [] (update-layout ctx)))
    (awesome.connect_signal "xkb::group_changed" (fn [] (update-status ctx)))
    (wibox.widget (gears.table.crush [text-widget img-widget]
                                     {:layout wibox.layout.align.horizontal
                                      :buttons [(button [] 4
                                                        #(rotate-layouts ctx -1))
                                                (button [] 5
                                                        #(rotate-layouts ctx 1))]}))))
