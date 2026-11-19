;;; post.el --- Blog post  -*- lexical-binding: t -*-

(defun tpl--banner-line (&optional text)
  "Phrack banner line, 75 wide, framing TEXT; all dashes if TEXT is nil."
  (if (null text)
      (concat "|=" (make-string 71 ?-) "=|")
    (let* ((free (max 0 (- 65 (string-width text))))
           (left (/ free 2)))
      (concat "|=" (make-string left ?-) "=[ " text " ]="
              (make-string (- free left) ?-) "=|"))))

(defun tpl-banner (title)
  "Phrack-style banner for TITLE, wrapped to keep dashes on both sides."
  (mapconcat #'identity
             `(,(tpl--banner-line)
               ,@(mapcar #'tpl--banner-line (split-string (string-fill title 59) "\n"))
               ,(tpl--banner-line))
             "\n"))

(defun tpl-post (post)
  "Page for POST: title bar, date/tags bar, banner and article box."
  (tpl-base
   (plist-get post :title)
   `((h1 ((class . "opt")) (strong () "Title") ,(concat " : " (plist-get post :title)))
     (div ((class . "opt-bottom"))
          (strong () "Date") ,(concat " : " (plist-get post :date))
          ,@(when (plist-get post :tags)
              `(" | " (strong () "Tags") " : " ,@(tpl-tag-links (plist-get post :tags)))))
     (article ((class . "framed article"))
              (pre ((class . "banner")) ,(tpl-banner (plist-get post :title)))
              (raw-string ,(plist-get post :html))))))
;;; post.el ends here
