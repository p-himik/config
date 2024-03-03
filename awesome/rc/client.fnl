(local awful (require :awful))
(local beautiful (require :beautiful))
(local gears (require :gears))
(local {: modkey} (require :rc.common))

(fn update-borders [s]
  ;; Based on https://github.com/awesomeWM/awesome/issues/2518#issuecomment-500389134.
  (when (?. s :selected_tag)
    (let [ln s.selected_tag.layout.name
          max? (or (= ln :max) (= ln :fullscreen))
          only-one? (= (length s.tiled_clients) 1)
          useless-border? (or max? only-one?)]
      (each [_ c (ipairs s.clients)]
        (set c.border_width
          (if (or c.maximized
                  (not c.focusable)
                  (and useless-border? (not c.floating)))
            0
            beautiful.border_width))))))

(fn connect-props-signals [lib props f]
  (each [_ prop (ipairs props)]
    (lib.connect_signal (.. "property::" prop) f)))

(fn update-borders-by-client [c]
  (when c
    (update-borders c.screen)))

(connect-props-signals client
                       [:floating :fullscreen :maximized_vertical
                        :maximized_horizontal :maximized :minimized :hidden]
                       update-borders-by-client)

(each [_ sg (ipairs [:list :manage])]
  (client.connect_signal sg update-borders-by-client))

(client.connect_signal :property::screen (fn [c old-screen]
                                           (update-borders-by-client c)
                                           (update-borders old-screen)))

(connect-props-signals tag
                       [:selected :activated :tagged]
                       (fn [t]
                         (update-borders t.screen)))

;; Signal function to execute when a new client appears.
(client.connect_signal
  :manage
  (fn [c]
    (if awesome.startup
      (when (and (not c.size_hints.user_position)
                 (not c.size_hints.program_position))
        ;; Prevent clients from being unreachable after sceen count changes.
        (awful.placement.no_offscreen c))
      ;; Set the window at the slave,
      ;; i.e. put it at the end of others instead of setting it master.
      (awful.client.setslave c))))

(var *focus-follows-mouse* true)

(fn refocus-client [c]
  ;; Enable sloppy focus, so that focus follows mouse.
  (when (and *focus-follows-mouse*
             (not= (awful.layout.get c.screen) awful.layout.suit.magnifier)
             (awful.client.focus.filter c))
    (set client.focus c)))

(client.connect_signal :mouse::enter refocus-client)

(fn check-prevent-auto-unfocus [c]
  ;; Prevent mouse from leaving a marked client.
  (set *focus-follows-mouse* (not c.prevent_auto_unfocus)))

(client.connect_signal :focus check-prevent-auto-unfocus)
(client.connect_signal :unfocus check-prevent-auto-unfocus)

(fn delay-refocus-client-under-mouse []
  ;; It's needed to focus a client that's under mouse right after we change a tag's layout.
  (gears.timer {:timeout     0.01
                :autostart   true
                :single_shot true
                :callback    (fn []
                               (-?> mouse.current_client refocus-client))}))

;; (screen.connect_signal :tag::history::update delay-refocus-client-under-mouse)

(client.connect_signal :focus (fn [c]
                                (set c.border_color beautiful.border_focus)))
(client.connect_signal :unfocus (fn [c]
                                  (set c.border_color beautiful.border_normal)))

;; This adds the default Awesome 3.5 behavior when adding/removing a screen.
;; See https://github.com/awesomeWM/awesome/issues/1382.
(screen.connect_signal :removed awesome.restart)
(screen.connect_signal :added awesome.restart)

(local b awful.button)
(local k awful.key)

(client.connect_signal
  :request::default_mousebindings
  (fn []
    (awful.mouse.append_client_mousebindings
      [(b [] 1 (fn [c] (c:activate {:context :mouse_click})))
       (b [modkey] 1 (fn [c] (c:activate {:context :mouse_click :action :mouse_move})))
       (b [modkey] 3 (fn [c] (c:activate {:context :mouse_click :action :mouse_resize})))
       ;(b [] 8 (fn [c] (awful.spawn "goldendict \"`xclip -o`\"")))
       ])))

(client.connect_signal
  :request::default_keybindings
  (fn []
    (awful.keyboard.append_client_keybindings
      [(k [modkey :Shift] :c
          (fn [c] (c:kill))
          {:description "close" :group :client})
       (k [modkey :Control] :space
          awful.client.floating.toggle
          {:description "toggle floating" :group :client})
       (k [modkey :Control] :Return
          (fn [c] (c:swap (awful.client.getmaster)))
          {:description "move to master" :group :client})
       (k [modkey] :o
          (fn [c] (c:move_to_screen))
          {:description "move to screen" :group :client})
       (k [modkey] :t
          (fn [c] (set c.ontop (not c.ontop)))
          {:description "toggle keep on top" :group :client})
       (k [modkey] :n
          (fn [c]
            ;; The client currently has the input focus, so it cannot be
            ;; minimized, since minimized clients can't have the focus.
            (set c.minimized true))
          {:description "minimize" :group :client})
       (k [modkey] :m
          (fn [c]
            (set c.maximized (not c.maximized))
            ;; TODO: Remove when https://github.com/awesomeWM/awesome/issues/1692 is fixed.
            (when (and client.focus
                       (not client.focus.fullscreen)
                       (not c.maximized))
              (set client.focus.ignore_border_width false)
              (set client.focus.border_width beautiful.border_width))
            (c:raise))
          {:description "maximize" :group :client})])))
