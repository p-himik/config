(local awful (require :awful))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local gears (require :gears))
(local {: modkey : cmds} (require :rc.common))
(local clj (require :cljlib))
(local {: main-menu : apw} (require :rc.widgets.common))
(local menubar (require :menubar))
(local tags (require :rc.tags))

(fn mk-client-menu-toggle-fn [only-current-tag?]
  (var instance nil)
  (fn [_c]
    (if (and instance instance.wibox.visible)
      (do
        (instance:hide)
        (set instance nil))
      (let [filter-fn (if only-current-tag?
                        (let [s (awful.screen.focused)
                              tags (collect [_ t (ipairs s.selected_tags)]
                                     (values t true))]
                          (fn [c]
                            (clj.some (fn [t] (. tags t)) (c:tags))))
                        (fn [_c] true))
            items {}]
        (var key 0)
        (each [c (awful.client.iterate filter-fn)]
          (let [name (or c.name "")
                name (if (< key 10)
                       (do
                         (set key (+ key 1))
                         (.. "[&" key "] " name))
                       name)
                cmd (fn []
                      (when c.valid
                        (when (not (c:isvisible))
                          (awful.tag.viewmore (c:tags) c.screen))
                        (c:emit_signal "request::activate" "menu.clients" {:raise true})))]
            (table.insert items {:text name
                                 :cmd  cmd
                                 :icon c.icon})))
        (when (not= nil (next items))
          (set instance (awful.menu.new {:theme {:width 300}
                                         :items items}))
          (instance:show)
          (instance:item_enter 1))))))

(fn refocus-centerwork-layout-main-client [screen cb]
  (each [_ t (pairs screen.tags)]
    ;; Do not do anything when switching _to_ a tag.
    (when (and t.selected (= t.layout.name :centerwork))
      (let [find-client
            (fn []
              (var tag-first-client nil)
              (or
                (clj.some (fn [c]
                            (if
                              c.sticky
                              c

                              (awful.client.focus.filter c)
                              (clj.some (fn [v]
                                          (when (= v t)
                                            (if
                                              c.maximized
                                              ;; Only use the maximized window if it's the one focused.
                                              ;; Otherwise, maximized windows from the back of the stack
                                              ;; will be brought forward.
                                              (when (= c client.focus)
                                                c)

                                              (and (= nil tag-first-client)
                                                   (not c.minimized))
                                              (set tag-first-client c))))
                                        (c:tags))))
                          (client.get screen))
                tag-first-client))

            chosen-client (find-client)]
        ;; Cannot use `awful.layout.parameters` because it returns
        ;; an empty list of clients if the tag is not selected.
        (when (?. chosen-client :focusable)
          (chosen-client:emit_signal "request::activate" "refocus-centerwork-layout-main-client")))))
  ;; Note that just directly calling `cb` or even wrapping it in `gears.timer.delayed_call`
  ;; will not work because changing focus is lazy while changing a tag is not.
  ;; Some discussion and more details: https://github.com/awesomeWM/awesome/issues/3153
  (gears.timer.start_new 0.01 cb))

(fn switch-to-tag [tag]
  (refocus-centerwork-layout-main-client tag.screen (fn [] (tag:view_only))))

(local taglist-buttons
  (let [b awful.button]
    (gears.table.join
      (b [] 1
         switch-to-tag)
      (b [modkey] 1
         (fn [t]
           (-?> client.focus (: :move_to_tag t))))
      (b [] 3
         awful.tag.viewtoggle)
      (b [modkey] 3
         (fn [t]
           (-?> client.focus (: :toggle_tag t))))
      (b [] 4
         (fn [t]
           (awful.tag.viewnext t.screen)))
      (b [] 5
         (fn [t]
           (awful.tag.viewprev t.screen))))))

