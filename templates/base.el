;;; base.el --- Page shell and shared pieces  -*- lexical-binding: t -*-

(defun tpl-nav ()
  "Bracketed site navigation."
  `(nav ((class . "nav"))
        ,@(mapcan (lambda (link)
                    (list "[ " `(a ((href . ,(cdr link))) ,(car link)) " ] "))
                  '(("Blog" . "/") ("Tags" . "/tags/")
                    ("About" . "/about/") ("RSS" . "/atom.xml")))))

(defun tpl-tag-links (tags)
  "Comma-separated links to TAGS' pages."
  (cdr (mapcan (lambda (tag)
                 (list ", " `(a ((href . ,(format "/tags/%s/" tag))) ,tag)))
               tags)))

(defun tpl-post-table (posts)
  "Blue table: post title left, date right."
  `(table ((class . "tissue"))
          (tbody ()
                 ,@(if posts
                       (mapcar (lambda (post)
                                 `(tr ()
                                      (td () (a ((href . ,(plist-get post :url)))
                                                ,(plist-get post :title)))
                                      (td () ,(plist-get post :date))))
                               posts)
                     '((tr () (td () "No posts yet.") (td () " ")))))))

(defun tpl-base (title body)
  "Full page titled TITLE around BODY, a list of esxml nodes."
  `(html ((lang . "en"))
         (head ()
               (meta ((charset . "utf-8")))
               (meta ((name . "viewport") (content . "width=device-width,initial-scale=1")))
               (title () ,(format ".:: %s ::." title))
               (link ((rel . "stylesheet") (href . "/style.css")))
               (link ((rel . "alternate") (type . "application/atom+xml")
                      (href . "/atom.xml") (title . ,site-title))))
         (body ()
               ,(tpl-nav)
               (header ()
                       (a ((href . "/") (class . "logo"))
                          (pre () ,(site-template-file "logo.txt"))))
               (main ((class . "around")) ,@body)
               ,(tpl-nav)
               (footer () ,(format "|=[ EOF ]=---  %s" site-author)))))
;;; base.el ends here
