(local {: trim} (require :rc.util))
(local wibox (require :wibox))

;; From https://cgit.kde.org/plasma-workspace.git/tree/components/keyboardlayout/org.kde.KeyboardLayouts.xml
(local interface "org.kde.KeyboardLayouts")
(local signal "currentLayoutChanged")
(local getter "getCurrentLayout")
;; From https://cgit.kde.org/plasma-workspace.git/tree/components/keyboardlayout/keyboardlayout.cpp
(local path "/Layouts")

(fn layout-to-img [layout]
  ;; Requires `famfamfam-flag-png` package to be installed.
  (.. "/usr/share/flags/countries/16x11/" layout  ".png"))

(fn get-current-layout []
  (let [curr-layout-cmd (.. "dbus-send --print-reply=literal --dest=org.kde.kded5 "
                            path " " interface "." getter)]
    (with-open [h (io.popen curr-layout-cmd)]
      (trim (h:read "*a")))))

(local initial-img (layout-to-img (get-current-layout)))

(dbus.add_match "session" (.. "interface='" interface "',member='" signal "'"))

(fn create-widget []
  (let [widget (wibox.widget {:widget wibox.widget.imagebox
                              :image  initial-img
                              :resize true})]
    (dbus.connect_signal interface (fn [data layout]
                                     (when (and (= data.member signal)
                                                (= data.path path))
                                       (widget:set_image (layout-to-img layout)))))
    widget))
