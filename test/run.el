;;; run.el --- Load and run all tests  -*- lexical-binding: t -*-

(require 'ert)

(dolist (f (directory-files (file-name-directory load-file-name) t "-test\\.el\\'"))
  (load f nil t))

(ert-run-tests-batch-and-exit)
;;; run.el ends here
