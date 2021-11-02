(local awful (require :awful))

(local xbindkeys-cmd "killall xbindkeys 2>/dev/null; sleep 1; xbindkeys")
(local compton-cmd "killall compton 2>/dev/null; compton --daemon --config \"$HOME/config/compton.conf\"")
(local snixembed-cmd "killall snixembed 2>/dev/null; sleep 1; snixembed")

(each [_ cmd (ipairs [xbindkeys-cmd compton-cmd snixembed-cmd])]
  (awful.spawn.with_shell cmd))
