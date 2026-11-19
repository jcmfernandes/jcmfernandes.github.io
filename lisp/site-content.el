;;; site-content.el --- Read content files: metadata and body HTML  -*- lexical-binding: t -*-

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'time-date)
(require 'org)
;; Load now so the `let' in `site--org-html' binds ox-html's variables
;; dynamically, not lexically.
(require 'ox-html)
(require 'site-init)

(set-language-environment "UTF-8")

(defvar site-babel-languages '(emacs-lisp)
  "Org Babel languages allowed to run during export.")

(defconst site--pandoc-meta-template
  (expand-file-name "pandoc-meta.tpl"
                    (file-name-directory (or load-file-name buffer-file-name))))

(defconst site--name-re "\\`[a-z0-9-]+\\'"
  "Allowed slugs and tags. They become directory names.")

(defun site-parse-date (s)
  "Return \"YYYY-MM-DD\" from S, plain or an Org timestamp; nil if invalid."
  (when (stringp s)
    (let ((s (string-trim s)))
      (when (string-match
             "\\`<?\\([0-9]\\{4\\}\\)-\\([0-9]\\{2\\}\\)-\\([0-9]\\{2\\}\\)\\(?: [^>]*\\)?>?\\'"
             s)
        (let ((y (string-to-number (match-string 1 s)))
              (m (string-to-number (match-string 2 s)))
              (d (string-to-number (match-string 3 s))))
          (when (and (<= 1 m 12) (<= 1 d (date-days-in-month y m)))
            (format "%04d-%02d-%02d" y m d)))))))

(defun site-slug (file)
  "Return FILE's slug: base name without an optional YYYY-MM-DD- prefix."
  (let ((base (file-name-base file)))
    (if (string-match "\\`[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}-" base)
        (substring base (match-end 0))
      base)))

(defun site--pandoc (file &rest args)
  "Run pandoc with ARGS on FILE. Return stdout.
Signal an error naming FILE if pandoc fails."
  (let ((err (make-temp-file "site-pandoc")))
    (unwind-protect
        (with-temp-buffer
          (let* ((coding-system-for-read 'utf-8)
                 (status (apply #'call-process "pandoc" nil (list t err) nil
                                (append args (list file)))))
            (unless (eq status 0)
              (error "%s: pandoc failed: %s" file
                     (with-temp-buffer
                       (insert-file-contents err)
                       (string-trim (buffer-string)))))
            (buffer-string)))
      (delete-file err))))

(defun site--md-meta (file)
  "Return (:title :date :tags :draft) from FILE's YAML header."
  (let* ((json (site--pandoc file "-f" "markdown" "-t" "plain"
                             (concat "--template=" site--pandoc-meta-template)))
         (m (json-parse-string json :object-type 'plist :array-type 'list
                               :false-object nil :null-object nil))
         (tags (plist-get m :tags)))
    (list :title (plist-get m :title)
          :date (plist-get m :date)
          :tags (if (stringp tags) (list tags) tags)
          :draft (and (plist-get m :draft) t))))

(defun site--org-meta (file)
  "Return (:title :date :tags :draft) from FILE's Org keywords."
  (with-temp-buffer
    (insert-file-contents file)
    (let ((org-mode-hook nil))
      (org-mode))
    (let ((kw (org-collect-keywords '("TITLE" "DATE" "FILETAGS" "DRAFT"))))
      (cl-flet ((get (k) (cadr (assoc k kw))))
        (list :title (get "TITLE")
              :date (get "DATE")
              :tags (and (get "FILETAGS") (split-string (get "FILETAGS") ":" t "[ \t]+"))
              :draft (and (get "DRAFT") (member-ignore-case (get "DRAFT") '("t" "true" "yes")) t))))))

(defun site-read-item (file kind)
  "Return the item plist for FILE. KIND is `post', `page' or `index'.
Signal an error naming FILE if metadata is missing or invalid."
  (let* ((fmt (if (string-suffix-p ".org" file) 'org 'md))
         (meta (if (eq fmt 'org) (site--org-meta file) (site--md-meta file)))
         (title (plist-get meta :title))
         (raw-date (plist-get meta :date))
         (date (site-parse-date raw-date))
         (slug (site-slug file)))
    (unless (and title (not (string-empty-p title)))
      (error "%s: missing title" file))
    (when (and (eq kind 'post) (not raw-date))
      (error "%s: missing date" file))
    (when (and raw-date (not date))
      (error "%s: invalid date %S" file raw-date))
    (unless (string-match-p site--name-re slug)
      (error "%s: invalid slug %S (use a-z, 0-9, -)" file slug))
    (dolist (tag (plist-get meta :tags))
      (unless (string-match-p site--name-re tag)
        (error "%s: invalid tag %S (use a-z, 0-9, -)" file tag)))
    (list :kind kind :file file :format fmt :slug slug
          :url (pcase kind
                 ('index "/")
                 ('page (format "/%s/" slug))
                 ('post (format "/posts/%s/" slug)))
          :title title :date date
          :tags (plist-get meta :tags)
          :draft (plist-get meta :draft))))

(defun site--org-site-links (text _backend _info)
  "Turn Org's `file:///x' links into site-absolute `/x' in exported TEXT.
Org reads `[[/posts/x/]]' as an absolute file path; on the site it is a URL."
  (replace-regexp-in-string "\\(href\\|src\\)=\"file:///" "\\1=\"/" text))

(defun site--org-html (file)
  "Export Org FILE's body to an HTML fragment. Run Babel blocks.
Signal an error naming FILE if export fails."
  (org-babel-do-load-languages
   'org-babel-load-languages
   (mapcar (lambda (lang) (cons lang t)) site-babel-languages))
  (with-temp-buffer
    (insert-file-contents file)
    (setq default-directory (file-name-directory file))
    (let ((org-mode-hook nil))
      (org-mode))
    (let ((org-export-use-babel t)
          (org-confirm-babel-evaluate nil)
          (org-babel-python-command "python3")
          (org-export-with-toc nil)
          (org-export-with-section-numbers nil)
          (org-html-htmlize-output-type 'css)
          (org-html-doctype "html5")
          (org-html-html5-fancy t)
          (org-export-filter-link-functions '(site--org-site-links)))
      (condition-case e
          (org-export-as 'html nil nil t)
        (error (error "%s: org export failed: %s" file (error-message-string e)))))))

(defun site-render-body (item)
  "Return ITEM's body as an HTML fragment."
  (let ((file (plist-get item :file)))
    (if (eq (plist-get item :format) 'org)
        (site--org-html file)
      (site--pandoc file "-f" "markdown" "-t" "html"))))

(defun site-with-html (item)
  "Return ITEM with :html set to its rendered body."
  (append item (list :html (site-render-body item))))

(provide 'site-content)
;;; site-content.el ends here
