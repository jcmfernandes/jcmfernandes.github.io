;;; post.el --- Blog post  -*- lexical-binding: t -*-

(defun tpl--banner-line (width &optional text)
  "Phrack banner line, WIDTH wide, framing TEXT; all dashes if TEXT is nil."
  (if (null text)
      (concat "|=" (make-string (- width 4) ?-) "=|")
    (let* ((free (max 0 (- width 10 (string-width text))))
           (left (/ free 2)))
      (concat "|=" (make-string left ?-) "=[ " text " ]="
              (make-string (- free left) ?-) "=|"))))

(defun tpl-banner (title &optional width)
  "Phrack-style banner for TITLE, WIDTH (default 75) columns wide.
TITLE wraps to keep at least 3 dashes on both sides."
  (let ((width (or width 75)))
    (mapconcat (lambda (text) (tpl--banner-line width text))
               `(nil ,@(split-string (string-fill title (- width 16)) "\n") nil)
               "\n")))

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
              (pre ((class . "banner banner-wide")) ,(tpl-banner (plist-get post :title)))
              (pre ((class . "banner banner-narrow")) ,(tpl-banner (plist-get post :title) 42))
              (raw-string ,(plist-get post :html))))))
;;; post.el ends here
