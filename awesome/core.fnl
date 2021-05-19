(require :rc.notifications)
(require :rc.autostart)
(require :rc.client)
;; When loaded, this module makes sure that there's always a client that will
;; have focus on events such as tag switching, client unmanaging, etc.
(require :awful.autofocus)

(local menubar (require :menubar))
(local common (require :rc.common))
;; Set the terminal for applications that require it.
(set menubar.utils.terminal common.cmds.terminal)

(local awful (require :awful))
(local set-wallpaper (require :rc.wallpaper))
(local add-wibar-to-screen (require :rc.wibar))
(awful.screen.connect_for_each_screen
  (fn [s]
    (set-wallpaper s)
    (add-wibar-to-screen s)))

(local {: global-buttons : global-keys} (require :rc.bindings))
(set root.buttons global-buttons)
(set root.keys global-keys)

(set awful.rules.rules (require :rc.rules))
