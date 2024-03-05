(local awful (require :awful))

(local mate-polkit-cmd "killall mate-polkit 2>/dev/null; mate-polkit")
(local xbindkeys-cmd "killall xbindkeys 2>/dev/null; sleep 1; xbindkeys")
(local compositor-cmd "killall picom 2>/dev/null; picom --daemon --config \"$HOME/config/picom.conf\"")
(local mate-panel-reset-cmd "mate-panel --replace")

(each [_ cmd (ipairs [mate-polkit-cmd xbindkeys-cmd compositor-cmd mate-panel-reset-cmd])]
  (awful.spawn.with_shell cmd))
