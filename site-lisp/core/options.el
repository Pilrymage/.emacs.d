;;; core/options.el --- Global options -*- lexical-binding: t; -*-

(set-language-environment "utf-8")
(set-default-coding-systems 'utf-8-unix)
(set-keyboard-coding-system 'utf-8-unix)
(set-terminal-coding-system 'utf-8-unix)

(setq use-short-answers t
      inhibit-startup-screen t
      auto-mode-case-fold nil)

(push '(tool-bar-lines . 0) default-frame-alist)

(setq frame-resize-pixelwise t
      frame-inhibit-implied-resize t
      tab-width 4
      idle-update-delay 1.0
      fast-but-imprecise-scrolling t
      redisplay-skip-fontification-on-input t)

(setq-default cursor-in-non-selected-windows nil
              cursor-type 'hollow)

(setq highlight-nonselected-windows nil)
(set-locale-environment "en_US.UTF-8")
(setenv "LANG" "en_US.UTF-8")


(setq initial-frame-alist '((top . 0.5)
                            (left . 0.5)
                            (width . 0.628)
                            (height . 0.8)
                            (fullscreen)))

(setq default-frame-alist
      (append '((undecorated-round . t)
                (drag-internal-border . t)
                (internal-border-width . 4))
              default-frame-alist))

(blink-cursor-mode -1)

(defvar data-dir (file-name-as-directory (expand-file-name "data" user-emacs-directory))
  "Root directory for data files.")
(defvar cache-dir (file-name-as-directory (expand-file-name "cache" user-emacs-directory))
  "Root directory for cache files.")
(defvar user-dir (expand-file-name "~/.emacs.d")
  "Canonical user Emacs directory.")

(setq byte-compile-warnings '(not interactive-only))

;; gnupg
(custom-set-variables '(epg-gpg-program "C:/Users/pilrymage/scoop/apps/gnupg/current/bin/gpg.EXE"))

(use-package better-defaults)

(provide 'options)

;;; core/options.el ends here
