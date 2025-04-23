(local awful (require :awful))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local {: modkey : cmds} (require :rc.common))
(local cw (require :rc.widgets.common))
(local menubar (require :menubar))
(local tags (require :rc.tags))

(local b awful.button)
(local k awful.key)

(fn spawn [cmd]
  (let [t (type cmd)]
    (if (= t :function) (cmd)
        (= t :string) (awful.spawn cmd)
        (error (.. "Unknown cmd type: " t)))))

(awful.mouse.append_global_mousebindings [(b [] 3 (fn [] (cw.main-menu:toggle)))
                                          (b [] 4 awful.tag.viewnext)
                                          (b [] 5 awful.tag.viewprev)
                                          (b [modkey] 8
                                             (fn []
                                               (spawn "goldendict \"`xclip -o`\"")))])

(awful.keyboard.append_global_keybindings [(k [] :F1 (fn [])
                                              {:description "disable the annoying F1 help"
                                               :group :client})
                                           (k [] "#126"
                                              (fn []
                                                (spawn cmds.switch-dp-monitor))
                                              {:description "switch monitor (plus-minus sign, Fn+F5)"
                                               :group :awesome})
                                           (k [modkey :Control] :t
                                              (fn []
                                                (spawn cmds.jetbrains-idea))
                                              {:description "launch JetBrains IDEA"
                                               :group :launcher})
                                           (k [modkey :Control :Mod1] :d
                                              (fn [] (spawn :goldendict))
                                              {:description "launch GoldenDict"
                                               :group :launcher})
                                           (k [modkey] :Return
                                              (fn [] (spawn cmds.terminal))
                                              {:description "open a terminal"
                                               :group :launcher})
                                           (k [modkey] :Tab
                                              (fn []
                                                (awful.client.focus.history.previous)
                                                (-?> client.focus (: :raise)))
                                              {:description "go back"
                                               :group :client})
                                           (k [modkey] :c
                                              (cw.mk-client-menu-toggle-fn true)
                                              {:description "select client"
                                               :group :client})
                                           (k [] :XF86AudioRaiseVolume
                                              cw.pulse.volume-up)
                                           (k [] :XF86AudioLowerVolume
                                              cw.pulse.volume-down)
                                           (k [] :XF86AudioMute
                                              cw.pulse.toggle-muted)
                                           (k [] :XF86AudioMicMute
                                              cw.pulse.toggle-mic-muted)
                                           (k [modkey] :Left
                                              cw.pulse.volume-down)
                                           (k [modkey] :Right
                                              cw.pulse.volume-up)
                                           (k [modkey] :Down
                                              cw.pulse.toggle-muted)
                                           (k [modkey] :Up
                                              cw.pulse.toggle-mic-muted)
                                           (k [modkey] :s
                                              hotkeys-popup.show_help
                                              {:description "show help"
                                               :group :awesome})
                                           (k [modkey] :w
                                              (fn [] (cw.main-menu:show))
                                              {:description "show main menu"
                                               :group :awesome})
                                           (k [modkey] :Escape
                                              awful.tag.history.restore
                                              {:description "go back"
                                               :group :tag})
                                           (k [] :Print
                                              (fn []
                                                (spawn cmds.screenshot-screen))
                                              {:description "screenshot screen"
                                               :group :awesome})
                                           (k [:Shift] :Print
                                              (fn []
                                                (spawn cmds.screenshot-window))
                                              {:description "screenshot window"
                                               :group :awesome})
                                           (k [:Control :Shift] :Print
                                              (fn []
                                                (spawn cmds.screenshot-selection))
                                              {:description "screenshot selection"
                                               :group :awesome})
                                           (k [modkey :Control] :r
                                              awesome.restart
                                              {:description "reload Awesome WM"
                                               :group :awesome})
                                           (k [modkey] :q
                                              (fn [] (spawn cmds.lock))
                                              {:description "lock session"
                                               :group :awesome})
                                           (k [modkey :Mod1] :q ;; Alt.
                                              (fn [] (spawn cmds.logout))
                                              {:description :logout
                                               :group :awesome})
                                           (k [modkey :Control] :q
                                              (fn [] (spawn cmds.suspend))
                                              {:description :suspend
                                               :group :awesome})
                                           (k [modkey :Control :Shift] :q
                                              (fn [] (spawn cmds.hibernate))
                                              {:description :hibernate
                                               :group :awesome})
                                           (k [modkey :Control] :j
                                              (fn []
                                                (awful.screen.focus_relative 1))
                                              {:description "focus the next screen"
                                               :group :screen})
                                           (k [modkey :Control] :k
                                              (fn []
                                                (awful.screen.focus_relative -1))
                                              {:description "focus the previous screen"
                                               :group :screen})
                                           (k [modkey] :u
                                              awful.client.urgent.jumpto
                                              {:description "jump to urgent client"
                                               :group :client})
                                           (k [modkey :Control] :n
                                              (fn []
                                                ;; Focus restored client.
                                                (-?> (awful.client.restore)
                                                     (: :activate
                                                        {:raise true
                                                         :context :key.unminimize})))
                                              {:description "restore minimized client"
                                               :group :client})
                                           (k [modkey] "."
                                              (fn [] (awful.tag.incmwfact 0.05))
                                              {:description "increase master width factor"
                                               :group :layout})
                                           (k [modkey] ","
                                              (fn []
                                                (awful.tag.incmwfact -0.05))
                                              {:description "decrease master width factor"
                                               :group :layout})
                                           (k [modkey :Control :Shift] :h
                                              (fn []
                                                (awful.tag.incnmaster 1 nil
                                                                      true))
                                              {:description "increase the number of master clients"
                                               :group :layout})
                                           (k [modkey :Control :Shift] :l
                                              (fn []
                                                (awful.tag.incnmaster -1 nil
                                                                      true))
                                              {:description "decrease the number of master clients"
                                               :group :layout})
                                           (k [modkey :Control] :h
                                              (fn []
                                                (awful.tag.incncol 1 nil true))
                                              {:description "increase the number of columns"
                                               :group :layout})
                                           (k [modkey :Control] :l
                                              (fn []
                                                (awful.tag.incncol -1 nil true))
                                              {:description "decrease the number of columns"
                                               :group :layout})
                                           (k [modkey] :space
                                              (fn [] (awful.layout.inc 1))
                                              {:description "select next layout"
                                               :group :layout})
                                           (k [modkey :Shift] :space
                                              (fn [] (awful.layout.inc -1))
                                              {:description "select previous layout"
                                               :group :layout})
                                           (k [modkey] :r
                                              (fn []
                                                (let [s (awful.screen.focused)]
                                                  (s.mypromptbox:run)))
                                              {:description "run prompt"
                                               :group :launcher})
                                           (k [modkey] :x
                                              (fn []
                                                (awful.prompt.run {:prompt "Run Lua code: "
                                                                   :textbox (let [s (awful.screen.focused)]
                                                                              s.mypromptbox.widget)
                                                                   :exe_callback awful.util.eval
                                                                   :history_path (.. (awful.util.get_cache_dir)
                                                                                     :/history_eval)}))
                                              {:description "lua execute prompt"
                                               :group :launcher})
                                           (k [modkey] :p menubar.show
                                              {:description "show the menubar"
                                               :group :launcher})])

