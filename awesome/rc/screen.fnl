(local awful (require :awful))
(local beautiful (require :beautiful))
(local gears (require :gears))
(local tags (require :rc.tags))
(local {: modkey &as common} (require :rc.common))
(local create-kbd-widget (require :rc.widgets.keyboard))
(local create-calendar-widget (require :rc.widgets.calendar))
(local cw (require :rc.widgets.common))
(local set-wallpaper (require :rc.wallpaper))
(local vicious (require :vicious))
(local vpn (require :vpnwidget))
(local wibox (require :wibox))

(local all-tags {:names   []
                 :layouts []})
(each [_ nl (ipairs tags.tag-specs)]
  (table.insert all-tags.names nl.name)
  (table.insert all-tags.layouts nl.layout))

(fn box-props [params children]
  (gears.table.crush children params))

(local mylauncher (awful.widget.launcher {:image beautiful.awesome_icon
                                          :menu  cw.main-menu}))

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
  (let [b awful.button
        layout-button (fn [button inc]
                        (b [] button (fn [] (awful.layout.inc inc))))]
    (set s.mylayoutbox (awful.widget.layoutbox
                         {:screen s
                          :buttons [(layout-button 1 1)
                                    (layout-button 3 -1)
                                    (layout-button 4 1)
                                    (layout-button 5 -1)]}))
    (set s.mytaglist (awful.widget.taglist
                       {:screen s
                        :filter awful.widget.taglist.filter.all
                        :buttons [(b [] 1 tags.switch-to-tag)
                                  (b [modkey] 1 (fn [t] (-?> client.focus (: :move_to_tag t))))
                                  (b [] 3 awful.tag.viewtoggle)
                                  (b [modkey] 3 (fn [t] (-?> client.focus (: :toggle_tag t))))
                                  (b [] 4 (fn [t] (awful.tag.viewnext t.screen)))
                                  (b [] 5 (fn [t] (awful.tag.viewprev t.screen)))]}))
    (set s.mytasklist (awful.widget.tasklist
                        {:screen s
                         :filter awful.widget.tasklist.filter.currenttags
                         :buttons [(b [] 1 (fn [c] (c:activate {:context :tasklist :action :toggle_minimization})))
                                   (b [] 3 (cw.mk-client-menu-toggle-fn false))
                                   (b [] 4 (fn [_c] (awful.client.focus.byidx 1)))
                                   (b [] 5 (fn [_c] (awful.client.focus.byidx -1)))]})))
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
                              {:widget cw.apw.progressbar
                               :forced_width (math.ceil (* size 1.5))}
                              ;batwidget
                              air-monitor
                              vpn-widget
                              (create-kbd-widget)
                              (wibox.widget.systray)
                              calendar-widget
                              s.mylayoutbox])]))))

(screen.connect_signal
  :request::desktop_decoration
  (fn [s]
    (set-wallpaper s)
    (add-wibar-to-screen s)))
