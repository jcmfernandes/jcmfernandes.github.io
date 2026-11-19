;;; tag.el --- Tag pages  -*- lexical-binding: t -*-

(defun tpl-tag (tag posts)
  "Page listing POSTS tagged TAG."
  (tpl-base
   (concat "Tag: " tag)
   `((div ((class . "opt")) (strong () "Tag") ,(concat " : " tag))
     ,(tpl-post-table posts))))

(defun tpl-tags (tags)
  "Page listing TAGS, an alist (TAG . POSTS), with post counts."
  (tpl-base
   "Tags"
   `((div ((class . "opt")) (strong () "Tags") ,(format " : %d" (length tags)))
     (table ((class . "tissue"))
            (tbody ()
                   ,@(if tags
                         (mapcar (lambda (entry)
                                   `(tr ()
                                        (td () (a ((href . ,(format "/tags/%s/" (car entry))))
                                                  ,(car entry)))
                                        (td () ,(number-to-string (length (cdr entry))))))
                                 tags)
                       '((tr () (td () "No tags yet.") (td () " ")))))))))
;;; tag.el ends here