(local tasklist-buttons
  (let [b awful.button]
    (gears.table.join
      (b [] 1
         (fn [c]
           (if (= c client.focus)
             (set c.minimized true)
             (c:emit_signal "request::activate" "tasklist" {:raise true}))))
      (b [] 3
         (mk-client-menu-toggle-fn false))
      (b [] 4
         (fn [_c]
           (awful.client.focus.byidx 1)))
      (b [] 5
         (fn [_c]
           (awful.client.focus.byidx -1))))))

(local global-buttons
  (let [b awful.button]
    (gears.table.join
      (b [] 3
         (fn []
           (main-menu:toggle)))
      (b [] 4
         awful.tag.viewnext)
      (b [] 5
         awful.tag.viewprev))))

(local common-global-keys
  (let [k awful.key]
    (gears.table.join
      (k [] "#126"
         (fn [] (awful.spawn.with_shell cmds.switch-dp-monitor))
         {:description "Switch monitor (plus-minus sign, Fn+F5)" :group :awesome})
      (k [modkey :Control] :t
         (fn [] (awful.spawn cmds.jetbrains-toolbox))
         {:description "Launch JetBrains Toolbox" :group :launcher})
      (k [modkey] :Return
         (fn [] (awful.spawn cmds.terminal))
         {:description "open a terminal" :group :launcher})
      (k [modkey] :Tab
         (fn []
           (awful.client.focus.history.previous)
           (-?> client.focus (: :raise)))
         {:description "go back" :group :client})
      (k [modkey] :c
         (mk-client-menu-toggle-fn true)
         {:description "select client" :group :client})

      (k [] :XF86AudioRaiseVolume apw.up)
      (k [] :XF86AudioLowerVolume apw.down)
      (k [] :XF86AudioMute apw.togglemute)
      (k [modkey] :Left apw.down)
      (k [modkey] :Right apw.up)

      (k [modkey] :s
         hotkeys-popup.show_help
         {:description "show help" :group :awesome})
      (k [modkey] :w
         (fn [] (main-menu:show))
         {:description "show main menu" :group :awesome})
      (k [modkey] :Escape
         awful.tag.history.restore
         {:description "go back" :group :tag})

      (k [] :Print
         (fn [] (awful.spawn cmds.screenshot-screen))
         {:description "screenshot screen" :group :awesome})
      (k [:Shift] :Print
         (fn [] (awful.spawn cmds.screenshot-window))
         {:description "screenshot window" :group :awesome})
      (k [:Control :Shift] :Print
         (fn [] (awful.spawn cmds.screenshot-selection))
         {:description "screenshot selection" :group :awesome})

      (k [modkey :Control] :r
         awesome.restart
         {:description "reload Awesome WM" :group :awesome})
      (k [modkey] :q
         (fn [] (awful.spawn cmds.lock))
         {:description "lock session" :group :awesome})
      (k [modkey :Mod1] :q ;; Alt.
         (fn [] (awful.spawn cmds.logout))
         {:description "logout" :group :awesome})
      (k [modkey :Control] :q
         (fn [] (awful.spawn.with_shell cmds.suspend))
         {:description "suspend" :group :awesome})
      (k [modkey :Control :Shift] :q
         (fn [] (awful.spawn cmds.hibernate))
         {:description "hibernate" :group :awesome})

      (k [modkey :Control] :j
         (fn [] (awful.screen.focus_relative 1))
         {:description "focus the next screen" :group :screen})
      (k [modkey :Control] :k
         (fn [] (awful.screen.focus_relative -1))
         {:description "focus the previous screen" :group :screen})
      (k [modkey] :u
         awful.client.urgent.jumpto
         {:description "jump to urgent client" :group :client})
      (k [modkey :Control] :n
         (fn []
           (match (awful.client.restore)
             ;; Focus restored client.
             c (do (set client.focus c)
                   (c:raise))))
         {:description "restore minimized client" :group :client})

      (k [modkey] "."
         (fn [] (awful.tag.incmwfact 0.05))
         {:description "increase master width factor" :group :layout})
      (k [modkey] ","
         (fn [] (awful.tag.incmwfact -0.05))
         {:description "decrease master width factor" :group :layout})
      (k [modkey :Control :Shift] :h
         (fn [] (awful.tag.incnmaster 1 nil true))
         {:description "increase the number of master clients" :group :layout})
      (k [modkey :Control :Shift] :l
         (fn [] (awful.tag.incnmaster -1 nil true))
         {:description "decrease the number of master clients" :group :layout})
      (k [modkey :Control] :h
         (fn [] (awful.tag.incncol 1 nil true))
         {:description "increase the number of columns" :group :layout})
      (k [modkey :Control] :l
         (fn [] (awful.tag.incncol -1 nil true))
         {:description "decrease the number of columns" :group :layout})
      (k [modkey] :space
         (fn [] (awful.layout.inc 1))
         {:description "select next layout" :group :layout})
      (k [modkey :Shift] :space
         (fn [] (awful.layout.inc -1))
         {:description "select previous layout" :group :layout})

      (k [modkey] :r
         (fn []
           (let [s (awful.screen.focused)]
             (s.mypromptbox:run)))
         {:description "run prompt" :group :launcher})
      (k [modkey] :x
         (fn []
           (awful.prompt.run {:prompt "Run Lua code: "
                              :textbox (let [s (awful.screen.focused)]
                                         s.mypromptbox.widget)
                              :exe_callback awful.util.eval
                              :history_path (.. (awful.util.get_cache_dir) "/history_eval")}))
         {:description "lua execute prompt" :group :launcher})
      (k [modkey] :p
         menubar.show
         {:description "show the menubar" :group :launcher}))))

