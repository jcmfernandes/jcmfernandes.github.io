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

(ert-deftest site-read-item-org-draft-case-insensitive ()
  (let ((f (site-test--file "posts/d.org" "#+TITLE: D\n#+DATE: 2026-01-01\n#+DRAFT: True\n")))
    (should (eq (plist-get (site-read-item f 'post) :draft) t))))

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

(ert-deftest site-render-org-markup ()
  (let ((f (site-test--file "about.org" "#+TITLE: About\n\nSome *bold* text.\n")))
    (should (string-match-p "<b>bold</b>" (site-render-body (site-read-item f 'page))))))

(ert-deftest site-render-org-runs-babel ()
  (let ((f (site-test--file "about.org"
                            "#+TITLE: About\n\n#+begin_src emacs-lisp :exports both\n(* 6 7)\n#+end_src\n")))
    (should (string-match-p "42" (site-render-body (site-read-item f 'page))))))

(ert-deftest site-render-org-code-has-css-classes ()
  (let ((f (site-test--file "about.org"
                            "#+TITLE: About\n\n#+begin_src emacs-lisp\n(defun f () \"s\")\n#+end_src\n")))
    (should (string-match-p "class=\"org-keyword\"" (site-render-body (site-read-item f 'page))))))

(ert-deftest site-render-org-site-absolute-links ()
  (let* ((f (site-test--file "about.org"
                             (concat "#+TITLE: About\n\n"
                                     "[[/posts/hello/][Hello]] [[file:/posts/x/][X]]\n\n"
                                     "[[/images/me.jpg]]\n\n"
                                     "[[../posts/rel/][Rel]] [[https://example.com][Ext]]\n")))
         (html (site-render-body (site-read-item f 'page))))
    (should (string-match-p "href=\"/posts/hello/\"" html))
    (should (string-match-p "href=\"/posts/x/\"" html))
    (should (string-match-p "src=\"/images/me.jpg\"" html))
    (should (string-match-p "href=\"\\.\\./posts/rel/\"" html))
    (should (string-match-p "href=\"https://example.com\"" html))
    (should-not (string-match-p "file://" html))))

(ert-deftest site-render-org-failure-names-file ()
  (let ((f (site-test--file "about.org" "#+TITLE: About\n\n#+INCLUDE: \"nope.org\"\n")))
    (should (string-match-p "about\\.org: org export failed"
                            (site-test--error-message
                             (lambda () (site-render-body (site-read-item f 'page))))))))

(ert-deftest site-render-md ()
  (let* ((f (site-test--file "about.md" "---\ntitle: About\n---\n\nHello *world*.\n"))
         (html (site-render-body (site-read-item f 'page))))
    (should (string-match-p "<em>world</em>" html))
    (should-not (string-match-p "title:" html))))

(ert-deftest site-render-org-alert ()
  (let ((f (site-test--file "about.org"
                            "#+TITLE: About\n\n#+begin_important\nA *hard* fork.\n#+end_important\n")))
    (should (string-match-p "<div class=\"important\"[^>]*>[[:space:]]*<p>[[:space:]]*A <b>hard</b> fork."
                            (site-render-body (site-read-item f 'page))))))

(ert-deftest site-render-org-stable-ids ()
  (let* ((f (site-test--file "about.org"
                             "#+TITLE: About\n\n#+begin_note\nHi.\n#+end_note\n"))
         (html (site-render-body (site-read-item f 'page))))
    (random t)
    (should (string-match-p "id=\"org[0-9a-f]+\"" html))
    (should (equal html (site-render-body (site-read-item f 'page))))))

(defconst site-test--toc-body
  "\n* One\n:PROPERTIES:\n:CUSTOM_ID: one\n:END:\nA\n** Sub\nB\n* Two\n:PROPERTIES:\n:CUSTOM_ID: two\n:END:\nC\n")

(ert-deftest site-render-org-post-has-toc ()
  (let* ((f (site-test--file "posts/2026-11-23-toc.org"
                             (concat "#+TITLE: T\n#+DATE: 2026-11-23\n" site-test--toc-body)))
         (html (site-render-body (site-read-item f 'post)))
         (toc (and (string-match "<nav id=\"table-of-contents\"\\(?:.\\|\n\\)*?</nav>" html)
                   (match-string 0 html))))
    (should toc)
    (should (string-match-p "<a href=\"#one\">One</a>" toc))
    (should (string-match-p "<a href=\"#two\">Two</a>" toc))
    (should-not (string-match-p "Sub" toc))
    (should (string-match-p "<h2><a href=\"#table-of-contents\">Table of Contents</a></h2>" toc))))

(ert-deftest site-render-org-post-toc-opt-out ()
  (let ((f (site-test--file "posts/2026-11-23-toc.org"
                            (concat "#+TITLE: T\n#+DATE: 2026-11-23\n#+OPTIONS: toc:nil\n"
                                    site-test--toc-body))))
    (should-not (string-match-p "table-of-contents"
                                (site-render-body (site-read-item f 'post))))))

(ert-deftest site-render-org-page-has-no-toc ()
  (let ((f (site-test--file "about.org" (concat "#+TITLE: About\n" site-test--toc-body))))
    (should-not (string-match-p "table-of-contents"
                                (site-render-body (site-read-item f 'page))))))

(ert-deftest site-render-org-headings-link-to-themselves ()
  (let ((f (site-test--file "about.org" (concat "#+TITLE: About\n" site-test--toc-body))))
    (should (string-match-p "<h2 id=\"one\"><a href=\"#one\">One</a></h2>"
                            (site-render-body (site-read-item f 'page))))))

(ert-deftest site-slugify ()
  (should (equal (site--slugify "What to say?") "what-to-say"))
  (should (equal (site--slugify "  João's café, 2026! ") "joao-s-cafe-2026"))
  (should (equal (site--slugify "?!") "")))

(ert-deftest site-render-org-heading-ids-from-titles ()
  (let* ((f (site-test--file "about.org"
                             (concat "#+TITLE: About\n\n"
                                     "* What to say?\n** Sub\n* What to say?\n"
                                     "* See [[https://example.com][the site]]\n"
                                     "* Kept\n:PROPERTIES:\n:CUSTOM_ID: mine\n:END:\n")))
         (html (site-render-body (site-read-item f 'page))))
    (should (string-match-p "<h2 id=\"what-to-say\">" html))
    (should (string-match-p "<h3 id=\"sub\">" html))
    (should (string-match-p "<h2 id=\"what-to-say-2\">" html))
    (should (string-match-p "<h2 id=\"see-the-site\">" html))
    (should (string-match-p "<h2 id=\"mine\">" html))))

(defconst site-test--numbered-body
  (concat "\n* What to say?\n** Sub\n* Kept\n:PROPERTIES:\n:CUSTOM_ID: mine\n:END:\n"
          "* COMMENT Hidden\n* Gone :noexport:\n* Last\n"))

(ert-deftest site-render-org-numbered-heading-ids ()
  (let* ((f (site-test--file "posts/2026-11-23-ids.org"
                             (concat "#+TITLE: T\n#+DATE: 2026-11-23\n" site-test--numbered-body)))
         (html (site-render-body (site-read-item f 'post))))
    (should (string-match-p "<h2 id=\"---0x00---what-to-say\">" html))
    (should (string-match-p "<h3 id=\"sub\">" html))
    (should (string-match-p "<h2 id=\"mine\">" html))
    (should (string-match-p "<h2 id=\"---0x02---last\">" html))))

(ert-deftest site-render-org-numbered-heading-ids-with-toc-keyword ()
  (let ((f (site-test--file "posts/2026-11-23-ids.org"
                            (concat "#+TITLE: T\n#+DATE: 2026-11-23\n#+OPTIONS: toc:nil\n"
                                    "#+TOC: headlines 1\n" site-test--numbered-body))))
    (should (string-match-p "<h2 id=\"---0x00---what-to-say\">"
                            (site-render-body (site-read-item f 'post))))))

(ert-deftest site-render-org-unnumbered-heading-ids-without-toc ()
  (let ((f (site-test--file "posts/2026-11-23-ids.org"
                            (concat "#+TITLE: T\n#+DATE: 2026-11-23\n#+OPTIONS: toc:nil\n"
                                    site-test--numbered-body))))
    (should (string-match-p "<h2 id=\"what-to-say\">"
                            (site-render-body (site-read-item f 'post))))))

(ert-deftest site-render-md-alerts ()
  (let* ((f (site-test--file "about.md"
                             (concat "---\ntitle: About\n---\n\n"
                                     "> [!IMPORTANT]  \n> A **hard** fork.\n> Really.\n\n"
                                     "> [!WARNING]\n> Hot.\n\n"
                                     "> [!BOGUS]\n> Kept.\n\n"
                                     "> Plain quote.\n")))
         (html (site-render-body (site-read-item f 'page))))
    (should (string-match-p "<div class=\"important\">[[:space:]]*<p>A <strong>hard</strong> fork.[[:space:]]Really.</p>" html))
    (should (string-match-p "<div class=\"warning\">[[:space:]]*<p>Hot.</p>" html))
    (should (string-match-p "<blockquote>[[:space:]]*<p>\\[!BOGUS\\]" html))
    (should (string-match-p "<blockquote>[[:space:]]*<p>Plain quote.</p>" html))))

(ert-deftest site-with-html-appends-html ()
  (let ((f (site-test--file "about.md" "---\ntitle: About\n---\n\nHi.\n")))
    (should (string-match-p "<p>Hi.</p>"
                            (plist-get (site-with-html (site-read-item f 'page)) :html)))))
;;; site-content-test.el ends here
