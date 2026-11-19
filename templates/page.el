;;; page.el --- Standalone page  -*- lexical-binding: t -*-

(defun tpl-page (page)
  "Page for PAGE: title bar, article box."
  (tpl-base
   (plist-get page :title)
   `((h1 ((class . "opt")) ,(plist-get page :title))
     (article ((class . "framed article")) (raw-string ,(plist-get page :html))))))
;;; page.el ends here
