;;; modules/editor.el --- Editing enhancements -*- lexical-binding: t; -*-

(use-package recentf
  :config
  (recentf-mode 1)
  (setq recentf-max-saved-items 200)
  )

(defun my/org-timer-record-and-stop-and-done ()
  (interactive)
  (org-timer)
  (org-timer-stop)
  (org-todo 'done))

(defun my/org-clock-out-and-done ()
  (interactive)
  (org-clock-out)
  (org-todo 'done))
(use-package general
  :config
  ;; 1. 为 Org mode 创建一个专用的定义器
  (general-create-definer my/org-leader-def
    :keymaps 'org-mode-map
    :states 'normal
    :prefix "SPC n")

  ;; 2. 直接使用该定义器绑定功能
  (my/org-leader-def
    "a" 'org-toggle-narrow-to-subtree
    "A" 'org-agenda
    "b" 'org-tree-to-indirect-buffer
    "c" 'org-cliplink
    "C" 'org-capture
    "f" 'org-footnote-new
    "g" 'org-goto
    "I" 'org-clock-in
    "O" 'my/org-clock-out-and-done
    "p" 'org-download-clipboard
    "P" 'org-super-links-insert-link
    "q" 'org-set-tags-command
    "S" 'org-sparse-tree
    "t" 'org-todo
    "T" 'org-timestamp
    "Y" 'org-super-links-store-link
    "," 'org-timer-pause-or-continue
    "." 'org-timer
    "0" 'org-timer-start
    "_" 'my/org-timer-record-and-stop-and-done
    "'" 'org-edit-special
    "RET" 'org-ctrl-c-ret
    "TAB" 'org-ctrl-c-tab
    "*" 'org-ctrl-c-star
    "-" 'org-ctrl-c-minus
    ;; 绑定子命令图（Command Map）
    "r" 'verb-command-map))

(use-package rime
  :defer t
  :custom
  (default-input-method "rime")
  :bind (:map rime-mode-map
              ("C-`" . rime-send-keybinding)
              ("`" . rime-inline-ascii))
  :config
  (cond (my/macos-p
         (rime-librime-root (expand-file-name "librime/dist" user-emacs-directory)))
        (my/windows-p
         (setq rime-librime-root "~/scoop/apps/librime/current")
         (setq rime-emacs-module-header-root "~/scoop/apps/emacs/current/include/"))) 
  (global-set-key (kbd "`") #'rime-inline-ascii)
  (setq rime-inline-ascii-holder ?x
        rime-user-data-dir (expand-file-name "rime" user-emacs-directory)))

(defvar +evil-want-o/O-to-continue-comments t
  "If non-nil, the o/O keys will continue comment lines if the point is on a
  line with a linewise comment.")

(defvar +evil-want-move-window-to-wrap-around nil
  "If non-nil, `+evil/window-move-*' commands will wrap around.")

(defvar +evil-preprocessor-regexp "^\\s-*#[a-zA-Z0-9_]"
  "The regexp used by `+evil/next-preproc-directive' and
  `+evil/previous-preproc-directive' on ]# and [#, to jump between preprocessor
  directives. By default, this only recognizes C directives.")

(defvar +snippets-dir (expand-file-name "snippets" user-emacs-directory)
  "Directory that stores personal snippets.")

(defun +evil-embrace-latex-mode-hook-h (&rest _)
  "Placeholder to avoid missing Doom embrace helpers.")

(defun +evil-embrace-angle-bracket-modes-hook-h (&rest _)
  "Placeholder to avoid missing Doom embrace helpers.")

(defun +evil-embrace-scala-mode-hook-h (&rest _)
  "Placeholder to avoid missing Doom embrace helpers.")
(defvar evil-want-Y-yank-to-eol t)
(defvar evil-want-abbrev-expand-on-insert-exit nil)
(defvar evil-respect-visual-line-mode nil)
(defvar evil-want-C-g-bindings t)
(defvar evil-want-C-i-jump nil)  ; we do this ourselves
(defvar evil-want-C-u-scroll t)  ; moved the universal arg to <leader> u
(defvar evil-want-C-u-delete t)
(defvar evil-want-C-w-delete t)
(use-package evil
  :defer t
  :hook (after-init . evil-mode)
  :ensure t
  :preface
  (setq evil-ex-search-vim-style-regexp t
        evil-ex-visual-char-range t  ; column range for ex commands
        evil-mode-line-format 'nil
        ;; more vim-like behavior
        evil-symbol-word-search t
        ;; if the current state is obvious from the cursor's color/shape, then
        ;; we won't need superfluous indicators to do it instead.
        evil-default-cursor '+evil-default-cursor-fn
        evil-normal-state-cursor 'box
        evil-emacs-state-cursor  '(box +evil-emacs-cursor-fn)
        evil-insert-state-cursor 'bar
        evil-visual-state-cursor 'hollow
        ;; Only do highlighting in selected window so that Emacs has less work
        ;; to do highlighting them all.
        evil-ex-interactive-search-highlight 'selected-window
        ;; It's infuriating that innocuous "beginning of line" or "end of line"
        ;; errors will abort macros, so suppress them:
        evil-kbd-macro-suppress-motion-error t
        evil-undo-system 'undo-redo)
  :config
  (evil-select-search-module 'evil-search-module 'evil-search)

  ;; PERF: Stop copying the selection to the clipboard each time the cursor
  ;; moves in visual mode. Why? Because on most non-X systems (and in terminals
  ;; with clipboard plugins like xclip.el active), Emacs will spin up a new
  ;; process to communicate with the clipboard for each movement. On Windows,
  ;; older versions of macOS (pre-vfork), and Waylang (without pgtk), this is
  ;; super expensive and can lead to freezing and/or zombie processes.
  ;;
  ;; UX: It also clobbers clipboard managers (see emacs-evil/evil#336).
  (setq evil-visual-update-x-selection-p nil)
  ;; Start help-with-tutorial in emacs state
  (advice-add #'help-with-tutorial :after (lambda (&rest _) (evil-emacs-state +1)))
  (defun +evil-default-cursor-fn ()
    (evil-set-cursor-color (get 'cursor 'evil-normal-color)))
  (defun +evil-emacs-cursor-fn ()
    (evil-set-cursor-color (get 'cursor 'evil-emacs-color))))

;; Ensure `evil-shift-width' always matches `tab-width'; evil does not police
;; this itself, so we must.
(use-package evil-surround
  :defer t
  :hook (after-init . evil-surround-mode)
  :config
  (global-evil-surround-mode 1)
  (add-to-list 'evil-surround-pairs-alist '(?$ . ("\\(" . "\\)"))))

(use-package evil-commentary
  :defer t
  :hook (after-init . evil-surround-mode)
  :config
  (evil-commentary-mode))
(use-package evil-args
  :defer t)
(use-package evil-easymotion
  :defer t
  :config
  ;; Use evil-search backend, instead of isearch
  (evilem-make-motion evilem-motion-search-next #'evil-ex-search-next
                      :bind ((evil-ex-search-highlight-all nil)))
  (evilem-make-motion evilem-motion-search-previous #'evil-ex-search-previous
                      :bind ((evil-ex-search-highlight-all nil)))
  (evilem-make-motion evilem-motion-search-word-forward #'evil-ex-search-word-forward
                      :bind ((evil-ex-search-highlight-all nil)))
  (evilem-make-motion evilem-motion-search-word-backward #'evil-ex-search-word-backward
                      :bind ((evil-ex-search-highlight-all nil)))
  ;; Rebind scope of w/W/e/E/ge/gE evil-easymotion motions to the visible
  ;; buffer, rather than just the current line.
  (put 'visible 'bounds-of-thing-at-point (lambda () (cons (window-start) (window-end))))
  (evilem-make-motion evilem-motion-forward-word-begin #'evil-forward-word-begin :scope 'visible)
  (evilem-make-motion evilem-motion-forward-WORD-begin #'evil-forward-WORD-begin :scope 'visible)
  (evilem-make-motion evilem-motion-forward-word-end #'evil-forward-word-end :scope 'visible)
  (evilem-make-motion evilem-motion-forward-WORD-end #'evil-forward-WORD-end :scope 'visible)
  (evilem-make-motion evilem-motion-backward-word-begin #'evil-backward-word-begin :scope 'visible)
  (evilem-make-motion evilem-motion-backward-WORD-begin #'evil-backward-WORD-begin :scope 'visible)
  (evilem-make-motion evilem-motion-backward-word-end #'evil-backward-word-end :scope 'visible)
  (evilem-make-motion evilem-motion-backward-WORD-end #'evil-backward-WORD-end :scope 'visible))
(use-package evil-embrace
  :defer t
  :hook (LaTeX-mode . embrace-LaTeX-mode-hook)
  :hook (LaTeX-mode . +evil-embrace-latex-mode-hook-h)
  :hook (org-mode . embrace-org-mode-hook)
  :hook (ruby-mode . embrace-ruby-mode-hook)
  :hook (emacs-lisp-mode . embrace-emacs-lisp-mode-hook)
  :hook ((c++-mode c++-ts-mode rustic-mode csharp-mode java-mode swift-mode typescript-mode)
         . +evil-embrace-angle-bracket-modes-hook-h)
  :hook (scala-mode . +evil-embrace-scala-mode-hook-h)
  :config
  (setq evil-embrace-show-help-p nil))
(use-package evil-exchange
  :defer t)
(use-package evil-indent-plus
  :defer t)
(use-package evil-lion
  :defer t)
(use-package evil-nerd-commenter
  :defer t)
(use-package evil-numbers
  :defer t)
(use-package evil-textobj-anyblock
  :defer t)
(use-package evil-traces
  :config (evil-traces-mode))
(use-package exato
  :defer t
  :commands evil-outer-xml-attr evil-inner-xml-attr)
(use-package evil-quick-diff
  :defer t
  :init (evil-quick-diff-install)
  :straight (evil-quick-diff :host github :repo "rgrinberg/evil-quick-diff"))
;; format
(defcustom +format-on-save-disabled-modes
  '(sql-mode           ; sqlformat is currently broken
    tex-mode           ; latexindent is broken
    latex-mode
    LaTeX-mode
    org-msg-edit-mode) ; doesn't need a formatter
  "A list of major modes in which to not reformat the buffer upon saving.

  If it is t, it is disabled in all modes, the same as if the +onsave flag wasn't
  used at all.
  If nil, formatting is enabled in all modes."
  :type '(list symbol))
;; format +onsave
(defvaralias '+format-with 'apheleia-formatter)
(defvaralias '+format-inhibit 'apheleia-inhibit)
(use-package apheleia
  :defer t
  :hook (after-init . apheleia-global-mode))
;; snippets          ; my elves. They type so I don't have to
(defvar yas-snippet-dirs "~/.emacs.d/yasnippet")

(use-package auto-yasnippet
  :defer t
  :config
  (setq aya-persist-snippets-dir +snippets-dir))

;; ====== emacs ======
;;dired             ; making dired pretty [functionul]
(setq dired-dwim-target t  ; suggest a target for moving/copying intelligently
      ;; don't prompt to revert, just do it
      auto-revert-remote-files t
      ;; Always copy/delete recursively
      dired-recursive-copies  'always
      dired-recursive-deletes 'top
      ;; Ask whether destination dirs should get created when copying/removing files.
      dired-create-destination-dirs 'ask
      ;; Where to store image caches
      image-dired-dir (concat cache-dir "image-dired/")
      image-dired-db-file (concat image-dired-dir "db.el")
      image-dired-gallery-dir (concat image-dired-dir "gallery/")
      image-dired-temp-image-file (concat image-dired-dir "temp-image")
      image-dired-temp-rotate-image-file (concat image-dired-dir "temp-rotate-image")
      ;; Screens are larger nowadays, we can afford slightly larger thumbnails
      image-dired-thumb-size 150)
(evil-set-initial-state 'dired-mode 'emacs)
(use-package dirvish
  :defer t
  :init
  (setq dirvish-cache-dir (concat cache-dir "dirvish"))
  :config
  (dirvish-override-dired-mode)
  (setq dirvish-reuse-session nil)
  (setq dirvish-attributes '(file-size)
        dirvish-mode-line-format
        '(:left (sort file-time symlink) :right (omit yank index)))
  (setq dirvish-attributes nil
        dirvish-use-header-line nil
        dirvish-use-mode-line nil)
  (setq dirvish-subtree-always-show-state t))
(use-package diredfl
  :defer t
  :hook (dired-mode . diredfl-mode)
  :hook (dirvish-directory-view-mode . diredfl-mode))
(use-package dired-x
  :straight nil
  :defer t
  :ensure nil
  :hook (dired-mode . dired-omit-mode)
  :config
  (setq dired-omit-verbose nil
        dired-omit-files
        (concat dired-omit-files
                "\\|^\\.DS_Store\\'"
                "\\|^flycheck_.*"
                "\\|.*归档.*"
                "\\|^\\.project\\(?:ile\\)?\\'"
                "\\|^\\.\\(?:svn\\|git\\)\\'"
                "\\|^\\.ccls-cache\\'"
                "\\|\\(?:\\.js\\)?\\.meta\\'"
                "\\|\\.\\(?:elc\\|o\\|pyo\\|swp\\|class\\)\\'"))
  ;; Disable the prompt about whether I want to kill the Dired buffer for a
  ;; deleted directory. Of course I do!
  (setq dired-clean-confirm-killing-deleted-buffers nil)
  ;; Let OS decide how to open certain files
  (when-let (cmd my/open-command)
    (setq dired-guess-shell-alist-user
          `(("\\.\\(?:docx\\|pdf\\|djvu\\|eps\\)\\'" ,cmd)
            ("\\.\\(?:jpe?g\\|png\\|gif\\|xpm\\)\\'" ,cmd)
            ("\\.\\(?:xcf\\)\\'" ,cmd)
            ("\\.csv\\'" ,cmd)
            ("\\.tex\\'" ,cmd)
            ("\\.\\(?:mp4\\|mkv\\|avi\\|flv\\|rm\\|rmvb\\|ogv\\)\\(?:\\.part\\)?\\'" ,cmd)
            ("\\.\\(?:mp3\\|flac\\)\\'" ,cmd)
            ("\\.html?\\'" ,cmd)
            ("\\.md\\'" ,cmd)))))
(use-package dired-aux
  :straight nil
  :ensure nil
  :defer t
  :init
  (require 'dired-aux)
  :config
  (setq dired-create-destination-dirs 'ask
        dired-vc-rename-file t))
(use-package dired-preview
  :defer t
  :hook (dired-mode . dired-preview-mode))
;;electric          ; smarter, keyword-based electric-indent
(defvar-local +electric-indent-words '()
  "The list of electric words. Typing these will trigger reindentation of the
  current line.")

;;使用 with-eval-after-load 顶替 after!
(with-eval-after-load 'electric
  (setq-default electric-indent-chars '(?\n ?\^?))

  (add-hook 'electric-indent-functions-hook
            (defun +electric-indent-char-fn (_c)
              (when (and (eolp) +electric-indent-words)
                (save-excursion
                  (backward-word)
                  (looking-at-p (concat "\\<" (regexp-opt +electric-indent-words))))))))
;;undo              ; persistent, smarter undo for your inevitable mistakes
(use-package undo-fu
  :defer t
  :hook (window-setup-hook . undo-fu-mode)
  :config
  (setq undo-limit 400000           ; 400kb (default is 160kb)
        undo-strong-limit 3000000   ; 3mb   (default is 240kb)
        undo-outer-limit 48000000)  ; 48mb  (default is 24mb)
  (define-minor-mode undo-fu-mode
    "Enables `undo-fu' for the current session."
    :keymap (let ((map (make-sparse-keymap)))
              (define-key map [remap undo] #'undo-fu-only-undo)
              (define-key map [remap redo] #'undo-fu-only-redo)
              (define-key map (kbd "C-_")     #'undo-fu-only-undo)
              (define-key map (kbd "M-_")     #'undo-fu-only-redo)
              (define-key map (kbd "C-M-_")   #'undo-fu-only-redo-all)
              (define-key map (kbd "C-x r u") #'undo-fu-session-save)
              (define-key map (kbd "C-x r U") #'undo-fu-session-recover)
              map)
    :init-value nil
    :global t))
(use-package undo-fu-session
  :defer t
  :hook (undo-fu-mode . global-undo-fu-session-mode)
  :custom (undo-fu-session-directory (concat cache-dir "undo-fu-session"))
  :config
  (setq undo-fu-session-incompatible-files '("\\.gpg$" "/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))

  (when (executable-find "zstd")
    ;; There are other algorithms available, but zstd is the fastest, and speed
    ;; is our priority within Emacs
    (setq undo-fu-session-compression 'zst)))
(use-package vundo
  :defer t
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols
        vundo-compact-display t))
;;vc                ; version-control and Emacs, sitting in a tree
(setq-default vc-handled-backends '(SVN Git Hg))
;; 设置特定模式的初始状态为 emacs
(with-eval-after-load 'log-view
  (evil-set-initial-state 'log-view-mode 'emacs)
  (evil-set-initial-state 'vc-git-log-view-mode 'emacs)
  (evil-set-initial-state 'vc-hg-log-view-mode 'emacs)
  (evil-set-initial-state 'vc-bzr-log-view-mode 'emacs)
  (evil-set-initial-state 'vc-svn-log-view-mode 'emacs))
(use-package vc :ensure nil
  :defer t)
(use-package vc-annotate
  :straight nil
  :defer t
  :ensure nil
  :config
  (evil-set-initial-state 'vc-annotate-mode 'normal))
(with-eval-after-load 'vc-dir
  (evil-set-initial-state 'vc-dir-mode 'emacs))
(use-package smerge-mode
  :ensure nil
  :defer t
  :config
  (add-hook 'find-file-hook
            (defun +vc-init-smerge-mode-h ()
              (unless (bound-and-true-p smerge-mode)
                (save-excursion
                  (goto-char (point-min))
                  (when (re-search-forward "^<<<<<<< " nil t)
                    (smerge-mode 1)))))))

(use-package browse-at-remote
  :defer t)
(use-package git-timemachine
  :defer t
  :straight (git-timemachine :host github :repo "emacsmirror/git-timemachine")
  :config
  (setq git-timemachine-show-minibuffer-details t)
  (with-eval-after-load 'evil
    (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps)))
(use-package git-modes
  :defer t
  )

(setq evil-shift-width 2)

(defun my/jump-to-user-emacs-directory ()
  (interactive)
  (dired (concat user-emacs-directory "site-lisp")))

(defun repeat-command (proc times)
  "Call PROC a total of TIMES."
  (dotimes (_ times)
    (funcall proc)))

(defun my/previous-five-line ()
  "Move cursor up five lines."
  (interactive)
  (repeat-command #'evil-previous-line 5))

(defun my/next-five-line ()
  "Move cursor down five lines."
  (interactive)
  (repeat-command #'evil-next-line 5))

(defvar my/evil-global-binding
  '(("u" . evil-previous-line)
    ("e" . evil-next-line)
    ("n" . evil-backward-char)
    ("i" . evil-forward-char)
    (",." . evil-jump-item)
    ("m" . evil-forward-word-end)
    ("M" . evil-forward-WORD-end)
    ("U" . my/previous-five-line)
    ("E" . my/next-five-line)
    ("N" . evil-beginning-of-line)
    ("I" . evil-end-of-line)
    ("j" . evil-undo)
    ("l" . evil-insert)
    ("L" . evil-insert-line)
    ("`" . evil-invert-char)
    ("Q" . kill-current-buffer)
    ("M" . execute-extended-command)
    (";" . evil-ex)
    ("h" . evil-backward-word-end)
    ("H" . evil-backward-WORD-end)
    ("k" . evil-ex-search-next)
    ("K" . evil-ex-search-previous)
    ("C-w u" . evil-window-up)
    ("C-w e" . evil-window-down)
    ("C-w n" . evil-window-left)
    ("C-w i" . evil-window-right))
  "Custom Colemak-friendly global Evil bindings.")

(defvar my/evil-insert-binding
  '(("C-p" . previous-line)
    ("C-n" . next-line)
    ("C-f" . forward-char)
    ("C-b" . backward-char)
    ("C-a" . beginning-of-line)
    ("C-d" . org-delete-char)
    ("C-e" . end-of-line)
    ("C-u" . nil)
    ("C-k" . org-kill-line))
  "Insert-state keybindings mirroring common Emacs defaults.")

(with-eval-after-load 'evil
  (dolist (pair my/evil-global-binding)
    (evil-global-set-key 'normal (kbd (car pair)) (cdr pair))
    (evil-global-set-key 'visual (kbd (car pair)) (cdr pair)))
  (dolist (pair my/evil-insert-binding)
    (let* ((key (car pair))
           (fn (cdr pair))
           (resolved (if (and (eq fn 'org-kill-line)
                              (not (fboundp 'org-kill-line)))
                         #'kill-line
                       fn)))
      (evil-global-set-key 'insert (kbd key) resolved)))
  (when (boundp 'evil-motion-state-map)
    (keymap-set evil-motion-state-map "SPC" nil)
    (keymap-set evil-motion-state-map "SPC 0" #'restart-emacs)
    (keymap-set evil-motion-state-map "SPC b" #'previous-buffer)
    (keymap-set evil-motion-state-map "SPC c" #'org-capture)
    (keymap-set evil-motion-state-map "SPC d" #'dired)
    (keymap-set evil-motion-state-map "SPC e" #'elfeed)
    (keymap-set evil-motion-state-map "SPC f" #'find-file)
    (keymap-set evil-motion-state-map "SPC F" #'toggle-frame-fullscreen)
    (keymap-set evil-motion-state-map "SPC g" #'magit)
    (keymap-set evil-motion-state-map "SPC h f" #'helpful-callable)
    (keymap-set evil-motion-state-map "SPC h v" #'helpful-variable)
    (keymap-set evil-motion-state-map "SPC h k" #'helpful-key)
    (keymap-set evil-motion-state-map "SPC h x" #'helpful-command)
    (keymap-set evil-motion-state-map "SPC h d" #'helpful-at-point)
    (keymap-set evil-motion-state-map "SPC h F" #'helpful-function)
    (keymap-set evil-motion-state-map "SPC j" #'org-journal-new-entry)
    (keymap-set evil-motion-state-map "SPC J" #'org-journal-open-current-journal-file)
    (keymap-set evil-motion-state-map "SPC m s" #'bookmark-set)
    (keymap-set evil-motion-state-map "SPC m l" #'list-bookmarks)
    (keymap-set evil-motion-state-map "SPC m j" #'bookmark-jump)
    (keymap-set evil-motion-state-map "SPC q" #'scratch-buffer)
    (keymap-set evil-motion-state-map "SPC r" #'recentf)
    (keymap-set evil-motion-state-map "SPC w" #'my/jump-to-user-emacs-directory)
    (if my/windows-p
        (keymap-set evil-motion-state-map "SPC `" #'eshell)
      (keymap-set evil-motion-state-map "SPC `" #'vterm))))

(use-package pangu-spacing
  :defer t
  :config
  (global-pangu-spacing-mode 1)
  (setq pangu-spacing-real-insert-separtor t))

(use-package magit-delta
  :hook (magit-mode . magit-delta-mode))

(use-package which-key
  :config
  (setq which-key-side-window-max-width 0.5
        which-key-popup-type 'side-window)
  (which-key-mode 1))

(global-set-key (kbd "<f8>") #'execute-extended-command)
(electric-pair-mode 1)
(with-eval-after-load 'electric-pair
  (setq electric-pair-pairs '((?\" . ?\")
                              (?\` . ?\`)
                              (?\( . ?\))
                              (?\[ . ?\])
                              (?\{ . ?\})
                              (?\【 . ?\】)
                              (?\「 . ?\」)
                              (?\《 . ?\》)
                              (?\（ . ?\）))))
(setq show-paren-style 'mixed)
(setopt show-paren-context-when-offscreen t
        blink-matching-paren-highlight-offscreen t)
(setq-default fill-column 80)
(provide 'editor)

;;; modules/editor.el ends here
