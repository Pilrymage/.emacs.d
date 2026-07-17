;;; modules/ui.el --- Look & feel -*- lexical-binding: t; -*-

(require 'cl-lib)

(mapc #'disable-theme custom-enabled-themes)
(load-theme 'modus-operandi-deuteranopia t)

;; Vertical window divider
(use-package frame
  :straight nil
  :init
  (setq window-divider-default-right-width 12
        window-divider-default-bottom-width 1
        window-divider-default-places 'right-only)
  :config
  (window-divider-mode 1))

(when my/linux-p
  (setf (alist-get 'undecorated default-frame-alist) t))
(when my/macos-p
  (setf (alist-get 'ns-transparent-titlebar default-frame-alist) t))

(defconst modules-ui--monospace-font-candidates
  '("Iosevka Mono"
    "Iosevka Term"
    "Iosevka"
    "Cascadia Mono"
    "Sarasa Mono Slab TC"
    "Menlo"
    "DejaVu Sans Mono"
    "Monospace")
  "Preferred monospaced font families, in priority order.")

(defconst modules-ui--cjk-font-candidates
  '(;"Sarasa Mono Slab TC"
    "LXGW WenKai Mono TC"
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

(defconst modules-ui--variable-pitch-font-candidates
  '("LXGW WenKai"
    "LXGW WenKai TC"
    "Noto Sans"
    "Segoe UI"
    "Helvetica"
    "Sans Serif")
  "Preferred proportional font families, in priority order.")

(defvar modules-ui-cjk-font-scale 1.0
  "Scale applied to the selected CJK font family.")

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

(defun modules-ui--set-fontset-font (characters family frame &optional add)
  "Use FAMILY for CHARACTERS in FRAME and the default fontset.
ADD has the same meaning as in `set-fontset-font'."
  (when family
    (let ((font (font-spec :family family)))
      (set-fontset-font t characters font nil add)
      (set-fontset-font nil characters font frame add))))

(defun modules-ui--set-cjk-font-scale (family)
  "Set the configured rescaling factor for CJK font FAMILY."
  (when family
    (let ((family-pattern (regexp-quote family)))
      (setq face-font-rescale-alist
            (cons (cons family-pattern modules-ui-cjk-font-scale)
                  (cl-remove-if
                   (lambda (entry)
                     (member (car entry)
                             (mapcar #'regexp-quote
                                     modules-ui--cjk-font-candidates)))
                   face-font-rescale-alist))))))

(defun modules-ui-apply-fonts (&optional frame)
  "Configure preferred fonts and fallbacks for graphical FRAME."
  (interactive)
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (let ((monospace (modules-ui--find-font-family
                        modules-ui--monospace-font-candidates frame))
            (variable-pitch (modules-ui--find-font-family
                             modules-ui--variable-pitch-font-candidates frame))
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
          (set-face-attribute 'default frame :family monospace :height 160)
          (set-face-attribute 'fixed-pitch frame :family monospace))
        (when variable-pitch
          (set-face-attribute 'variable-pitch frame :family variable-pitch))
        (modules-ui--set-cjk-font-scale cjk)
        (dolist (assignment `((han . ,cjk)
                              (bopomofo . ,cjk)
                              (kana . ,japanese)
                              (hangul . ,korean)
                              (emoji . ,emoji)))
          (modules-ui--set-fontset-font
           (car assignment) (cdr assignment) frame))
        ;; Prefer symbols supplied by the primary monospace font and use the
        ;; Nerd Font only for missing private-use glyphs.
        (when monospace
          (modules-ui--set-fontset-font '(#xE000 . #xF8FF)
                                        monospace frame))
        (modules-ui--set-fontset-font '(#xE000 . #xF8FF)
                                      nerd frame 'append)))))

(modules-ui-apply-fonts)
(add-hook 'after-make-frame-functions #'modules-ui-apply-fonts)

(use-package hl-todo
  :hook ((prog-mode yaml-mode yaml-ts-mode) . hl-todo-mode)
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
  :hook ((prog-mode yaml-mode yaml-ts-mode) . indent-bars-mode))

(use-package doom-modeline
  :init
  (setq doom-modeline-bar-width 3
        doom-modeline-major-mode-icon nil
        doom-modeline-buffer-file-name-style 'relative-from-project
        doom-modeline-buffer-encoding 'nondefault)
  :config
  (doom-modeline-mode 1))

(use-package diff-hl
  :config
  (global-diff-hl-mode 1)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))

(defun modules-ui--sync-mixed-pitch-mode ()
  "Keep `mixed-pitch-mode' in sync with `writeroom-mode'."
  (mixed-pitch-mode (if writeroom-mode 1 -1)))

(use-package writeroom-mode
  :hook (org-mode . writeroom-mode)
  :init
  (setq writeroom-global-effects nil
        writeroom-maximize-window nil))

(use-package mixed-pitch
  :commands mixed-pitch-mode
  :hook (writeroom-mode . modules-ui--sync-mixed-pitch-mode))

(use-package nerd-icons
  :defer t)

(use-package display-line-numbers
  :straight nil
  :hook ((prog-mode yaml-mode yaml-ts-mode conf-mode)
         . display-line-numbers-mode)
  :init
  (setq display-line-numbers-width-start t
        display-line-numbers-type 'relative))

(setq use-file-dialog nil
      use-dialog-box nil
      inhibit-startup-echo-area-message user-login-name
      inhibit-default-init t
      initial-scratch-message nil)

(when (fboundp 'pixel-scroll-precision-mode)
  (setq pixel-scroll-precision-use-momentum t)
  (pixel-scroll-precision-mode 1))

(setq scroll-margin 4
      scroll-preserve-screen-position t)

(provide 'ui)

;;; modules/ui.el ends here
