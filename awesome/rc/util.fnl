(fn trim [s]
  ;; Remove leading and trailing spaces from the string.
  ;; trim5 from http://lua-users.org/wiki/StringTri
  (or (s:match "^%s*(.*%S)") ""))

{: trim}
