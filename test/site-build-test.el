;;; site-build-test.el --- Tests for site-build  -*- lexical-binding: t -*-

(add-to-list 'load-path (file-name-directory (or load-file-name buffer-file-name)))
(require 'site-test-helper)
(require 'site-build)

(defun site-test--post (slug date &optional tags)
  (list :kind 'post :slug slug :url (format "/posts/%s/" slug)
        :title (upcase slug) :date date :tags tags :html "<p>x</p>"))

(ert-deftest site-load-config-env-override ()
  (let ((root (site-test--tree '(("site.el" . ";; -*- lexical-binding: t -*-\n(setq site-base-url \"https://example.com/\")")))))
    (with-environment-variables (("SITE_BASE_URL" nil))
      (site-load-config root)
      (should (equal site-base-url "https://example.com")))
    (with-environment-variables (("SITE_BASE_URL" "http://localhost:8000"))
      (site-load-config root)
      (should (equal site-base-url "http://localhost:8000")))))

(ert-deftest site-load-config-missing-site-el ()
  (let ((root (site-test--tree '(("content/.keep" . "")))))
    (should (string-match-p "site\\.el: missing"
                            (cadr (should-error (site-load-config root)))))))

(ert-deftest site-collect-sorts-and-drops-drafts ()
  (let* ((root (site-test--tree
                '(("content/index.org" . "#+TITLE: Home\n")
                  ("content/about.md" . "---\ntitle: About\n---\n")
                  ("content/posts/2026-01-01-old.org" . "#+TITLE: Old\n#+DATE: 2026-01-01\n")
                  ("content/posts/new.md" . "---\ntitle: New\ndate: 2026-03-01\n---\n")
                  ("content/posts/wip.md" . "---\ntitle: WIP\ndate: 2026-04-01\ndraft: true\n---\n"))))
         (c (site-collect root nil))
         (c-drafts (site-collect root t)))
    (should (equal (plist-get (plist-get c :intro) :url) "/"))
    (should (equal (mapcar (lambda (p) (plist-get p :url)) (plist-get c :pages)) '("/about/")))
    (should (equal (mapcar (lambda (p) (plist-get p :slug)) (plist-get c :posts)) '("new" "old")))
    (should (equal (mapcar (lambda (p) (plist-get p :slug)) (plist-get c-drafts :posts))
                   '("wip" "new" "old")))))

(ert-deftest site-collect-duplicate-url ()
  (let ((root (site-test--tree
               '(("content/posts/2026-01-01-hello.org" . "#+TITLE: A\n#+DATE: 2026-01-01\n")
                 ("content/posts/hello.md" . "---\ntitle: B\ndate: 2026-02-01\n---\n")))))
    (should (string-match-p "URL /posts/hello/ already used"
                            (cadr (should-error (site-collect root nil)))))))

(ert-deftest site-collect-ignores-lock-files ()
  (let ((root (site-test--tree
               '(("content/posts/a.org" . "#+TITLE: A\n#+DATE: 2026-01-01\n")
                 ("content/.#about.org" . "")))))
    (make-symbolic-link "user@host.123:456" (expand-file-name "content/posts/.#a.org" root))
    (let ((c (site-collect root nil)))
      (should (equal (mapcar (lambda (p) (plist-get p :slug)) (plist-get c :posts)) '("a")))
      (should-not (plist-get c :pages)))))

(ert-deftest site-collect-page-clashes-with-tags-index ()
  (let ((root (site-test--tree '(("content/tags.org" . "#+TITLE: Tags\n")))))
    (should (string-match-p "URL /tags/ already used"
                            (cadr (should-error (site-collect root nil)))))))

(ert-deftest site-tags-groups-and-sorts ()
  (let* ((a (site-test--post "a" "2026-02-01" '("lisp" "emacs")))
         (b (site-test--post "b" "2026-01-01" '("lisp")))
         (tags (site-tags (list a b))))
    (should (equal (mapcar #'car tags) '("emacs" "lisp")))
    (should (equal (cdr (assoc "lisp" tags)) (list a b)))))

(ert-deftest site-atom-limits-and-uses-absolute-urls ()
  (let* ((site-base-url "https://example.com")
         (posts (cl-loop for i from 25 downto 1
                         collect (site-test--post (format "p%d" i) (format "2026-01-%02d" i))))
         (xml (with-temp-buffer
                (insert (site-atom posts))
                (xml-parse-region (point-min) (point-max))))
         (feed (car xml)))
    (should (eq (car feed) 'feed))
    (should (= (length (xml-get-children feed 'entry)) 20))
    (should (equal (car (xml-node-children (car (xml-get-children feed 'updated))))
                   "2026-01-25T00:00:00Z"))
    (should (equal (car (xml-node-children
                         (car (xml-get-children (car (xml-get-children feed 'entry)) 'id))))
                   "https://example.com/posts/p25/"))))
(defconst site-test-fixture (expand-file-name "fixture" site-test-dir))

(defun site-test--build (drafts)
  "Build the fixture into a fresh temp dir. Return the dir."
  (let ((out (make-temp-file "site-out" t)))
    (with-environment-variables (("SITE_BASE_URL" nil))
      (site-build-site site-test-fixture out drafts))))

(defun site-test--read (out rel)
  (with-temp-buffer
    (let ((coding-system-for-read 'utf-8))
      (insert-file-contents (expand-file-name rel out)))
    (buffer-string)))

(ert-deftest site-build-writes-expected-files ()
  (let ((out (site-test--build nil)))
    (dolist (rel '("index.html" "about/index.html" "posts/hello/index.html"
                   "posts/other/index.html" "tags/index.html" "tags/lisp/index.html"
                   "tags/emacs/index.html" "atom.xml" "style.css"))
      (should (file-exists-p (expand-file-name rel out))))
    (should-not (file-exists-p (expand-file-name "posts/wip/index.html" out)))))

(ert-deftest site-build-drafts-flag ()
  (should (file-exists-p (expand-file-name "posts/wip/index.html" (site-test--build t)))))

(ert-deftest site-build-page-contents ()
  (let* ((out (site-test--build nil))
         (index (site-test--read out "index.html"))
         (post (site-test--read out "posts/hello/index.html")))
    (should (string-prefix-p "<!doctype html>" index))
    (should (string-match-p "João Tester" index))
    (should (string-match-p "<b>here</b>" index))
    (should (string-match-p "href=\"/posts/hello/\"" index))
    (should (< (string-match "/posts/hello/" index) (string-match "/posts/other/" index)))
    (should (string-match-p "href=\"/tags/lisp/\"" post))
    (should (string-match-p "42" post))
    (should-not (string-match-p "<[a-z]+[^>]*/>" (replace-regexp-in-string
                                                   "<\\(meta\\|link\\)[^>]*/>" "" post)))))

(ert-deftest site-build-feed ()
  (let* ((out (site-test--build nil))
         (feed (car (with-temp-buffer
                      (insert (site-test--read out "atom.xml"))
                      (xml-parse-region (point-min) (point-max))))))
    (should (eq (car feed) 'feed))
    (should (= (length (xml-get-children feed 'entry)) 2))
    (should (string-match-p "https://example.com/posts/hello/" (site-test--read out "atom.xml")))))

(ert-deftest site-build-base-url-override ()
  (let ((out (make-temp-file "site-out" t)))
    (with-environment-variables (("SITE_BASE_URL" "http://localhost:8000"))
      (site-build-site site-test-fixture out nil))
    (should (string-match-p "http://localhost:8000/posts/hello/"
                            (site-test--read out "atom.xml")))))

(ert-deftest site-build-error-keeps-old-output ()
  (let ((out (site-test--build nil))
        (root (site-test--tree '(("site.el" . "")
                                 ("content/posts/x.org" . "#+TITLE: X\n")))))
    (should-error (site-build-site root out nil))
    (should (file-exists-p (expand-file-name "index.html" out)))))

(ert-deftest site-build-template-error-keeps-old-output ()
  (let ((out (site-test--build nil)))
    (cl-letf (((symbol-function 'tpl-post) (lambda (_) (error "boom"))))
      (with-environment-variables (("SITE_BASE_URL" nil))
        (should-error (site-build-site site-test-fixture out nil))))
    (should (file-exists-p (expand-file-name "index.html" out)))))

;;; site-build-test.el ends here
