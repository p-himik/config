(local awful (require :awful))
(local beautiful (require :beautiful))
(local gears (require :gears))
(local lgi (require :lgi))
(local naughty (require :naughty))
(local wibox (require :wibox))

(local pulseaudio-dbus (let [(ok? val-or-err) (pcall #(require :pulseaudio_dbus))]
                         (if ok?
                           val-or-err
                           nil)))

(local icon-theme (lgi.Gtk.IconTheme.get_default))
(local icon-flags [lgi.Gtk.IconLookupFlags.GENERIC_FALLBACK])

(fn lookup-icon [n size]
  (icon-theme:lookup_icon n size icon-flags))

(fn load-icon [i size]
  (let [i (if (= (type i) :string)
            (lookup-icon i size)
            i)]
    (i:load_surface)))

(local default-icons {:muted-mic  :microphone-sensitivity-muted
                      :normal-mic :microphone-sensitivity-high
                      :no-device  :error})
(local default-mixer "pavucontrol")
(local default-theme {:fg_color       "#cccccc"
                      :bg_color       "#333333"
                      :muted_fg_color "#ff3333"
                      :muted_bg_color "#333333"
                      :icon-size      32})

(local module {:mt {}})

(fn connect-to-pulseaudio []
  (let [address (pulseaudio-dbus.get_address)]
    (pulseaudio-dbus.get_connection address)))

(fn get-device-icon [device ctx]
  (-> (or (. ctx.theme.icons device.Name)
          (. device.PropertyList :device.icon_name))
      (load-icon ctx.theme.icon-size)))

(fn set-volume-display [{: volume-widget} volume]
  (volume-widget:set_value (/ volume 100)))

(fn set-no-device-display [{: volume-widget : theme : device-widget}]
  (volume-widget:set_color theme.fg_color)
  (device-widget:set_image (load-icon theme.icons.no-device theme.icon-size)))

(fn set-muted-display [{: volume-widget : theme}]
  (volume-widget:set_color theme.muted_fg_color)
  (volume-widget:set_background_color theme.muted_bg_color))

(fn set-unmuted-display [{: volume-widget : theme}]
  (volume-widget:set_color theme.fg_color)
  (volume-widget:set_background_color theme.bg_color))

(fn set-no-mic-device-display [{: mic-widget : mic-status-widget : theme}]
  (let [icon (load-icon theme.icons.no-device theme.icon-size)]
    (mic-widget:set_image icon)
    (mic-status-widget:set_image icon)))

(fn set-mic-muted-display [{: mic-status-widget : theme}]
  (mic-status-widget:set_image (load-icon theme.icons.muted-mic theme.icon-size)))

(fn set-mic-unmuted-display [{: mic-status-widget : theme}]
  (mic-status-widget:set_image (load-icon theme.icons.normal-mic theme.icon-size)))

(fn sync-display-with-sink [ctx sink]
  (if (sink:is_muted)
    (set-muted-display ctx)
    (let [v (. (sink:get_volume_percent) 1)]
      (set-unmuted-display ctx)
      (set-volume-display ctx v)))
  (ctx.device-widget:set_image (get-device-icon sink ctx)))

(fn sync-display-with-source [ctx source]
  (if (source:is_muted)
    (set-mic-muted-display ctx)
    (set-mic-unmuted-display ctx))
  (ctx.mic-widget:set_image (get-device-icon source ctx)))

(fn get-device [ctx path]
  (let [volume-step 2
        volume-max 100]
    (pulseaudio-dbus.get_device ctx.connection path volume-step volume-max)))

;; Forward declaration.
(var ensure-connection nil)

(fn get-current-sink [ctx]
  (let [{: core} (ensure-connection ctx)]
    (-?>> (or (core:get_fallback_sink)
              (?. (core:get_sinks) 1))
          (get-device ctx))))

(fn get-current-source [ctx]
  (let [{: core} (ensure-connection ctx)]
    (-?>> (or (core:get_fallback_source)
              (?. (core:get_sources) 1))
          (get-device ctx))))

(fn connect-sink [ctx path]
  (when path
    (let [device (get-device ctx path)]
      (when device.IsHardwareDevice
        (let [item (ctx.device-menu:add {:text (. device.PropertyList :device.description)
                                         :cmd  (fn []
                                                 (ctx.core:set_fallback_sink device.object_path))
                                         :icon (get-device-icon device ctx)})]
          (tset ctx.device-path->menu-item device.object_path item))
        (when device.signals.VolumeUpdated
          (device:connect_signal (fn [this _volume]
                                   (match (get-current-sink ctx)
                                     sink (when (= this.object_path sink.object_path)
                                             (sync-display-with-sink ctx sink))
                                     _ (set-no-device-display ctx)))
                                :VolumeUpdated))
        (when device.signals.MuteUpdated
          (device:connect_signal (fn [this _is-mute]
                                   (match (get-current-sink ctx)
                                     sink (when (= this.object_path sink.object_path)
                                             (sync-display-with-sink ctx sink))))
                                :MuteUpdated))))))

(fn disconnect-sink [ctx path]
  (let [menu-item (. ctx.device-path->menu-item path)]
    (ctx.device-menu:delete menu-item)
    (tset ctx.device-path->menu-item path nil)))

(fn connect-source [ctx path]
  (when path
    (let [device (get-device ctx path)]
      (when device.IsHardwareDevice
        (let [item (ctx.mic-menu:add {:text (. device.PropertyList :device.description)
                                      :cmd  (fn []
                                              (ctx.core:set_fallback_source device.object_path))
                                      :icon (get-device-icon device ctx)})]
          (tset ctx.mic-path->menu-item device.object_path item))
        (when device.signals.MuteUpdated
          (device:connect_signal (fn [this _is-mute]
                                   (match (get-current-source ctx)
                                     source (when (= this.object_path source.object_path)
                                               (sync-display-with-source ctx source))
                                     _ (set-no-mic-device-display ctx)))
                                :MuteUpdated))))))

(fn disconnect-source [ctx path]
  (let [menu-item (. ctx.mic-path->menu-item path)]
    (ctx.mic-menu:delete menu-item)
    (tset ctx.mic-path->menu-item path nil)))

(lambda listen-for-signal [{: core} signal ?f]
  (core:ListenForSignal (.. :org.PulseAudio.Core1. signal)
                        (if ?f [core.object_path] []))
  (when ?f
    (core:connect_signal ?f signal)))

(fn clear-menu [menu]
  (for [idx (length menu.items) 1 -1]
    (menu:delete idx)))

(set ensure-connection
  (lambda [ctx ?connection]
    (when (or (= ctx.connection nil)
              (ctx.connection:is_closed))
      (set ctx.connection (or ?connection (connect-to-pulseaudio)))
      (set ctx.core (pulseaudio-dbus.get_core ctx.connection))
      ;; We check the device in the listeners.
      (listen-for-signal ctx :Device.VolumeUpdated)
      (listen-for-signal ctx :Device.MuteUpdated)

      (listen-for-signal ctx :NewSink
                             (fn [_ path]
                               (connect-sink ctx path)))
      (listen-for-signal ctx :SinkRemoved
                             (fn [_ path]
                               (disconnect-sink ctx path)))
      (listen-for-signal ctx :FallbackSinkUpdated
                             (fn [_ path]
                               (let [sink (get-device ctx path)]
                                 (sync-display-with-sink ctx sink))))
      (listen-for-signal ctx :FallbackSinkUnset
                             (fn [_]
                               (set-no-device-display ctx)))
      (listen-for-signal ctx :NewSource
                             (fn [_ path]
                               (connect-source ctx path)))
      (listen-for-signal ctx :SourceRemoved
                             (fn [_ path]
                               (disconnect-source ctx path)))
      (listen-for-signal ctx :FallbackSourceUpdated
                             (fn [_ path]
                               (let [source (get-device ctx path)]
                                 (sync-display-with-source ctx source))))
      (listen-for-signal ctx :FallbackSourceUnset
                             (fn [_]
                               (set-no-mic-device-display ctx)))

      (clear-menu ctx.device-menu)
      (each [_ sink-path (ipairs (ctx.core:get_sinks))]
        (connect-sink ctx sink-path))
      (clear-menu ctx.mic-menu)
      (each [_ source-path (ipairs (ctx.core:get_sources))]
        (connect-source ctx source-path))
      (match (get-current-sink ctx)
        sink (sync-display-with-sink ctx sink)
        _ (set-no-device-display ctx))
      (match (get-current-source ctx)
        source (sync-display-with-source ctx source)
        _ (set-no-mic-device-display ctx)))
    ctx))

(fn volume-up [ctx]
  (-?> (get-current-sink ctx) (: :volume_up)))

(fn volume-down [ctx]
  (-?> (get-current-sink ctx) (: :volume_down)))

(fn toggle-muted [ctx]
  (-?> (get-current-sink ctx) (: :toggle_muted)))

(fn toggle-mic-muted [ctx]
  (-?> (get-current-source ctx) (: :toggle_muted)))

(fn fill-in-defaults [args]
  (let [args (or args {})
        theme (gears.table.join default-theme beautiful.pa_widget args.theme)
        icons (collect [k v (pairs (gears.table.join default-icons theme.icons))]
                (values k (lookup-icon v theme.icon-size)))]
    (set theme.icons icons)
    (set args.theme theme)
    (set args.mixer (or args.mixer default-mixer))
    args))

(fn activate-sink-by-offset [ctx offset]
  (let [menu ctx.device-menu]
    (match (get-current-sink ctx)
      sink (let [item (. ctx.device-path->menu-item sink.object_path)
                 idx (gears.table.hasitem menu.items item)
                 n (length menu.items)
                 new-idx (% (+ idx offset) n)
                 new-idx (if (= new-idx 0) n new-idx)]
             (when (not= idx new-idx)
              (menu:exec new-idx)))
      _ (menu:exec 1))))

(fn activate-source-by-offset [ctx offset]
  (let [menu ctx.mic-menu]
    (match (get-current-source ctx)
      source (let [item (. ctx.mic-path->menu-item source.object_path)
                   idx (gears.table.hasitem menu.items item)
                   n (length menu.items)
                   new-idx (% (+ idx offset) n)
                   new-idx (if (= new-idx 0) n new-idx)]
               (when (not= idx new-idx)
                (menu:exec new-idx)))
      _ (menu:exec 1))))

(fn add-button [w b f]
  (when f
    (w:add_button (awful.button [] b f))))

(fn new [args]
  (match (pcall connect-to-pulseaudio)
    (false error)
    (naughty.notify {:title  "PulseAudio is not available"
                     :text   error
                     :preset naughty.config.presets.critical})

    (true connection)
    (let [args (fill-in-defaults args)
          device-menu (awful.menu {:items []})
          device-widget (awful.widget.launcher {:image (load-icon args.theme.icons.no-device args.theme.icon-size)
                                                :menu  device-menu})
          volume-widget (wibox.widget {:widget       (wibox.widget.progressbar)
                                       :min_value    0
                                       :max_value    1
                                       :forced_width 100})
          mic-menu (awful.menu {:items []})
          mic-widget (awful.widget.launcher {:image (load-icon args.theme.icons.no-device args.theme.icon-size)
                                             :menu  mic-menu})
          mic-context-menu (when args.mic-context-menu-items
                             (awful.menu {:items args.mic-context-menu-items}))
          mic-status-widget (awful.widget.button {:image (load-icon args.theme.icons.normal-mic args.theme.icon-size)})
          ctx (-> {:theme args.theme
                   :device-path->menu-item {}
                   :mic-path->menu-item {}
                   : volume-widget
                   : device-menu
                   : device-widget
                   : mic-menu
                   : mic-widget
                   : mic-status-widget}
                  (ensure-connection connection))]
      (doto device-widget
        (add-button 4 (fn [] (activate-sink-by-offset ctx -1)))
        (add-button 5 (fn [] (activate-sink-by-offset ctx 1))))
      (doto volume-widget
        (add-button 1 (fn [] (toggle-muted ctx)))
        (add-button 3 (when args.mixer (fn [] (awful.spawn args.mixer))))
        (add-button 4 (fn [] (volume-up ctx)))
        (add-button 5 (fn [] (volume-down ctx))))
      (doto mic-widget
        (add-button 4 (fn [] (activate-source-by-offset ctx -1)))
        (add-button 5 (fn [] (activate-source-by-offset ctx 1))))
      (doto mic-status-widget
        (add-button 1 (fn [] (toggle-mic-muted ctx)))
        (add-button 3 (when mic-context-menu (fn [] (mic-context-menu:toggle)))))
      {: device-widget
       : volume-widget
       : mic-widget
       : mic-status-widget
       :volume-up        (fn [] (volume-up ctx))
       :volume-down      (fn [] (volume-down ctx))
       :toggle-muted     (fn [] (toggle-muted ctx))
       :toggle-mic-muted (fn [] (toggle-mic-muted ctx))})))

(fn module.mt.__call [_mt ...]
  (new ...))

(setmetatable module module.mt)
