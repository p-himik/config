(local awful (require :awful))
(local clj (require :cljlib))
(local gears (require :gears))
(local lain (require :lain))

;; NOTE: Use `xprop WM_CLASS` to get the value and use the last item in the list for the rules.
;;       To spy on the classes of newly opened windows, you can try using
;;       `xprop -spy -root _NET_ACTIVE_WINDOW | stdbuf -oL cut -f5 -d' ' | xargs -I{} xprop -id {} WM_CLASS`.
;; The values are case-sensitive.
(local tag-specs
  (let [ls awful.layout.suit
        t (fn [name layout classes]
            {: name : layout : classes})]
    ;; Table of layouts to cover with awful.layout.inc, order matters.
    (awful.layout.append_default_layouts
      [ls.floating
       lain.layout.centerwork
       ls.tile
       ls.tile.left
       ls.tile.bottom
       ls.tile.top
       ls.fair
       ls.fair.horizontal
       ls.magnifier
       ls.max
       ls.max.fullscreen])
    [(t :cmd ls.fair
        [])
     (t :www lain.layout.centerwork
        [])
     (t :dev ls.tile
        ["^jetbrains-" "java-lang-Thread"])
     (t :soc ls.fair
        ["Skype" "Telegram" "Slack" "discord" "Zulip"])
     (t :db ls.tile.left
        ["com-install4j-runtime-launcher-Launcher" "Cherrytree" "calibre"])
     (t "@" ls.tile.left
        [])
     (t :vb ls.tile.left
        ["VirtualBox"])
     (t :8 ls.tile.left
        ["Deadbeef"])
     (t :9 ls.max.fullscreen
        ["Steam"])]))

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

{: tag-specs
 : switch-to-tag}