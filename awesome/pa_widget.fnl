(local awful (require :awful))
(local beautiful (require :beautiful))
(local gears (require :gears))
(local lgi (require :lgi))
(local naughty (require :naughty))
(local wibox (require :wibox))
(local spawn (require :awful.spawn))

(local (json-status json) (pcall require :cjson))

(local Gtk (lgi.require :Gtk :3.0))

(local module {:mt {}})

(fn find-idx [tbl pred]
  (each [idx val (ipairs tbl)]
    (when (pred val)
      (lua "return idx"))))

(fn find-val [tbl pred]
  (-?>> (find-idx tbl pred) (. tbl)))

(fn clamp [v min max]
  (if (< v min) min
      (> v max) max
      v))

(fn str-starts-with? [s substr]
  (= (s:sub 1 (length substr)) substr))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn spawn-pactl-subscribe [ctx subscriber]
  (let [pid (spawn.with_line_callback "pactl subscribe"
              {:stdout (fn [line]
                         (when (str-starts-with? line "Event 'change' on ")
                           (if (line:find " sink ") (subscriber.on-sink-change)
                               (line:find " source ")
                               (subscriber.on-source-change)
                               (line:find " server ")
                               (subscriber.on-server-change))))
               :exit (fn [reason code]
                       (if (= reason :signal)
                           (match code
                             ;; Do nothing, it was terminated deliberately.
                             9
                             nil
                             ;; Restarted deliberately.
                             1
                             (spawn-pactl-subscribe ctx subscriber)
                             ;; Else notify.
                             _
                             (naughty.notify {:title "`pactl subscribe` has been killed"
                                              :text (.. "Signal: " code
                                                        ". You can restart it by restarting Awesome WM.")
                                              :preset naughty.config.presets.critical}))
                           (do
                             (naughty.notify {:title "`pactl subscribe` has exited"
                                              :text (.. "Exit status: " code
                                                        ". It was restarted automatically.")
                                              :timeout 3
                                              :preset naughty.config.presets.warn})
                             (spawn-pactl-subscribe ctx subscriber))))})]
    (tset ctx :pactl-pid pid)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local volume-step 3)
(local volume-max 100)

(fn muted? [device-info]
  device-info.mute)

(fn hw-device? [device-info]
  (not= :monitor (-> device-info.properties (. :device.class))))

(fn has-available-ports? [device-info]
  (find-idx device-info.ports (fn [p] (not= p.availability "not available"))))

(fn get-sinks [cb]
  (spawn.easy_async "pactl -f json list sinks"
                    (fn [stdout _ _ _]
                      (cb (icollect [_ d (ipairs (json.decode stdout))]
                            (when (hw-device? d)
                              d))))))

(fn get-sources [cb]
  (spawn.easy_async "pactl -f json list sources"
                    (fn [stdout _ _ _]
                      (cb (icollect [_ d (ipairs (json.decode stdout))]
                            (when (and (hw-device? d) (has-available-ports? d))
                              d))))))

(fn find-device-idx-by-name [devices name]
  (find-idx devices (fn [d]
                      (= d.name name))))

(fn find-device-by-name [devices name]
  (-?>> (find-device-idx-by-name devices name) (. devices)))

(fn get-default-sink-name [cb]
  (spawn.easy_async "pactl get-default-sink"
                    (fn [stdout _ _ _]
                      (cb (stdout:gsub "\n$" "")))))

(fn get-default-source-name [cb]
  (spawn.easy_async "pactl get-default-source"
                    (fn [stdout _ _ _]
                      (cb (stdout:gsub "\n$" "")))))

(fn get-sink-by-name [name cb]
  (get-sinks (fn [sinks]
               (cb (find-device-by-name sinks name)))))

(fn get-source-by-name [name cb]
  (get-sources (fn [sources]
                 (cb (find-device-by-name sources name)))))

(fn get-default-sink [cb]
  (get-default-sink-name (fn [n]
                           (get-sink-by-name n cb))))

(fn get-default-source [cb]
  (get-default-source-name (fn [n]
                             (get-source-by-name n cb))))

(fn set-default-sink [sink-name]
  (spawn.spawn [:pactl :set-default-sink sink-name] false))

(fn set-default-source [source-name]
  (spawn.spawn [:pactl :set-default-source source-name] false))

(fn find-suitable-idx [idx offset n]
  (if idx
      (let [new-idx (% (+ idx offset) n)]
        (if (= new-idx 0)
            n
            new-idx))
      (> n 0)
      1))

(fn activate-sink-by-offset [offset]
  (let [cb (fn [default-sink-name sinks]
             (let [idx (find-device-idx-by-name sinks default-sink-name)
                   new-idx (find-suitable-idx idx offset (length sinks))]
               (when new-idx
                 (set-default-sink (. sinks new-idx :name)))))]
    (get-default-sink-name (fn [n]
                             (get-sinks (fn [sinks] (cb n sinks)))))))

