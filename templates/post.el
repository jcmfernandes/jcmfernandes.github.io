;;; post.el --- Blog post  -*- lexical-binding: t -*-

(defun tpl-post (post)
  "Page for POST: title bar, date/tags bar, article box."
  (tpl-base
   (plist-get post :title)
   `((h1 ((class . "opt")) (strong () "Title") ,(concat " : " (plist-get post :title)))
     (div ((class . "opt-bottom"))
          (strong () "Date") ,(concat " : " (plist-get post :date))
          ,@(when (plist-get post :tags)
              `(" | " (strong () "Tags") " : " ,@(tpl-tag-links (plist-get post :tags)))))
     (article ((class . "framed article")) (raw-string ,(plist-get post :html))))))
;;; post.el ends here
