(local {: trim} (require :rc.util))
(local wibox (require :wibox))
(local lgi (require :lgi))
(local proxy (require :dbus_proxy))
(local clj (require :cljlib))

(local dbus-connection-flags lgi.Gio.DBusConnectionFlags)

;; From https://cgit.kde.org/plasma-workspace.git/tree/components/keyboardlayout/org.kde.KeyboardLayouts.xml
(local interface "org.kde.KeyboardLayouts")
(local signals ["layoutChanged" "layoutListChanged"])
;; From https://cgit.kde.org/plasma-workspace.git/tree/components/keyboardlayout/keyboardlayout.cpp
(local path "/Layouts")

(local kbd-dbus-proxy (proxy.Proxy:new {:bus proxy.Bus.SESSION
                                        :name "org.kde.keyboard"
                                        :path path
                                        :interface interface}))

(fn layout-to-img [layout-idx]
  (let [layouts (kbd-dbus-proxy:getLayoutsList)
        layout (. layouts (+ layout-idx 1) 1)]
    ;; Requires `famfamfam-flag-png` package to be installed.
    (.. "/usr/share/flags/countries/16x11/" layout  ".png")))

(local initial-img (layout-to-img (kbd-dbus-proxy:getLayout)))

(each [_ signal (ipairs signals)]
  (dbus.add_match "session" (.. "interface='" interface "',member='" signal "'")))

(fn create-widget []
  (let [widget (wibox.widget {:widget wibox.widget.imagebox
                              :image  initial-img
                              :resize true})]
    (dbus.connect_signal interface (fn [data layout-idx]
                                     (when (and (= data.path path)
                                                (clj.some #(= data.member $1) signals))
                                       (let [layout-idx (or layout-idx (kbd-dbus-proxy:getLayout))]
                                         (widget:set_image (layout-to-img layout-idx))))))
    widget))
