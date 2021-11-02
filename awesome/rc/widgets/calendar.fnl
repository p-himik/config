(local {: trim} (require :rc.util))
(local calendar-popup (require :awful.widget.calendar_popup))
(local wibox (require :wibox))

(local position :tr)
(local args {:position      position
             :spacing       3
             :week_numbers  true
             :long_weekdays true})
(each [_ cell (ipairs [:normal :weeknumber :weekday :header :month :focus])]
  (tset args (.. "style_" cell) {:border_width 0}))

(fn create-widget []
  (let [box (calendar-popup.month args)]
    (doto (wibox.widget.textclock)
      (box:attach position))))
