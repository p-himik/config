(local beautiful (require :beautiful))
(local gears (require :gears))

(fn set-wallpaper [s]
  (match beautiful.wallpaper
    wp (let [wp (if (= (type wp) :function)
                    (wp s)
                    wp)]
         (gears.wallpaper.maximized wp s true))))

(screen.connect_signal "property::geometry" set-wallpaper)

set-wallpaper
