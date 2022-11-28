(local {: trim} (require :rc.util))
(local wibox (require :wibox))
(local lgi (require :lgi))
(local proxy (require :dbus_proxy))
(local clj (require :cljlib))
(local gears (require :gears))

(local dbus-connection-flags lgi.Gio.DBusConnectionFlags)

;; From https://cgit.kde.org/plasma-workspace.git/tree/components/keyboardlayout/org.kde.KeyboardLayouts.xml
(local interface "org.kde.KeyboardLayouts")
(local signals ["layoutChanged" "layoutListChanged"])
;; From https://cgit.kde.org/plasma-workspace.git/tree/components/keyboardlayout/keyboardlayout.cpp
(local path "/Layouts")

(var kbd-dbus-proxy nil)

(fn create-dbus-proxy []
  (proxy.Proxy:new {:bus proxy.Bus.SESSION
                    :name "org.kde.keyboard"
                    :path path
                    :interface interface}))

(fn layout-to-img [layout-idx]
  (when (and kbd-dbus-proxy layout-idx)
    (let [layouts (kbd-dbus-proxy:getLayoutsList)
          layout (. layouts (+ layout-idx 1) 1)]
      ;; Requires `famfamfam-flag-png` package to be installed.
      (.. "/usr/share/flags/countries/16x11/" layout  ".png"))))

(each [_ signal (ipairs signals)]
  (dbus.add_match "session" (.. "interface='" interface "',member='" signal "'")))

(fn create-widget []
  (let [widget (wibox.widget {:widget wibox.widget.imagebox
                              :resize true})
        set-image (fn [layout-idx]
                    (let [layout-idx (or layout-idx (-?> kbd-dbus-proxy (: :getLayout)))]
                      (widget:set_image (layout-to-img layout-idx))))]
    (dbus.connect_signal interface (fn [data layout-idx]
                                     (when (and (= data.path path)
                                                (clj.some #(= data.member $1) signals))
                                       (set-image layout-idx))))
    (gears.timer.delayed_call
      (fn []
        (when (not kbd-dbus-proxy)
          (set kbd-dbus-proxy (create-dbus-proxy)))
        (set-image nil)))
    widget))
