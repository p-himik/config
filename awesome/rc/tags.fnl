(local awful (require :awful))
(local lain (require :lain))

;; NOTE: Use `xprop WM_CLASS` to get the value and use the last item in the list for the rules.
;;       To spy on the classes of newly opened windows, you can try using
;;       `xprop -spy -root _NET_ACTIVE_WINDOW | stdbuf -oL cut -f5 -d' ' | xargs -I{} xprop -id {} WM_CLASS`.
;; The values are case-sensitive.
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
      ["Steam"])])
