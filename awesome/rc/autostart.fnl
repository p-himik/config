(local awful (require :awful))

(local mate-polkit-cmd "killall mate-polkit 2>/dev/null; mate-polkit")
(local xbindkeys-cmd "killall xbindkeys 2>/dev/null; sleep 1; xbindkeys")
(local compositor-cmd "killall picom 2>/dev/null; sleep 1; picom --daemon --config \"$HOME/config/picom.conf\"")
;; Discarding the output of snixembed because there's just too much garbage in there.
(local snixembed-cmd "killall snixembed 2>/dev/null; sleep 1; snixembed 2>&1 >/dev/null")


(each [_ cmd (ipairs [mate-polkit-cmd xbindkeys-cmd compositor-cmd snixembed-cmd])]
  (awful.spawn.with_shell cmd))
