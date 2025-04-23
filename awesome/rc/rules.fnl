;; Rules to apply to new clients (through the "manage" signal).
;; (awful.ewmh.add_activate_filter (fn [c] false))
;; Use `xprop WM_STATE WM_HINTS WM_TRANSIENT_FOR WM_PROTOCOLS WM_CLASS WM_CLIENT_LEADER WM_NAME WM_NORMAL_HINTS`
;; to extract common useful properties.
(local awful (require :awful))
(local beautiful (require :beautiful))
(local gears (require :gears))
(local {: modkey} (require :rc.common))
(local ruled (require :ruled))
(local tags (require :rc.tags))

;; Taken from https://github.com/alfunx/.dotfiles/blob/master/.config/awesome/config/rules.lua
;; placement, that should be applied after setting x/y/width/height/geometry
;; TODO: Check and remove after https://github.com/awesomeWM/awesome/issues/2497 is fixed
(fn awful.rules.delayed_properties.delayed_placement [c value props]
  (when props.delayed_placement
    (awful.rules.extra_properties.placement c props.delayed_placement props)))

(local rules [
  {:id :global
   :rule {}
   :properties {:border_width beautiful.border_width
                :border_color beautiful.border_normal
                :focus awful.client.focus.filter
                :raise true
                :screen awful.screen.preferred
                :placement (+ awful.placement.no_overlap awful.placement.no_offscreen)
                :size_hints_honor false}}
  {:id :floating
   :rule_any {:instance [
                "DTA" ;; Firefox addon DownThemAll.
                "copyq" ;; Includes session name in class.
              ]
              :class [
                "Arandr"
                "Gpick"
                "Kruler"
                "MessageWin" ;; kalarm.
                "Sxiv"
                "Wpa_gui"
                "pinentry"
                "veromix"
                "xtightvncviewer"
              ]
              :name [
                "Event Tester" ;; xev.
              ]
              :role [
                "AlarmWindow" ;; Thunderbird's calendar.
                "gimp-toolbox"
                "gimp-dock"
                ;"pop-up" ;; e.g. Google Chrome's (detached) Developer Tools.
              ]}
   :properties {:floating true}}
  {:rule {:class "Mate-panel"
          :name "Bottom Panel"}
   :properties {:focusable false
                :ontop true}
                :border_width 0
                :respect_rule_border true}
  {:rule {:class "albert"}
   :properties {:ontop true
                :border_width 0
                :floating true
                :respect_rule_border true}}
  {:id :on-top
   :rule_any {:role [
                "gimp-toolbox"
                "gimp-dock"
              ]}
   :properties {:ontop true}}
  {:id :maximized
   :rule_any {:class ["discord" "whatsdesk" "Signal"]}
   :properties {:maximized true}}

  {:rule {:class "Pavucontrol"}
   :properties {:floating true
                :delayed_placement awful.placement.centered}}
  {:rule {:name "Export Image as JPEG"}
   :properties {:placement awful.placement}}
  {:rule {:class "^jetbrains-"
          ;; Find class or file dialog.
          :name "^ $"}
   :properties {:prevent_auto_unfocus true
                :placement awful.placement.centered}}
  {;; IDEA starting splash screen.
   :rule {;; For some reason, using `^$` does not work here in Awesome v4.3-219.
          ;; But it works in other places *shrug*.
          :class "jetbrains-idea"
          :name "^win"}
   :properties {:floating true
                :focusable false}}
  {:rule {:class "^insync"
          :name "^Insync$"}
   :properties {:prevent_auto_unfocus true
                :floating true
                :maximized false
                :placement awful.placement.top_right}}
  {:rule {;; The main Slack window is named like "Slack | %channel/user% | %server%".
          ;; The call popup is named just "Slack | mini panel", and it requests to skip taskbar.
          ;; The other difference is that it has
          ;; `NET_WM_WINDOW_TYPE(ATOM) = _NET_WM_WINDOW_TYPE_CALLS-MINI-PANEL`
          ;; where the main window has
          ;; `NET_WM_WINDOW_TYPE(ATOM) = _NET_WM_WINDOW_TYPE_NORMAL`
          ;; but I'm not sure how to use it.
          :name "Slack | mini panel"}
   :properties {:skip_taskbar true
                :focusable false
                :floating true
                :ontop true}}
  {:rule {:class "GoldenDict"}
   :properties {:floating true
                :placement awful.placement.bottom}}
  {:rule {:name  "^Special Offers$"
          :class "^steam$"}
   :callback (fn [c] (c:kill))}
  {:rule {:name  "^Steam %- News$"
          :class "^Steam$"}
   :callback (fn [c]
               ;; Can't kill the window immediately as it sometimes makes Steam misbehave.
               (gears.timer {:timeout     0.1
                             :autostart   true
                             :single_shot true
                             :callback    (fn [] (c:kill))} ))}
  {:rule_any {:class ["^steam" "^Steam$"]}
   :properties {:maximized true}}
  {:rule {:name "LibGDX_game_development"}
   :properties {:floating true
                :ontop true
                :delayed_placement awful.placement.bottom_right}}
])

(each [_ t (ipairs tags.tag-specs)]
  (when t.classes
    (each [_ c (ipairs t.classes)]
      (table.insert rules {:rule       {:class c :type :normal}
                           :properties {:screen 1 :tag t.name}}))))

(ruled.client.connect_signal :request::rules (fn [] (ruled.client.append_rules rules)))

(client.connect_signal
  :request::activate
  (fn [c context hints]
    ;; Rules don't get triggered for an already managed client,
    ;; so we have to use signals to simulate such rules.
    (when (= c.class "GoldenDict")
      (let [s (awful.screen.focused)]
        (match s.selected_tag
          t (when (not= t c.first_tag)
              (c:move_to_tag t)))))))
