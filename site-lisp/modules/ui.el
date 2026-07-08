;;; modules/ui.el --- Look & feel -*- lexical-binding: t; -*-

(require 'cl-lib)

;; Prevent flashing of the modeline during startup.
(setq-default mode-line-format nil)
(setq warning-minimum-level :error)

(load-theme 'modus-operandi-deuteranopia t)

;; Vertical window divider
(use-package frame
  :straight (:type built-in)
  :custom
  (window-divider-default-right-width 12)
  (window-divider-default-bottom-width 1)
  (window-divider-default-places 'right-only)
  (window-divider-mode t))
;; Make sure new frames use window-divider
(add-hook 'before-make-frame-hook 'window-divider-mode)

(if my/linux-p
    (setq default-frame-alist '((undecorated . t))))
(if my/macos-p
    (setq default-frame-alist '((ns-transparent-titlebar . t))))


(use-package emojify
  :hook (after-init . global-emojify-mode)
  :config
  (emojify-set-emoji-styles '(unicode)))

(defun modules-ui-setup-fonts ()
  "Configure default fonts for the current frame."
  (when (display-graphic-p)
    (cl-loop for font in '("Iosevka Term")
             thereis (set-face-attribute 'default nil :family font :height 160))
    (cl-loop for font in '("Segoe UI Symbol" "Symbola" "Symbol")
             thereis (if (< emacs-major-version 27)
                         (set-fontset-font "fontset-default" 'unicode font nil 'prepend)
                       (set-fontset-font t 'symbol (font-spec :family font) nil 'prepend)))
    (cl-loop for font in '("Noto Color Emoji" "Apple Color Emoji" "Segoe UI Emoji")
             thereis (cond
                      ((< emacs-major-version 27)
                       (set-fontset-font "fontset-default" 'unicode font nil 'prepend))
                      ((< emacs-major-version 28)
                       (set-fontset-font t 'symbol (font-spec :family font) nil 'prepend))
                      (t
                       (set-fontset-font t 'emoji (font-spec :family font) nil 'prepend))))
    (cl-loop for font in '("LXGW WenKai Mono TC")
             thereis (set-fontset-font t 'han (font-spec :family font)))))

(modules-ui-setup-fonts)
(add-hook 'window-setup-hook #'modules-ui-setup-fonts)
(add-hook 'server-after-make-frame-hook #'modules-ui-setup-fonts)

(use-package hl-todo
  :hook ((prog-mode yaml-mode) . hl-todo-mode)
  :config
  (setq hl-todo-highlight-punctuation ":"
        hl-todo-keyword-faces
        '(("TODO" warning bold)
          ("FIXME" error bold)
          ("REVIEW" font-lock-keyword-face bold)
          ("HACK" font-lock-constant-face bold)
          ("DEPRECATED" font-lock-doc-face bold)
          ("NOTE" success bold)
          ("BUG" error bold)
          ("XXX" font-lock-constant-face bold))))

(use-package indent-bars
  :hook (prog-mode . indent-bars-mode))

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :init
  (setq projectile-dynamic-mode-line nil
        doom-modeline-bar-width 3
        doom-modeline-github nil
        doom-modeline-mu4e nil
        doom-modeline-persp-name nil
        doom-modeline-minor-modes nil
        doom-modeline-major-mode-icon nil
        doom-modeline-buffer-file-name-style 'relative-from-project
        doom-modeline-buffer-encoding 'nondefault
        doom-modeline-default-eol-type 0))

(use-package pulsar
  :defer t)

(defun modules-ui--neotree-no-confirm (&rest _)
  "Disable confirmation prompts used by Neotree."
  nil)

(use-package neotree
  :commands (neotree-show
             neotree-hide
             neotree-toggle
             neotree-dir
             neotree-find
             neo-global--with-buffer
             neo-global--window-exists-p)
  :init
  (setq neo-create-file-auto-open nil
        neo-auto-indent-point nil
        neo-autorefresh nil
        neo-mode-line-type 'none
        neo-window-width 30
        neo-show-updir-line nil
        neo-theme 'nerd
        neo-banner-message nil
        neo-confirm-create-file #'modules-ui--neotree-no-confirm
        neo-confirm-create-directory #'modules-ui--neotree-no-confirm
        neo-show-hidden-files t
        neo-keymap-style 'concise
        neo-hidden-regexp-list
        '("^\\.\\(?:git\\|hg\\|svn\\)$"
          "\\.\\(?:pyc\\|o\\|elc\\|lock\\|css\\.map\\|class\\)$"
          "^\\(?:node_modules\\|vendor\\|\\.\\(?:project\\|cask\\|yardoc\\|sass-cache\\)\\)$"
          "^\\.\\(?:sync\\|export\\|attach\\)$"
          "~$"
          "^#.*#$")))

(use-package unicode-fonts
  :defer t)

(use-package diff-hl
  :hook (after-init . global-diff-hl-mode)
  :config
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))

(use-package blamer
  :defer t
  :bind (("s-i" . blamer-show-commit-info)
         ("C-c i" . blamer-show-posframe-commit-info))
  :config
  (setq blamer-idle-time 0.3
        blamer-min-offset 20
        blamer--overlay-popup-position 'smart))

(use-package writeroom-mode
  :defer t
  :config
  (defvar +zen--old-writeroom-global-effects writeroom-global-effects)
  (setq writeroom-global-effects nil
        writeroom-maximize-window nil))

(defvar +zen-mixed-pitch-modes
  '(markdown-mode org-mode text-mode)
  "Modes that should enable `mixed-pitch-mode' when in writeroom.")

(use-package mixed-pitch
  :hook (writeroom-mode . +zen-enable-mixed-pitch-mode-h)
  :config
  (defun +zen-enable-mixed-pitch-mode-h ()
    "Toggle `mixed-pitch-mode' when the current mode supports it."
    (if (and writeroom-mode
             (apply #'derived-mode-p +zen-mixed-pitch-modes))
        (mixed-pitch-mode +1)
      (mixed-pitch-mode -1))))

(use-package minions
  :hook (doom-modeline-mode . minions-mode))

(use-package nerd-icons
  :defer t)

(use-package display-line-numbers
  :ensure nil
  :hook ((prog-mode yaml-mode yaml-ts-mode conf-mode org-mode) . display-line-numbers-mode)
  :init
  (setq display-line-numbers-width-start t
        display-line-numbers-type t))

(setq use-file-dialog nil
      use-dialog-box nil
      inhibit-startup-echo-area-message user-login-name
      inhibit-default-init t
      initial-scratch-message nil)

(unless (daemonp)
  (advice-add #'display-startup-echo-area-message :override #'ignore))

(use-package time
  :ensure nil
  :init
  (setq display-time-default-load-average nil
        display-time-format "%H:%M"))

(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

(setq scroll-step 1
      scroll-margin 4
      scroll-conservatively 100000
      auto-window-vscroll nil
      scroll-preserve-screen-position t)

(provide 'ui)

;;; modules/ui.el ends here
