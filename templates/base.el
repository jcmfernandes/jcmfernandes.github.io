;;; base.el --- Page shell and shared pieces  -*- lexical-binding: t -*-

(defun tpl-nav ()
  "Bracketed site navigation."
  `(nav ((class . "nav"))
        ,@(mapcan (lambda (link)
                    (list "[ " `(a ((href . ,(cdr link))) ,(car link)) " ] "))
                  '(("Blog" . "/") ("About" . "/about/") ("RSS" . "/atom.xml")))))

(defun tpl-tag-links (tags)
  "Comma-separated links to TAGS' pages."
  (cdr (mapcan (lambda (tag)
                 (list ", " `(a ((href . ,(format "/tags/%s/" tag))) ,tag)))
               tags)))

(defun tpl-post-table (posts)
  "Blue table: post title, tags, date."
  `(table ((class . "tissue"))
          (tbody ()
                 ,@(if posts
                       (mapcar (lambda (post)
                                 `(tr ()
                                      (td () (a ((href . ,(plist-get post :url)))
                                                ,(plist-get post :title)))
                                      (td () ,@(or (tpl-tag-links (plist-get post :tags))
                                                   '(" ")))
                                      (td () ,(plist-get post :date))))
                               posts)
                     '((tr () (td () "No posts yet.") (td () " ") (td () " ")))))))

(defconst tpl--live-reload-js
  "(function () {
  var seen = null;
  setInterval(function () {
    fetch('/.build', {cache: 'no-store'})
      .then(function (r) { return r.ok ? r.text() : null; })
      .then(function (id) {
        if (id === null) return;
        if (seen === null) seen = id;
        else if (id !== seen) location.reload();
      })
      .catch(function () {});
  }, 1000);
})();"
  "Preview only: reload the page when /.build changes.")

(defun tpl-base (title body)
  "Full page titled TITLE around BODY, a list of esxml nodes."
  `(html ((lang . "en"))
         (head ()
               (meta ((charset . "utf-8")))
               (meta ((name . "viewport") (content . "width=device-width,initial-scale=1")))
               (title () ,(format ".:: %s ::." title))
               (link ((rel . "stylesheet")
                      (href . ,(if site-css-version
                                   (concat "/style.css?v=" site-css-version)
                                 "/style.css"))))
               (link ((rel . "icon") (type . "image/png") (href . "/favicon.png")))
               (link ((rel . "alternate") (type . "application/atom+xml")
                      (href . "/atom.xml") (title . ,site-title))))
         (body ()
               ,(tpl-nav)
               (header ()
                       (a ((href . "/") (class . "logo"))
                          (img ((src . "/logo.webp") (alt . ,site-title)))))
               (main ((class . "around")) ,@body)
               ,(tpl-nav)
               (footer () ,(format "|=[ EOF ]=---  %s" site-author)
                       ,@(when (and site-commit site-repo-url)
                           `(" | " (a ((href . ,(concat site-repo-url "/commit/" site-commit)))
                                      ,(substring site-commit 0 8)))))
               ,@(when site-live-reload
                   `((script () (raw-string ,tpl--live-reload-js)))))))
;;; base.el ends here
