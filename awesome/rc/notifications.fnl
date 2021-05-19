(local awful (require :awful))
(local naughty (require :naughty))
(local ruled (require :ruled))

(naughty.connect_signal
 :request::display_error
 (fn [msg startup?]
   ;; `startup?` should be true only inside the fallback config.
   (naughty.notification {:preset  naughty.config.presets.critical
                          :title   (.. "Oops, an error happened" (if startup? " during startup!" "!"))
                          :message msg})))

(fn send-text-to-clipboard [text]
  (with-open [h (io.popen "xclip -selection clipboard" "w")]
    (h:write text)))

(fn not-empty-str [s]
  (when (and (not= s "")
             (not= s nil))
    s))

(ruled.notification.connect_signal
  :request::rules
  (fn []
    (ruled.notification.append_rule {:rule       {:urgency  :low
                                                  :app_name "Solaar"}
                                     :properties {:ignore true}})
    (let [copy-action (naughty.action {:name "Copy"})]
      (copy-action:connect_signal
        :invoked
        (fn [_action notif]
          (let [title (not-empty-str notif.title)
                msg (not-empty-str notif.message)]
            (send-text-to-clipboard (if (and title msg)
                                      (.. title "\n" msg)
                                      (or title msg))))))
      (ruled.notification.append_rule
        {:rule       {}
         :properties {:append_actions [copy-action]
                      :screen         awful.screen.preferred
                      :never_timeout  true}}))))

(naughty.connect_signal :request::display (fn [n] (naughty.layout.box {:notification n})))
