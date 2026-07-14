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

(defconst modules-ui--monospace-font-candidates
  '("Iosevka Fixed SS05"
    "Iosevka Term"
    "Iosevka"
    "Cascadia Mono"
    "Menlo"
    "DejaVu Sans Mono"
    "Monospace")
  "Preferred monospaced font families, in priority order.")

(defconst modules-ui--cjk-font-candidates
  '("LXGW WenKai Mono TC"
    "LXGW WenKai Mono TC Regular"
    "LXGW WenKai Mono"
    "Noto Sans SC"
    "Noto Sans CJK SC"
    "Microsoft YaHei UI"
    "PingFang SC")
  "Preferred Chinese and Bopomofo font families, in priority order.")

(defconst modules-ui--japanese-font-candidates
  '("Noto Sans JP"
    "Noto Sans CJK JP"
    "Yu Gothic UI"
    "Hiragino Sans")
  "Preferred Japanese font families, in priority order.")

(defconst modules-ui--korean-font-candidates
  '("Noto Sans KR"
    "Noto Sans CJK KR"
    "Malgun Gothic"
    "Apple SD Gothic Neo")
  "Preferred Korean font families, in priority order.")

(defconst modules-ui--nerd-font-candidates
  '("Symbols Nerd Font Mono" "Symbols Nerd Font")
  "Preferred Nerd Font symbol families, in priority order.")

(defvar modules-ui--default-fontset-configured-p nil
  "Whether the default fontset has received the configured fallbacks.")

(defun modules-ui--emoji-font-candidates ()
  "Return platform-appropriate emoji font families in priority order."
  (cond
   (my/windows-p '("Segoe UI Emoji" "Noto Color Emoji" "Apple Color Emoji"))
   (my/macos-p '("Apple Color Emoji" "Noto Color Emoji" "Segoe UI Emoji"))
   (t '("Noto Color Emoji" "Segoe UI Emoji" "Apple Color Emoji"))))

(defun modules-ui--find-font-family (candidates frame)
  "Return the first installed family from CANDIDATES usable on FRAME."
  (cl-loop for family in candidates
           when (find-font (font-spec :family family) frame)
           return family))

(defun modules-ui--set-fontset-font (characters family frame)
  "Use FAMILY for CHARACTERS in FRAME and, once, the default fontset."
  (when family
    (let ((font (font-spec :family family)))
      (unless modules-ui--default-fontset-configured-p
        (set-fontset-font t characters font nil 'prepend))
      (set-fontset-font nil characters font frame 'prepend))))

(defun modules-ui-apply-fonts (&optional frame)
  "Configure preferred fonts and fallbacks for graphical FRAME."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (let ((monospace (modules-ui--find-font-family
                        modules-ui--monospace-font-candidates frame))
            (cjk (modules-ui--find-font-family
                  modules-ui--cjk-font-candidates frame))
            (japanese (modules-ui--find-font-family
                       modules-ui--japanese-font-candidates frame))
            (korean (modules-ui--find-font-family
                     modules-ui--korean-font-candidates frame))
            (emoji (modules-ui--find-font-family
                    (modules-ui--emoji-font-candidates) frame))
            (nerd (modules-ui--find-font-family
                   modules-ui--nerd-font-candidates frame)))
        (when monospace
          (set-face-attribute 'default frame :family monospace :height 160))
        (dolist (assignment `((han . ,cjk)
                              (bopomofo . ,cjk)
                              (kana . ,japanese)
                              (hangul . ,korean)
                              (emoji . ,emoji)
                              ((#xE000 . #xF8FF) . ,nerd)))
          (modules-ui--set-fontset-font
           (car assignment) (cdr assignment) frame))
        (setq modules-ui--default-fontset-configured-p t)))))

(modules-ui-apply-fonts)
(add-hook 'after-make-frame-functions #'modules-ui-apply-fonts)

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
