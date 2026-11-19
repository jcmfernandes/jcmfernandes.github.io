;;; site-init.el --- Load pinned packages via straight.el  -*- lexical-binding: t -*-

;;; Commentary:
;; straight.el lives in <repo>/straight/. Packages are pinned by
;; straight/versions/default.el.

;;; Code:

(defvar straight-base-dir
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name)))))

(defvar bootstrap-version)
;; straight.el's upstream default branch is main; "master" lags behind it, which
;; makes thaw/freeze prompt (and fail in batch mode).
(defvar straight-repository-branch "main")
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el"
                         straight-base-dir))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(defconst site-packages '(esxml htmlize)
  "Emacs packages the generator needs.")

(dolist (pkg site-packages)
  (straight-use-package pkg))

(require 'esxml)
(require 'htmlize)

(defun site-deps ()
  "Pin packages to the lockfile, or create the lockfile if missing.
Afterwards copy the lockfile to straight/.thawed, so the devenv task
can skip work until the lockfile changes."
  (let ((lock (expand-file-name "straight/versions/default.el" straight-base-dir)))
    (if (file-exists-p lock)
        (progn
          (straight-thaw-versions)
          (straight-rebuild-all))
      (straight-freeze-versions))
    (copy-file lock (expand-file-name "straight/.thawed" straight-base-dir) t)))

(provide 'site-init)
;;; site-init.el ends here