(let [client-direction-keys [{:key :j :dir :down :desc :below}
                             {:key :k :dir :up :desc :above}
                             {:key :h :dir :left :desc "on the left"}
                             {:key :l :dir :right :desc "on the right"}]]
  (each [_ k-desc (ipairs client-direction-keys)]
    (awful.keyboard.append_global_keybindings [(k [modkey] k-desc.key
                                                  (fn []
                                                    (awful.client.focus.bydirection k-desc.dir)
                                                    (-?> client.focus
                                                         (: :raise)))
                                                  {:description (.. "focus a client "
                                                                    k-desc.desc)
                                                   :group :client})
                                               (k [modkey :Shift] k-desc.key
                                                  (fn []
                                                    (awful.client.swap.bydirection k-desc.dir))
                                                  {:description (.. "swap with a client "
                                                                    k-desc.desc)
                                                   :group :client})])))

(awful.keyboard.append_global_keybindings [(k {:modifiers [modkey]
                                               :keygroup :numrow
                                               :description "only view tag"
                                               :group :tag
                                               :on_press (fn [i]
                                                           (let [s (awful.screen.focused)]
                                                             (-?> (. s.tags i)
                                                                  tags.switch-to-tag)))})
                                           (k {:modifiers [modkey :Control]
                                               :keygroup :numrow
                                               :description "toggle tag"
                                               :group :tag
                                               :on_press (fn [i]
                                                           (let [s (awful.screen.focused)]
                                                             (-?> (. s.tags i)
                                                                  awful.tag.viewtoggle)))})
                                           (k {:modifiers [modkey :Shift]
                                               :keygroup :numrow
                                               :description "move focused client to tag"
                                               :group :tag
                                               :on_press (fn [i]
                                                           (match client.focus
                                                             c (-?> (. c.screen.tags
                                                                       i)
                                                                    c:move_to_tag)))})
                                           (k {:modifiers [modkey
                                                           :Control
                                                           :Shift]
                                               :keygroup :numrow
                                               :description "toggle focused client on tag"
                                               :group :tag
                                               :on_press (fn [i]
                                                           (match client.focus
                                                             c (-?> (. c.screen.tags
                                                                       i)
                                                                    c:toggle_tag)))})])