(fn activate-source-by-offset [offset]
  (let [cb (fn [default-source-name sources]
             (let [idx (find-device-idx-by-name sources default-source-name)
                   new-idx (find-suitable-idx idx offset (length sources))]
               (when new-idx
                 (set-default-source (. sources new-idx :name)))))]
    (get-default-source-name (fn [n]
                               (get-sources (fn [sources] (cb n sources)))))))

(fn get-sink-volume-perc [info]
  (let [volumes (icollect [_ v (pairs info.volume)]
                  (v.value_percent:gsub "%%$" ""))
        total (accumulate [acc 0 _ v (ipairs volumes)]
                (+ acc (tonumber v)))
        n (length volumes)]
    (if (> n 0) (math.floor (/ total n)) 0)))

(fn set-default-sink-volume-perc [vol]
  (let [vol (clamp vol 0 volume-max)]
    (spawn.spawn [:pactl :set-sink-volume "@DEFAULT_SINK@" (.. vol "%")])))

(fn get-device-icon-name [info]
  (. info.properties :device.icon_name))

(fn get-device-description [info]
  (. info.properties :device.description))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local icon-theme (Gtk.IconTheme.get_default))
(local icon-flags [Gtk.IconLookupFlags.GENERIC_FALLBACK])

(fn lookup-icon [n size]
  (icon-theme:lookup_icon n size icon-flags))

(fn load-icon [i size]
  (let [i (if (= (type i) :string)
              (lookup-icon i size)
              i)]
    (i:load_surface)))

(local default-icons {:muted-mic :microphone-sensitivity-muted
                      :normal-mic :microphone-sensitivity-high
                      :no-device :error})

(local default-mixer :pavucontrol)
(local default-theme {:fg_color "#cccccc"
                      :bg_color "#333333"
                      :muted_fg_color "#ff3333"
                      :muted_bg_color "#333333"
                      :icon-size 32})

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn get-device-icon [info ctx]
  (-> (or (. ctx.theme.icons info.name) (get-device-icon-name info))
      (load-icon ctx.theme.icon-size)))

(fn set-volume-display [{: volume-widget} volume]
  (volume-widget:set_value volume))

(fn set-no-device-display [{: volume-widget : theme : device-widget}]
  (volume-widget:set_color theme.fg_color)
  (device-widget:set_image (load-icon theme.icons.no-device theme.icon-size)))

(fn set-muted-display [{: volume-widget : theme} muted?]
  (volume-widget:set_color (if muted?
                               theme.muted_fg_color
                               theme.fg_color))
  (volume-widget:set_background_color (if muted?
                                          theme.muted_bg_color
                                          theme.bg_color)))

(fn set-no-mic-device-display [{: mic-widget : mic-status-widget : theme}]
  (let [icon (load-icon theme.icons.no-device theme.icon-size)]
    (mic-widget:set_image icon)
    (mic-status-widget:set_image icon)))

(fn set-mic-muted-display [{: mic-status-widget : theme} muted?]
  (let [icon (if muted?
                 theme.icons.muted-mic
                 theme.icons.normal-mic)]
    (mic-status-widget:set_image (load-icon icon theme.icon-size))))

(fn sync-display-with-sink [ctx sink-info]
  (if sink-info
      (do
        (set-volume-display ctx (get-sink-volume-perc sink-info))
        (set-muted-display ctx (muted? sink-info))
        (ctx.device-widget:set_image (get-device-icon sink-info ctx)))
      (set-no-device-display ctx)))

(fn sync-display-with-source [ctx source-info]
  (if source-info
      (do
        (set-mic-muted-display ctx (muted? source-info))
        (ctx.mic-widget:set_image (get-device-icon source-info ctx)))
      (set-no-mic-device-display ctx)))

(fn clear-menu [menu]
  (for [idx (length menu.items) 1 -1]
    (menu:delete idx)))

(fn volume-up [ctx]
  (set-default-sink-volume-perc (+ (ctx.volume-widget:get_value) volume-step)))

(fn volume-down [ctx]
  (set-default-sink-volume-perc (- (ctx.volume-widget:get_value) volume-step)))

(fn toggle-muted []
  (spawn.spawn [:pactl :set-sink-mute "@DEFAULT_SINK@" :toggle]))

(fn toggle-mic-muted []
  (spawn.spawn [:pactl :set-source-mute "@DEFAULT_SOURCE@" :toggle]))

(fn fill-in-defaults [args]
  (let [args (or args {})
        theme (gears.table.join default-theme beautiful.pa_widget args.theme)
        icons (collect [k v (pairs (gears.table.join default-icons theme.icons))]
                (values k (lookup-icon v theme.icon-size)))]
    (set theme.icons icons)
    (set args.theme theme)
    (set args.mixer (or args.mixer default-mixer))
    args))

