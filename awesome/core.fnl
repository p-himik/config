(require :rc.notifications)
(require :rc.autostart)
(require :rc.client)
(require :rc.bindings)
(require :rc.screen)
(require :rc.rules)
;; When loaded, this module makes sure that there's always a client that will
;; have focus on events such as tag switching, client unmanaging, etc.
(require :awful.autofocus)

(local menubar (require :menubar))
(local common (require :rc.common))
;; Set the terminal for applications that require it.
(set menubar.utils.terminal common.cmds.terminal)
