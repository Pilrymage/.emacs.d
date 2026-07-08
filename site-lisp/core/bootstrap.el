;;; core/bootstrap.el --- Bootstrapping helpers -*- lexical-binding: t; -*-

(defconst core-site-lisp-dir (expand-file-name "site-lisp/" user-emacs-directory)
  "Root directory that contains custom site-lisp modules.")

(defvar core--default-gc-cons-threshold gc-cons-threshold
  "Remember the original `gc-cons-threshold' so we can restore it after startup.")

;; Defer garbage collection further back in the startup process to speed up init.
(setq gc-cons-threshold most-positive-fixnum)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq package-enable-at-startup nil)

(defun core--update-load-path (&rest _)
  "Ensure `load-path' prioritises local `site-lisp' and `lisp' directories."
  (dolist (dir '("site-lisp" "lisp"))
    (let ((expanded (expand-file-name dir user-emacs-directory)))
      (add-to-list 'load-path expanded))))

(defun core--add-subdirs-to-load-path (&rest _)
  "Add `site-lisp' sub-directories to `load-path'."
  (let ((default-directory (expand-file-name "site-lisp" user-emacs-directory)))
    (when (file-directory-p default-directory)
      (normal-top-level-add-subdirs-to-load-path))))

(advice-add #'package-initialize :after #'core--update-load-path)
(advice-add #'package-initialize :after #'core--add-subdirs-to-load-path)

(core--update-load-path)
(package-initialize)

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(use-package el-patch :straight t)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold core--default-gc-cons-threshold)))

(provide 'bootstrap)

;;; core/bootstrap.el ends here
