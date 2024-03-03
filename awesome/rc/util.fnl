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

{: trim : file-exists? : rotate-table-in-place}
