(local awful (require :awful))
(local beautiful (require :beautiful))
(local gears (require :gears))
(local layout-by-tag (require :rc.tags))
(local {: taglist-buttons : tasklist-buttons} (require :rc.bindings))
(local common (require :rc.common))
(local create-kbd-widget (require :rc.widgets.keyboard))
(local create-calendar-widget (require :rc.widgets.calendar))
(local {: main-menu : apw} (require :rc.widgets.common))
(local vicious (require :vicious))
(local vpn (require :vpnwidget))
(local wibox (require :wibox))

(local all-tags {:names   []
                 :layouts []})
(each [_ nl (ipairs layout-by-tag)]
  (table.insert all-tags.names nl.name)
  (table.insert all-tags.layouts nl.layout))

(fn box-props [params children]
  (gears.table.crush children params))

(local mylauncher (awful.widget.launcher {:image beautiful.awesome_icon
                                          :menu  main-menu}))

(local cpu-widget (doto (wibox.widget.graph)
                    (vicious.register vicious.widgets.cpu "$1" 0.5)))

(local mem-widget (doto (wibox.widget.progressbar)
                    (vicious.register vicious.widgets.mem "$1" 2)))

(local air-monitor (match common.air-monitor
                     cfg ((require :air_monitor) (gears.table.join cfg {:notify_co2 true}))))

(local vpn-widget (vpn))

;; `vicious` battery widget doesn't work and requires manual configuration.
;;(local battery (require :battery))
;;(local batwidget (battery))

(local calendar-widget (create-calendar-widget))

(fn add-wibar-to-screen [s]
  ;; Each screen has its own tag table.
  (awful.tag all-tags.names s all-tags.layouts)

  (set s.mypromptbox (awful.widget.prompt))
  (set s.mylayoutbox (awful.widget.layoutbox s))
  (let [layout-button (fn [b inc]
                        (awful.button [] b (fn [] (awful.layout.inc inc))))]
    (s.mylayoutbox:buttons (gears.table.join (layout-button 1 1)
                                             (layout-button 3 -1)
                                             (layout-button 4 1)
                                             (layout-button 5 -1))))
  (set s.mytaglist (awful.widget.taglist s awful.widget.taglist.filter.all taglist-buttons))
  (set s.mytasklist (awful.widget.tasklist s awful.widget.tasklist.filter.currenttags tasklist-buttons))
  (set s.mywibox (awful.wibar {:position :top :screen s}))
  (let [size s.mywibox.height]
    (s.mywibox:setup
      (box-props {:layout wibox.layout.align.horizontal}
                 [(box-props {:layout wibox.layout.fixed.horizontal
                              ;; TODO: Remove when https://github.com/awesomeWM/awesome/issues/3089 is fixed.
                              :fill_space true}
                             [mylauncher
                              s.mytaglist
                              s.mypromptbox])
                  s.mytasklist
                  (box-props {:layout wibox.layout.fixed.horizontal
                              :spacing (math.ceil (/ size 5))}
                             [{:widget cpu-widget
                               :color {:type  :linear
                                       :from  [0 0]
                                       :to    [0 40]
                                       :stops [[0 "#FF5656"] [0.5 "#88A175"] [1 "#AECF96"]]}
                               :background_color "#494B4F"
                               :forced_width (* size 2)}
                              (box-props {:border_color nil
                                          :forced_width (math.ceil (/ size 3))
                                          :direction :east
                                          :layout wibox.container.rotate}
                                         [{:widget mem-widget
                                           :color {:type  :linear
                                                   :from  [0 0]
                                                   :to    [20 0]
                                                   :stops [[0 "#AECF96"] [0.5 "#88A175"] [1 "#FF5656"]]}
                                           :background_color "#494B4F"}])
                              {:widget apw.progressbar
                               :forced_width (math.ceil (* size 1.5))}
                              ;batwidget
                              air-monitor
                              vpn-widget
                              (create-kbd-widget)
                              (wibox.widget.systray)
                              calendar-widget
                              s.mylayoutbox])]))))
