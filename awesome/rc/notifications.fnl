(local naughty (require :naughty))

;; Handle runtime errors after startup.
(var *in-error* false)
(awesome.connect_signal
  "debug::error"
  (fn [err]
    ;; Make sure we don't go into an endless error loop.
    (when (not *in-error*)
      (set *in-error* true)
      (naughty.notify {:preset naughty.config.presets.critical
                       :title  "Oops, an error happened!"
                       :text   (tostring err)})
      (set *in-error* false))))

(fn send-text-to-clipboard [text]
  (with-open [h (io.popen "xclip -selection clipboard" "w")]
    (h:write text)))

(fn not-empty-str [s]
  (when (and (not= s "")
             (not= s nil))
    s))

(local default-timeout 60)
(set naughty.config.defaults.timeout default-timeout)

(local rnotification (require :ruled.notification))
(rnotification.connect_signal
  "request::rules"
  (fn []
    (rnotification.append_rule {:rule       {:urgency  :low
                                             :app_name "Solaar"}
                                :properties {:ignore true}})
    (let [copy-action (naughty.action {:name "Copy"})]
      (copy-action:connect_signal
        "invoked"
        (fn [_action notif]
          (let [title (not-empty-str notif.title)
                msg (not-empty-str notif.message)]
            (send-text-to-clipboard (if (and title msg)
                                      (.. title "\n" msg)
                                      (or title msg))))))
      (rnotification.append_rule
        {:rule       {}
         :properties {:append_actions [copy-action]
                      :callback       (fn [args]
                                        ;; Timeout 0 means no timeout, which is used for critical notfications.
                                        (when (and (> args.timeout 0)
                                                   (< args.timeout default-timeout))
                                          (set args.timeout default-timeout)))}}))))