(fn add-button [w b f]
  (w:add_button (awful.button [] b f)))

(fn fill-sinks-menu [menu sinks ctx]
  (clear-menu menu)
  (each [_ sink (ipairs sinks)]
    (menu:add {:text (get-device-description sink)
               :icon (get-device-icon sink ctx)
               :cmd (fn [] (set-default-sink sink.name) false)})))

(fn fill-sources-menu [menu sources ctx]
  (clear-menu menu)
  (each [_ source (ipairs sources)]
    (menu:add {:text (get-device-description source)
               :icon (get-device-icon source ctx)
               :cmd (fn [] (set-default-source source.name) false)})))

(fn full-sync [ctx]
  (get-sinks (fn [sinks]
               (get-default-sink-name (fn [n]
                                        (let [d (find-device-by-name sinks n)]
                                          (sync-display-with-sink ctx d))))
               (fill-sinks-menu ctx.device-menu sinks ctx)))
  (get-sources (fn [sources]
                 (get-default-source-name (fn [n]
                                            (let [d (find-device-by-name sources
                                                                         n)]
                                              (sync-display-with-source ctx d))))
                 (fill-sources-menu ctx.mic-menu sources ctx))))

(fn new [args]
  (when (not json-status)
    (naughty.notify {:title "CJSON module required"
                     :text "The audio widgets can't work without the `cjson` module. Try installing e.g. `lua-cjson`."
                     :preset naughty.config.presets.critical}))
  (let [args (fill-in-defaults args)
        ctx {:theme args.theme
             :device-path->menu-item {}
             :mic-path->menu-item {}}
        volume-up (fn [] (volume-up ctx))
        volume-down (fn [] (volume-down ctx))
        device-menu (awful.menu {:items []})
        device-widget (doto (awful.widget.launcher {:image (load-icon args.theme.icons.no-device
                                                                      args.theme.icon-size)
                                                    :menu device-menu})
                        (add-button 4 (fn [] (activate-sink-by-offset -1)))
                        (add-button 5 (fn [] (activate-sink-by-offset 1))))
        volume-widget (doto (wibox.widget {:widget (wibox.widget.progressbar)
                                           :min_value 0
                                           :max_value volume-max
                                           :forced_width 100})
                        (add-button 1 toggle-muted)
                        (add-button 3
                                    (fn []
                                      (when args.mixer (awful.spawn args.mixer))))
                        (add-button 4 volume-up)
                        (add-button 5 volume-down))
        mic-menu (awful.menu {:items []})
        mic-widget (doto (awful.widget.launcher {:image (load-icon args.theme.icons.no-device
                                                                   args.theme.icon-size)
                                                 :menu mic-menu})
                     (add-button 4 (fn [] (activate-source-by-offset -1)))
                     (add-button 5 (fn [] (activate-source-by-offset 1))))
        mic-context-menu (when args.mic-context-menu-items
                           (awful.menu {:items args.mic-context-menu-items}))
        mic-status-widget (doto (awful.widget.button {:image (load-icon args.theme.icons.normal-mic
                                                                        args.theme.icon-size)})
                            (add-button 1 toggle-mic-muted)
                            (add-button 3
                                        (fn []
                                          (when mic-context-menu
                                            (mic-context-menu:toggle)))))]
    (tset ctx :volume-widget volume-widget)
    (tset ctx :device-menu device-menu)
    (tset ctx :device-widget device-widget)
    (tset ctx :mic-menu mic-menu)
    (tset ctx :mic-widget mic-widget)
    (tset ctx :mic-status-widget mic-status-widget)
    (full-sync ctx)
    (awesome.connect_signal :exit
                            (fn [_]
                              (when ctx.pactl-pid
                                (awesome.kill ctx.pactl-pid 9))))
    (spawn-pactl-subscribe ctx
                           {;; Volume/muting.
                            :on-sink-change (fn []
                                              (get-default-sink (fn [default-sink]
                                                                  (sync-display-with-sink ctx
                                                                                          default-sink))))
                            ;; Muting.
                            :on-source-change (fn []
                                                (get-default-source (fn [default-source]
                                                                      (sync-display-with-source ctx
                                                                                                default-source))))
                            ;; Adding/removing a device, changing the default device.
                            :on-server-change (fn []
                                                (full-sync ctx))})
    {: device-widget
     : volume-widget
     : mic-widget
     : mic-status-widget
     : volume-up
     : volume-down
     : toggle-muted
     : toggle-mic-muted}))

(fn module.mt.__call [_mt ...]
  (new ...))

(setmetatable module module.mt)
