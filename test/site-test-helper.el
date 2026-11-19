;;; site-test-helper.el --- Shared test setup  -*- lexical-binding: t -*-

(require 'ert)

(defconst site-test-dir
  (file-name-directory (or load-file-name buffer-file-name)))

(add-to-list 'load-path (expand-file-name "../lisp" site-test-dir))
(require 'site-content)

(defun site-test--tree (files)
  "Create a temp dir holding FILES, an alist (RELATIVE-PATH . CONTENT).
Return the dir."
  (let ((root (make-temp-file "site-test" t)))
    (pcase-dolist (`(,rel . ,content) files)
      (let ((f (expand-file-name rel root))
            (coding-system-for-write 'utf-8))
        (make-directory (file-name-directory f) t)
        (write-region content nil f)))
    root))

(defun site-test--file (rel content)
  "Create one temp file at REL holding CONTENT. Return its path."
  (expand-file-name rel (site-test--tree (list (cons rel content)))))

(provide 'site-test-helper)
;;; site-test-helper.el ends here
