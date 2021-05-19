(local gears (require :gears))
(local gfs (require :gears.filesystem))
(local fennel (require :fennel))

(local terminal "terminator")

(local sensitive-config (let [path (.. (gfs.get_configuration_dir) "/sensitive_config.fnl")]
                          (if (gfs.file_readable path)
                            (fennel.dofile path)
                            {})))

(gears.table.crush
  {; Default modkey.
   ; Usually, Mod4 is the key with a logo between Control and Alt.
   ; If you do not like this or do not have such a key,
   ; I suggest you to remap Mod4 to another key using xmodmap or other tools.
   ; However, you can use another modifier like Mod1, but it may interact with others.
   :modkey :Mod4
   :terminal "terminator"

   :cmds {:terminal terminal
          :editor (.. terminal " -x " (or (os.getenv :EDITOR) "vim"))
          :lock "physlock -dms"
          :logout (.. "pkill -u " (os.getenv "USER"))
          :suspend "dbus-send --system --print-reply --dest='org.freedesktop.login1' /org/freedesktop/login1 org.freedesktop.login1.Manager.Suspend boolean:true"
          :hibernate "sudo pm-hibernate"
          :screenshot-screen "spectacle -f"
          :screenshot-window "spectacle -a"
          :screenshot-selection "spectacle -r"
          :switch-dp-monitor "switch_monitor.sh DP-1"
          :jetbrains-toolbox "/home/p-himik/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox"}}
  sensitive-config)
