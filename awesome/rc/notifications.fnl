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

(local disabled-notifications [{:urgency :low :app_name "Solaar"}
                               {:urgency :low :app_name "Network Management"}
                               ;; For some reason, it still keeps on showing notifications about connected
                               ;; devices even after the relevant plugin has been disabled.
                               {:urgency :normal :app_name "blueman"}])
(local temp-notifications [{:urgency :normal :app_name "flameshot"}])

(ruled.notification.connect_signal
  :request::rules
  (fn []
    (ruled.notification.append_rules
      (icollect [_ rule (ipairs disabled-notifications)]
        {:rule       rule
         :properties {:ignore  true
                      ;; Without the timeout, the notification object will be there forever, creating a leak.
                      ;; TODO: Report the leak.
                      :timeout 1}}))
    (ruled.notification.append_rules
      (icollect [_ rule (ipairs temp-notifications)]
        {:rule       rule
         :properties {:timeout 3}}))
    (let [copy-action (naughty.action {:name "Copy"})
          copy-info-action (naughty.action {:name "Copy Info"})]
      (copy-action:connect_signal
        :invoked
        (fn [_action notif]
          (let [title (not-empty-str notif.title)
                msg (not-empty-str notif.message)]
            (send-text-to-clipboard (if (and title msg)
                                      (.. title "\n" msg)
                                      (or title msg))))))
      (copy-info-action:connect_signal
        :invoked
        (fn [_action notif]
          (let [view (require :fennel.view)
                info (view notif)]
            (send-text-to-clipboard info))))
      (ruled.notification.append_rule
        {:rule       {}
         :properties {:append_actions [copy-action copy-info-action]
                      :title          (fn [notif]
                                        (.. notif.title " [app: " notif.app_name "]"))
                      :screen         awful.screen.preferred
                      :never_timeout  true}}))))

(naughty.connect_signal :request::display (fn [n] (naughty.layout.box {:notification n})))
