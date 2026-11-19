;;; index.el --- Front page  -*- lexical-binding: t -*-

(defun tpl-index (intro posts)
  "Front page: INTRO item (or nil), summary bar, POSTS table."
  (tpl-base
   site-title
   `(,@(when intro
         `((article ((class . "framed article")) (raw-string ,(plist-get intro :html)))))
     (div ((class . "opt"))
          (strong () "Latest") ,(concat " : " (if posts (plist-get (car posts) :date) "-"))
          " | " (strong () "Posts") ,(format " : %d" (length posts)))
     ,(tpl-post-table posts))))
;;; index.el ends here
