(local naughty (require :naughty))

(fn trim [s]
  ;; Remove leading and trailing spaces from the string.
  ;; trim5 from http://lua-users.org/wiki/StringTri
  (or (s:match "^%s*(.*%S)") ""))

(fn file-exists? [name]
  (let [f (io.open name :r)]
    (-?> f (io.close))
    (not= f nil)))

(fn rotate-table-in-place [t n]
  (let [l (length t)]
    (if (< n 0) (rotate-table-in-place t (% n l))
        (= n 0) t
        (do
          (for [i 1 n]
            (table.insert t 1 (table.remove t l)))
          t))))

(fn log [...]
  (let [(file msg) (io.open "/tmp/awesome-fennel.log" "a+")]
    (when msg
      (naughty.notify {:title  "Cannot open log file"
                       :text   msg
                       :preset naughty.config.presets.critical}))
    (let [n (select :# ...)]
      (each [i item (ipairs [...])]
        (file:write item (when (< i n) " "))))
    (file:write "\n")
    (file:flush)
    (file:close)))

{: trim : file-exists? : rotate-table-in-place : log}
