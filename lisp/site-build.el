;;; site-build.el --- Build the site  -*- lexical-binding: t -*-

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'subr-x)
(require 'xml)

;; `emacs -l lisp/site-build.el` doesn't put lisp/ on the load path.
(add-to-list 'load-path (file-name-directory (or load-file-name buffer-file-name)))
(require 'site-init)
(require 'site-content)

(defconst site-repo-root
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name))))
  "Generator repo root: holds lisp/ and templates/.")

(defvar site-title "Untitled" "Site title.")
(defvar site-author "Anonymous" "Site author.")
(defvar site-base-url "http://localhost:8000" "Absolute site URL, no trailing slash.")
(defvar site-live-reload nil
  "Non-nil (preview only): pages reload when /.build changes.")

(defconst site--content-re "\\`[^.#].*\\.\\(org\\|md\\)\\'"
  "Content file names. Skips dotfiles and Emacs lock files (`.#x.org').")

(defun site-load-config (root)
  "Load ROOT/site.el. SITE_BASE_URL, when set and non-empty, wins.
SITE_LIVE_RELOAD=1 turns on `site-live-reload'."
  (let ((file (expand-file-name "site.el" root)))
    (unless (file-exists-p file)
      (error "%s: missing" file))
    (load file nil t))
  (setq site-live-reload (equal (getenv "SITE_LIVE_RELOAD") "1"))
  (let ((env (getenv "SITE_BASE_URL")))
    (when (and env (not (string-empty-p env)))
      (setq site-base-url env)))
  (setq site-base-url (string-trim-right site-base-url "/+")))

(defun site--check-unique-urls (items)
  "Signal an error if two ITEMS share a URL."
  (let ((seen (make-hash-table :test #'equal)))
    (dolist (item items)
      (let* ((url (plist-get item :url))
             (prev (gethash url seen)))
        (when prev
          (error "%s: URL %s already used by %s" (plist-get item :file) url prev))
        (puthash url (plist-get item :file) seen)))))

(defun site-collect (root drafts)
  "Read ROOT/content. Return (:intro ITEM :pages ITEMS :posts ITEMS).
Posts are newest first. Drafts are dropped unless DRAFTS is non-nil."
  (let* ((content (expand-file-name "content" root))
         (posts-dir (expand-file-name "posts" content))
         (intros nil)
         (pages nil)
         (posts (mapcar (lambda (f) (site-read-item f 'post))
                        (and (file-directory-p posts-dir)
                             (directory-files posts-dir t site--content-re)))))
    (dolist (f (directory-files content t site--content-re))
      (if (equal (site-slug f) "index")
          (push (site-read-item f 'index) intros)
        (push (site-read-item f 'page) pages)))
    (setq pages (nreverse pages))
    (unless drafts
      (setq pages (cl-remove-if (lambda (i) (plist-get i :draft)) pages)
            posts (cl-remove-if (lambda (i) (plist-get i :draft)) posts)))
    (setq posts (sort posts (lambda (a b) (string> (plist-get a :date) (plist-get b :date)))))
    (site--check-unique-urls (append intros pages posts))
    (list :intro (car intros) :pages pages :posts posts)))

(defun site--rfc3339 (date)
  "Turn \"YYYY-MM-DD\" into an RFC 3339 timestamp at midnight UTC."
  (concat date "T00:00:00Z"))

(defun site-atom (posts)
  "Return an Atom feed for the newest 20 of POSTS (already newest first)."
  (concat
   "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
   (esxml-to-xml
    `(feed ((xmlns . "http://www.w3.org/2005/Atom"))
           (title () ,site-title)
           (id () ,(concat site-base-url "/"))
           (link ((href . ,(concat site-base-url "/"))))
           (link ((rel . "self") (href . ,(concat site-base-url "/atom.xml"))))
           (updated () ,(site--rfc3339 (if posts (plist-get (car posts) :date) "1970-01-01")))
           (author () (name () ,site-author))
           ,@(mapcar
              (lambda (post)
                (let ((url (concat site-base-url (plist-get post :url))))
                  `(entry ()
                          (title () ,(plist-get post :title))
                          (id () ,url)
                          (link ((href . ,url)))
                          (updated () ,(site--rfc3339 (plist-get post :date)))
                          (content ((type . "html")) ,(plist-get post :html)))))
              (seq-take posts 20))))
   "\n"))

(dolist (tpl '("base" "post" "page" "index"))
  (load (expand-file-name (concat "templates/" tpl) site-repo-root) nil t))

(defun site--write (file string)
  "Write STRING to FILE as UTF-8, creating parent dirs."
  (make-directory (file-name-directory file) t)
  (let ((coding-system-for-write 'utf-8))
    (write-region string nil file nil 'silent)))

(defun site--page (url esxml)
  "Return (URL . HTML) for ESXML rendered as a full HTML document."
  (cons url (concat "<!doctype html>\n" (esxml-to-xml esxml) "\n")))

(defun site-build-site (root out drafts)
  "Build site ROOT into OUT. Include drafts if DRAFTS. Return OUT.
Everything is read and rendered before OUT is touched, so a failing
build leaves the previous output in place."
  (site-load-config root)
  (let* ((c (site-collect root drafts))
         (intro (and (plist-get c :intro) (site-with-html (plist-get c :intro))))
         (pages (mapcar #'site-with-html (plist-get c :pages)))
         (posts (mapcar #'site-with-html (plist-get c :posts)))
         (static (expand-file-name "static" root))
         (rendered
          (append
           (mapcar (lambda (page) (site--page (plist-get page :url) (tpl-page page))) pages)
           (mapcar (lambda (post) (site--page (plist-get post :url) (tpl-post post))) posts)
           (list (site--page "/" (tpl-index intro posts)))))
         (atom (site-atom posts)))
    (when (file-directory-p out)
      (delete-directory out t))
    (make-directory out t)
    (pcase-dolist (`(,url . ,html) rendered)
      (site--write (expand-file-name "index.html"
                                     (expand-file-name (string-remove-prefix "/" url) out))
                   html))
    (site--write (expand-file-name "atom.xml" out) atom)
    (when (file-directory-p static)
      (copy-directory static (file-name-as-directory out) nil t t))
    ;; Written last, so open pages reload only once the build is complete.
    (when site-live-reload
      (site--write (expand-file-name ".build" out) (format "%f" (float-time))))
    out))

(defun site-build ()
  "Command-line entry: build the repo into public/.
SITE_DRAFTS=true includes drafts. SITE_BASE_URL overrides the base URL."
  (message "Built %s"
           (site-build-site site-repo-root
                            (expand-file-name "public" site-repo-root)
                            (equal (getenv "SITE_DRAFTS") "true"))))

(provide 'site-build)
;;; site-build.el ends here
