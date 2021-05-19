(fn config-path []
  (let [di (debug.getinfo 1 "S")
        ;; `source`, when a script is run from a file, starts with "@".
        file-path (di.source:sub 2)
        rc-dir-path (file-path:match "(.*/)")]
    ;; Remove "/rc/" from the end of the path.
    (rc-dir-path:sub 1 (- (length rc-dir-path) 4))))

(fn trim [s]
  ;; Remove leading and trailing spaces from the string.
  ;; trim5 from http://lua-users.org/wiki/StringTri
  (or (s:match "^%s*(.*%S)") ""))

{: config-path
 : trim}