(fn add-key! [t ...]
  (gears.table.merge t (awful.key ...)))

(local client-global-keys
  (let [client-direction-keys [{:key :j :dir :down :desc "below"}
                               {:key :k :dir :up :desc "above"}
                               {:key :h :dir :left :desc "on the left"}
                               {:key :l :dir :right :desc "on the right"}]
        t {}]
        (var x false)
    (each [_ k-desc (ipairs client-direction-keys)]
      (-> t
          (add-key! [modkey] k-desc.key
                    (fn []
                       (awful.client.focus.bydirection k-desc.dir)
                       (-?> client.focus (: :raise)))
                    {:description (.. "focus a client " k-desc.desc) :group :client})
          (add-key! [modkey :Shift] k-desc.key
                    (fn []
                      (awful.client.swap.bydirection k-desc.dir))
                    {:description (.. "swap with a client " k-desc.desc) :group :client})))
    t))

(local tag-global-keys
  ;; Bind all key numbers to tags.
  ;; Be careful: we use keycodes to make it work on any keyboard layout.
  ;; This should map on the top row of your keyboard, usually 1 to 9.
  (let [t {}]
    (for [i 1 (math.min 9 (length tags))]
      (let [b (.. "#" (+ i 9))]
        (-> t
            (add-key! [modkey] (.. "#" (+ i 9))
                      (fn []
                        (let [s (awful.screen.focused)]
                          (-?> (. s.tags i) switch-to-tag)))
                      {:description (.. "view tag #" i) :group :tag})
            (add-key! [modkey :Control] b
                      (fn []
                        (let [s (awful.screen.focused)]
                          (-?> (. s.tags i) awful.tag.viewtoggle)))
                      {:description (.. "toggle tag #" i) :group :tag})
            (add-key! [modkey :Shift] b
                      (fn []
                        (match client.focus
                          c (-?> (. c.screen.tags i) c:move_to_tag)))
                      {:description (.. "move focused client to tag #" i) :group :tag})
            (add-key! [modkey :Control :Shift] b
                      (fn []
                        (match client.focus
                          c (-?> (. c.screen.tags i) c:toggle_tag)))
                      {:description (.. "toggle focused client on tag #" i) :group :tag}))))
    t))

{: taglist-buttons
 : tasklist-buttons
 : global-buttons
 :global-keys (gears.table.join common-global-keys
                                client-global-keys
                                tag-global-keys)}
