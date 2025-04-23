(local awful (require :awful))

(local mate-polkit-cmd "killall mate-polkit 2>/dev/null; mate-polkit")
(local xbindkeys-cmd "killall xbindkeys 2>/dev/null; sleep 1; xbindkeys")
(local compositor-cmd "killall picom 2>/dev/null; sleep 1; picom --daemon --config \"$HOME/config/picom.conf\"")

(each [_ cmd (ipairs [mate-polkit-cmd xbindkeys-cmd compositor-cmd])]
  (awful.spawn.with_shell cmd))
