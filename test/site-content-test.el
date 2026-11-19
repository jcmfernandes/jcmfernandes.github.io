;;; site-content-test.el --- Tests for site-content  -*- lexical-binding: t -*-

(add-to-list 'load-path (file-name-directory (or load-file-name buffer-file-name)))
(require 'site-test-helper)

(ert-deftest site-parse-date-plain ()
  (should (equal (site-parse-date "2026-11-19") "2026-11-19")))

(ert-deftest site-parse-date-org-timestamp ()
  (should (equal (site-parse-date "<2026-11-19 Thu>") "2026-11-19")))

(ert-deftest site-parse-date-invalid ()
  (should-not (site-parse-date "2026-02-30"))
  (should-not (site-parse-date "19/11/2026"))
  (should-not (site-parse-date nil)))

(ert-deftest site-slug-strips-date-prefix ()
  (should (equal (site-slug "/x/2026-11-19-hello.org") "hello"))
  (should (equal (site-slug "/x/about.md") "about")))

(ert-deftest site-read-item-org-post ()
  (let* ((f (site-test--file "posts/2026-11-19-hello.org"
                             "#+TITLE: Hello João\n#+DATE: <2026-11-19 Thu>\n#+FILETAGS: :lisp:emacs:\n#+DRAFT: t\n\nBody.\n"))
         (item (site-read-item f 'post)))
    (should (equal (plist-get item :title) "Hello João"))
    (should (equal (plist-get item :date) "2026-11-19"))
    (should (equal (plist-get item :tags) '("lisp" "emacs")))
    (should (eq (plist-get item :draft) t))
    (should (eq (plist-get item :format) 'org))
    (should (equal (plist-get item :url) "/posts/hello/"))))

(ert-deftest site-read-item-md-post ()
  (let* ((f (site-test--file "posts/other.md"
                             "---\ntitle: \"A & B *x*\"\ndate: 2026-10-02\ntags: [lisp]\ndraft: true\n---\n\nBody.\n"))
         (item (site-read-item f 'post)))
    (should (equal (plist-get item :title) "A & B x"))
    (should (equal (plist-get item :date) "2026-10-02"))
    (should (equal (plist-get item :tags) '("lisp")))
    (should (eq (plist-get item :draft) t))
    (should (eq (plist-get item :format) 'md))
    (should (equal (plist-get item :url) "/posts/other/"))))

(ert-deftest site-read-item-md-single-tag-string ()
  (let ((f (site-test--file "posts/x.md" "---\ntitle: X\ndate: 2026-01-01\ntags: lisp\n---\n")))
    (should (equal (plist-get (site-read-item f 'post) :tags) '("lisp")))))

(ert-deftest site-read-item-page-and-index-urls ()
  (let ((about (site-test--file "about.org" "#+TITLE: About\n"))
        (index (site-test--file "index.org" "#+TITLE: Home\n")))
    (should (equal (plist-get (site-read-item about 'page) :url) "/about/"))
    (should-not (plist-get (site-read-item about 'page) :date))
    (should (equal (plist-get (site-read-item index 'index) :url) "/"))))

(defun site-test--error-message (thunk)
  (cadr (should-error (funcall thunk) :type 'error)))

(ert-deftest site-read-item-missing-title ()
  (let ((f (site-test--file "about.org" "Just text.\n")))
    (should (string-match-p "about\\.org: missing title"
                            (site-test--error-message (lambda () (site-read-item f 'page)))))))

(ert-deftest site-read-item-post-missing-date ()
  (let ((f (site-test--file "posts/x.org" "#+TITLE: X\n")))
    (should (string-match-p "x\\.org: missing date"
                            (site-test--error-message (lambda () (site-read-item f 'post)))))))

(ert-deftest site-read-item-invalid-date ()
  (let ((f (site-test--file "posts/x.md" "---\ntitle: X\ndate: 2026-13-01\n---\n")))
    (should (string-match-p "x\\.md: invalid date"
                            (site-test--error-message (lambda () (site-read-item f 'post)))))))

(ert-deftest site-read-item-invalid-tag ()
  (let ((f (site-test--file "posts/x.org" "#+TITLE: X\n#+DATE: 2026-01-01\n#+FILETAGS: :Bad_Tag:\n")))
    (should (string-match-p "x\\.org: invalid tag"
                            (site-test--error-message (lambda () (site-read-item f 'post)))))))

(ert-deftest site-read-item-invalid-slug ()
  (let ((f (site-test--file "posts/Hello World.org" "#+TITLE: X\n#+DATE: 2026-01-01\n")))
    (should (string-match-p "Hello World\\.org: invalid slug"
                            (site-test--error-message (lambda () (site-read-item f 'post)))))))

(ert-deftest site-pandoc-failure-names-file ()
  (let ((f (expand-file-name "missing.md" (make-temp-file "site-test" t))))
    (should (string-match-p "missing\\.md: pandoc failed"
                            (site-test--error-message (lambda () (site--pandoc f "-t" "html")))))))
;;; site-content-test.el ends here
