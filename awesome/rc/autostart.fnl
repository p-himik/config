(local awful (require :awful))

(local xbindkeys-cmd "killall xbindkeys 2>/dev/null; sleep 1; xbindkeys")
(local compositor-cmd "killall picom 2>/dev/null; picom --daemon --config \"$HOME/config/picom.conf\"")
(local snixembed-cmd "killall snixembed 2>/dev/null; sleep 1; snixembed")

(each [_ cmd (ipairs [xbindkeys-cmd compositor-cmd snixembed-cmd])]
  (awful.spawn.with_shell cmd))
