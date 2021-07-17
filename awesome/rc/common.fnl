(local awful (require :awful))
(local fennel (require :fennel))
(local gears (require :gears))
(local gfs (require :gears.filesystem))
(local naughty (require :naughty))

(local terminal "terminator")

(local sensitive-config (let [path (.. (gfs.get_configuration_dir) "/sensitive_config.fnl")]
                          (if (gfs.file_readable path)
                            (fennel.dofile path)
                            {})))

(local spectacle-commands
  ;; Currently unused - left here for reference.
  {:screenshot-screen "spectacle -f"
   :screenshot-window "spectacle -a"
   :screenshot-selection "spectacle -r"})

(local flameshot-commands
  (let [check-before-running (fn [cmd]
                               (fn []
                                 (awful.spawn.easy_async "whoami"
                                   (fn [stdout stderr exit-reason exit-code]
                                     (let [user (stdout:gsub "\n$" "")]
                                       (awful.spawn.easy_async ["pgrep" "-x" "-u" user "-c" "flameshot"]
                                         (fn [stdout stderr exit-reason exit-code]
                                           (if (= exit-code 0)
                                             (awful.spawn cmd)
                                             ;; TODO: Either start flameshot here and wait for its DBus endpoints to become available
                                             ;;  or try running Awesome WM with dbus-launch: https://wiki.archlinux.org/title/Flameshot#Option_1:_Use_dbus-launch
                                             (naughty.notification {:preset  naughty.config.presets.warn
                                                                    :title   "Flameshot"
                                                                    :message "Please start Flameshot before taking screenshots with it"})))))))))]
    {:screenshot-screen (check-before-running "flameshot screen -c")
     ;; Flameshot can't capture a single window.
     :screenshot-window (check-before-running "flameshot gui")
     :screenshot-selection (check-before-running "flameshot gui")}))

(gears.table.crush
  {; Default modkey.
   ; Usually, Mod4 is the key with a logo between Control and Alt.
   ; If you do not like this or do not have such a key,
   ; I suggest you to remap Mod4 to another key using xmodmap or other tools.
   ; However, you can use another modifier like Mod1, but it may interact with others.
   :modkey :Mod4
   :terminal "terminator"

   :cmds (gears.table.crush
           {:terminal terminal
            :editor (.. terminal " -x " (or (os.getenv :EDITOR) "vim"))
            :lock "physlock -dms"
            :logout (.. "pkill -u " (os.getenv "USER"))
            :suspend "dbus-send --system --print-reply --dest='org.freedesktop.login1' /org/freedesktop/login1 org.freedesktop.login1.Manager.Suspend boolean:true"
            :hibernate "sudo pm-hibernate"
            :switch-dp-monitor "switch_monitor.sh DP-1"
            :jetbrains-toolbox "/home/p-himik/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox"}
           flameshot-commands)}
  sensitive-config)
