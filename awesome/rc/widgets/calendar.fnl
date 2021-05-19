(local {: trim} (require :rc.util))
(local calendar-popup (require :awful.widget.calendar_popup))
(local wibox (require :wibox))

;; TODO: Remove when glib is updated at least to 2.59.0
;;  For the details, see https://github.com/GNOME/glib/commit/2ceb48dfc28f619b1bfe6037e5799ec9d0a0ab31
;; Return a timezone string in ISO 8601:2000 standard form (+hhmm or -hhmm)
;; The recipe at http://lua-users.org/wiki/TimeZone does not work, probably
;; because of the bug in glib.
(fn get-tzoffset []
  (with-open [h (io.popen "date +%z")]
    (trim (h:read "*a"))))

(local position :tr)
(local args {:position      position
             :spacing       3
             :week_numbers  true
             :long_weekdays true})
(each [_ cell (ipairs [:normal :weeknumber :weekday :header :month :focus])]
  (tset args (.. "style_" cell) {:border_width 0}))

(fn create-widget []
  (let [box (calendar-popup.month args)]
    (doto (wibox.widget.textclock nil nil (get-tzoffset))
      (box:attach position))))
