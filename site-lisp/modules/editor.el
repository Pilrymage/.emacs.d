;;; modules/editor.el --- Editing enhancements -*- lexical-binding: t; -*-

(use-package general
  :demand t
  :config
  (general-create-definer my/evil-normal-def
    :states '(normal visual))

  (general-create-definer my/evil-insert-def
    :states '(insert))

  (general-create-definer my/leader-def
    :states '(normal visual motion)
    :prefix "SPC")

  (general-create-definer my/mode-leader-def
    :states '(normal visual)
    :prefix "SPC n")

  (general-define-key
   "<f8>" #'execute-extended-command
   "`" #'rime-inline-ascii)

  (with-eval-after-load 'evil
    (my/evil-normal-def
      ;; Colemak movement
      "u" #'evil-previous-line
      "e" #'evil-next-line
      "n" #'evil-backward-char
      "i" #'evil-forward-char
      "U" #'my/previous-five-lines
      "E" #'my/next-five-lines
      "N" #'evil-beginning-of-line
      "I" #'evil-end-of-line
      ;; Editing and commands
      ",." #'evil-jump-item
      "m" #'evil-forward-word-end
      "j" #'evil-undo
      "l" #'evil-insert
      "L" #'evil-insert-line
      "`" #'evil-invert-char
      "Q" #'kill-current-buffer
      "M" #'execute-extended-command
      ";" #'evil-ex
      "g +" '(evil-numbers/inc-at-pt :which-key "increment number")
      "g -" '(evil-numbers/dec-at-pt :which-key "decrement number")
      ;; Word and search motions
      "h" #'evil-backward-word-begin
      "H" #'evil-backward-WORD-begin
      "k" #'evil-ex-search-next
      "K" #'evil-ex-search-previous
      "w" #'evilem-motion-forward-word-begin
      "W" #'evilem-motion-forward-WORD-begin
      "b" #'evilem-motion-backward-word-begin
      "B" #'evilem-motion-backward-WORD-begin
      ;; Windows
      "C-w u" #'evil-window-up
      "C-w e" #'evil-window-down
      "C-w n" #'evil-window-left
      "C-w i" #'evil-window-right)

    (my/evil-insert-def
      ;; Line editing
      "C-a" #'beginning-of-line
      "C-e" #'end-of-line
      "C-k" #'kill-line
      ;; Character and word editing
      "C-f" #'forward-char
      "C-b" #'backward-char
      "M-f" #'forward-word
      "M-b" #'backward-word
      "C-p" #'previous-line
      "C-n" #'next-line
      "C-d" #'delete-char
      "M-d" #'kill-word
      "C-u" nil
      "C-y" #'yank)

    ;; Evil binds bare SPC in motion state by default; clear it before using
    ;; SPC as a leader prefix.
    (general-define-key
     :states '(normal visual motion)
     "SPC" nil)

    (my/leader-def
      "b" '(:ignore t :which-key "buffer")
      "b b" '(consult-buffer :which-key "switch buffer")
      "b p" '(previous-buffer :which-key "previous")
      "f" '(:ignore t :which-key "file")
      "f f" '(find-file :which-key "find file")
      "f r" '(consult-recent-file :which-key "recent files")
      "f d" '(consult-fd :which-key "find project file")
      "f D" '(consult-dir :which-key "change directory")
      "f e" '(my/open-config-directory :which-key "Emacs config")
      "s" '(:ignore t :which-key "search")
      "s l" '(consult-line :which-key "search buffer")
      "s r" '(consult-ripgrep :which-key "search project")
      "g" '(magit :which-key "Magit")
      "h" '(:ignore t :which-key "help")
      "h f" '(helpful-callable :which-key "callable")
      "h v" '(helpful-variable :which-key "variable")
      "h k" '(helpful-key :which-key "key")
      "h x" '(helpful-command :which-key "command")
      "h d" '(helpful-at-point :which-key "at point")
      "h F" '(helpful-function :which-key "function")
      "n" '(:ignore t :which-key "major mode")
      "o" '(:ignore t :which-key "open")
      "o c" '(org-capture :which-key "capture")
      "o d" '(dirvish :which-key "Dirvish")
      "o e" '(elfeed :which-key "Elfeed")
      "o j" '(org-journal-new-entry :which-key "new journal entry")
      "o J" '(org-journal-open-current-journal-file :which-key "today's journal")
      "o s" '(dirvish-side :which-key "Dirvish sidebar")
      "m" '(:ignore t :which-key "bookmarks")
      "m s" '(bookmark-set :which-key "set")
      "m l" '(list-bookmarks :which-key "list")
      "m j" '(bookmark-jump :which-key "jump")
      "q" '(:ignore t :which-key "session")
      "q s" '(scratch-buffer :which-key "scratch buffer")
      "q r" '(restart-emacs :which-key "restart Emacs")
      "t" '(:ignore t :which-key "toggle")
      "t f" '(toggle-frame-fullscreen :which-key "fullscreen"))

    (if my/windows-p
        (my/leader-def "o t" '(eshell :which-key "terminal"))
      (my/leader-def "o t" '(vterm :which-key "terminal")))

    (my/mode-leader-def
      :keymaps 'org-mode-map
      "a" '(org-toggle-narrow-to-subtree :which-key "narrow subtree")
      "A" '(org-agenda :which-key "agenda")
      "b" '(org-tree-to-indirect-buffer :which-key "indirect buffer")
      "c" '(org-cliplink :which-key "clip link")
      "C" '(org-capture :which-key "capture")
      "f" '(org-footnote-new :which-key "new footnote")
      "g" '(org-goto :which-key "goto")
      "I" '(org-clock-in :which-key "clock in")
      "O" '(my/org-clock-out-and-done :which-key "clock out and done")
      "p" '(org-download-clipboard :which-key "download clipboard")
      "P" '(org-super-links-insert-link :which-key "insert super link")
      "q" '(org-set-tags-command :which-key "set tags")
      "r" '(:keymap verb-command-map :package verb :which-key "verb")
      "S" '(org-sparse-tree :which-key "sparse tree")
      "t" '(org-todo :which-key "todo")
      "T" '(org-timestamp :which-key "timestamp")
      "Y" '(org-super-links-store-link :which-key "store super link")
      "," '(org-timer-pause-or-continue :which-key "pause or resume timer")
      "." '(org-timer :which-key "record timer")
      "0" '(org-timer-start :which-key "start timer")
      "_" '(my/org-timer-record-and-stop-and-done
            :which-key "record, stop, and done")
      "'" '(org-edit-special :which-key "edit special")
      "RET" '(org-ctrl-c-ret :which-key "ctrl-c return")
      "TAB" '(org-ctrl-c-tab :which-key "ctrl-c tab")
      "*" '(org-ctrl-c-star :which-key "ctrl-c star")
      "-" '(org-ctrl-c-minus :which-key "ctrl-c minus"))

    (my/mode-leader-def
      :keymaps 'agda2-mode-map
      "l" '(agda2-load :which-key "load")
      "b" '(agda2-previous-goal :which-key "previous goal")
      "f" '(agda2-next-goal :which-key "next goal")
      "c" '(agda2-make-case :which-key "case split")
      "g" '(agda2-give :which-key "fill goal")
      "r" '(agda2-refine :which-key "refine")
      "a" '(agda2-mimer-maybe-all :which-key "solve all goals")
      "," '(agda2-goal-and-context :which-key "goal and context")
      "." '(agda2-goal-and-context-and-inferred
            :which-key "goal, context, and inferred type")
      "h" '(agda2-helper-function-type :which-key "helper function type"))))

(use-package which-key
  :demand t
  :config
  (setq which-key-side-window-max-width 0.5
        which-key-popup-type 'side-window)
  (which-key-mode 1))

(use-package evil
  :hook (after-init . evil-mode)
  :init
  (setq evil-want-Y-yank-to-eol t
        evil-want-abbrev-expand-on-insert-exit nil
        evil-respect-visual-line-mode t
        evil-want-C-g-bindings t
        evil-want-C-i-jump nil
        evil-want-C-u-scroll nil
        evil-want-C-u-delete nil
        evil-want-C-w-delete nil)
  (setq evil-ex-search-vim-style-regexp t ; vim 正则而非 emacs
        evil-ex-visual-char-range t  ; ex 命令按列范围
        evil-mode-line-format 'nil   ; doom modeline 配合显示 evil 状态
        ;; more vim-like behavior
        evil-symbol-word-search t    ; 横线分隔单词看作一个词： this-is-a-symbol 是一词
        ;; if the current state is obvious from the cursor's color/shape, then
        ;; we won't need superfluous indicators to do it instead.
        evil-normal-state-cursor 'box
        evil-emacs-state-cursor  'box
        evil-insert-state-cursor 'bar
        evil-visual-state-cursor 'hollow
        ;; 只在当前窗口高亮匹配，提升性能
        evil-ex-interactive-search-highlight 'selected-window
        ;; 0 $ 移动不会因为已经在边界而被打断
        evil-kbd-macro-suppress-motion-error t
        ;; 使用 Emacs 原生 undo 而非 evil 模拟
        evil-undo-system 'undo-redo)
  :config
  (evil-select-search-module 'evil-search-module 'evil-search) ; evil 搜索而非 isearch
  ;; visual mode 下光标移动不许每次更新系统剪贴板，必要优化
  (setq evil-visual-update-x-selection-p nil)
  (evil-set-initial-state 'dired-mode 'emacs)
  (evil-set-initial-state 'log-view-mode 'emacs)
  (evil-set-initial-state 'vc-git-log-view-mode 'emacs)
  (evil-set-initial-state 'vc-hg-log-view-mode 'emacs)
  (evil-set-initial-state 'vc-bzr-log-view-mode 'emacs)
  (evil-set-initial-state 'vc-svn-log-view-mode 'emacs)
  (evil-set-initial-state 'vc-dir-mode 'emacs)
  (evil-set-initial-state 'vc-annotate-mode 'normal))

(use-package evil-surround
  :config
  (global-evil-surround-mode 1)
  (add-to-list 'evil-surround-pairs-alist '(?$ . ("\\(" . "\\)"))))

;; 注释：vgc, gcc
(use-package evil-commentary
  :config
  (evil-commentary-mode 1))

(use-package evil-numbers :defer t)

;; avy 代替
(use-package evil-easymotion
  :config
  (setq evilem-keys
        '(
          ?t ?n
          ?s  ?e
          ?r   ?i
          ?a    ?o
          ?d     ?h
          ?g ?m ?p ?l ?f ?u ?w ?y ?v ?k ?c ?b ?j ?, ?x ?. ?q ?\; ?z
          ))
  (setq evilem-style 'at-full)
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
  (evilem-make-motion evilem-motion-backward-WORD-begin #'evil-backward-WORD-begin :scope 'visible))


;; ex 状态实时预览
(use-package evil-traces
  :config (evil-traces-mode))

;; format +onsave
(use-package apheleia
  :hook (after-init . apheleia-global-mode))

;; snippets          ; my elves. They type so I don't have to
(defconst modules-editor--snippets-directory
  (expand-file-name "yasnippet" user-emacs-directory)
  "Directory that stores personal snippets.")

(use-package yasnippet
  :config
  (setq yas-snippet-dirs (list modules-editor--snippets-directory))
  (yas-global-mode 1))

(use-package auto-yasnippet
  :defer t
  :init
  (setq aya-persist-snippets-dir modules-editor--snippets-directory))

;; ====== emacs ======
;; dired             ; making dired pretty [functional]
(use-package dired
  :straight nil
  :init
  (setq dired-dwim-target t
        auto-revert-remote-files t
        dired-recursive-copies 'always
        dired-recursive-deletes 'top
        dired-create-destination-dirs 'ask
        dired-vc-rename-file t
        image-dired-dir (concat cache-dir "image-dired/")
        image-dired-db-file (concat image-dired-dir "db.el")
        image-dired-gallery-dir (concat image-dired-dir "gallery/")
        image-dired-temp-image-file (concat image-dired-dir "temp-image")
        image-dired-temp-rotate-image-file (concat image-dired-dir "temp-rotate-image")
        image-dired-thumb-size 150))

(use-package dirvish
  :init
  (setq dirvish-cache-dir (concat cache-dir "dirvish"))
  :config
  (dirvish-override-dired-mode)
  (setq dirvish-reuse-session nil
        dirvish-attributes
        '(vc-state subtree-state nerd-icons collapse
                   git-msg file-modes file-time file-size)
        dirvish-mode-line-format
        '(:left (sort file-time " " file-size symlink)
          :right (omit yank index))
        dirvish-use-header-line 'global
        dirvish-use-mode-line 'global
        dirvish-subtree-always-show-state t))

(use-package diredfl
  :hook ((dired-mode . diredfl-mode)
         (dirvish-directory-view-mode . diredfl-mode)))

(use-package dired-x
  :straight nil
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
;;undo              ; persistent, smarter undo for your inevitable mistakes
(use-package undo-fu
  :defer t
  :init
  (setq undo-limit 400000           ; 400kb (default is 160kb)
        undo-strong-limit 3000000   ; 3mb   (default is 240kb)
        undo-outer-limit 48000000)) ; 48mb (default is 24mb)

(use-package undo-fu-session
  :defer t
  :commands undo-fu-session-global-mode
  :init
  (setq undo-fu-session-directory (concat cache-dir "undo-fu-session")
        undo-fu-session-incompatible-files
        '("\\.gpg$" "/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))
  (when (executable-find "zstd")
    (setq undo-fu-session-compression 'zst)))

(use-package vundo
  :defer t
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols
        vundo-compact-display t))
;; vc                ; version-control and Emacs, sitting in a tree
(use-package vc
  :straight nil
  :init
  (setq vc-handled-backends '(SVN Git Hg)))

(use-package vc-annotate
  :straight nil
  :defer t)

(use-package smerge-mode
  :straight nil
  :hook (find-file . modules-editor--maybe-enable-smerge-mode))

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
  :defer t)

;; Evil's shift operators use two spaces by default in this configuration.
(setq evil-shift-width 2)

(use-package pangu-spacing
  :preface
  ;; pangu-spacing still consults an internal rx category table at runtime.
  (require 'rx)
  :config
  (global-pangu-spacing-mode 1)
  (setq pangu-spacing-real-insert-separtor t))

(use-package rime
  :defer t
  :init
  (setq default-input-method "rime"
        rime-inline-ascii-holder ?x
        rime-user-data-dir (expand-file-name "rime" user-emacs-directory))
  (cond (my/macos-p
         (setq rime-librime-root
               (expand-file-name "librime/dist" user-emacs-directory)))
        (my/windows-p
         (setq rime-librime-root "~/scoop/apps/librime/current"
               rime-emacs-module-header-root
               "~/scoop/apps/emacs/current/include/")))
  :bind (:map rime-mode-map
              ("C-`" . rime-send-keybinding)
              ("`" . rime-inline-ascii)))

;; Built-in editing behavior
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

;; Custom commands and modes
(defun my/open-config-directory ()
  "Open the site-lisp directory of this Emacs configuration."
  (interactive)
  (dirvish (expand-file-name "site-lisp" user-emacs-directory)))

(defun my/previous-five-lines ()
  "Move point up five lines."
  (interactive)
  (evil-previous-line 5))

(defun my/next-five-lines ()
  "Move point down five lines."
  (interactive)
  (evil-next-line 5))

(defun modules-editor--use-emacs-state-after-tutorial (&rest _)
  "Enter Evil's Emacs state after opening the tutorial."
  (evil-emacs-state 1))

(defun modules-editor--maybe-enable-smerge-mode ()
  "Enable `smerge-mode' when the current buffer contains conflict markers."
  (unless (bound-and-true-p smerge-mode)
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^<<<<<<< " nil t)
        (smerge-mode 1)))))

(defun modules-editor--sync-undo-fu-session-mode ()
  "Keep persistent undo sessions in sync with `modules-editor-undo-mode'."
  (undo-fu-session-global-mode (if modules-editor-undo-mode 1 -1)))

(define-minor-mode modules-editor-undo-mode
  "Globally remap Emacs undo commands to undo-fu."
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map [remap undo] #'undo-fu-only-undo)
            (define-key map [remap redo] #'undo-fu-only-redo)
            (define-key map (kbd "C-_") #'undo-fu-only-undo)
            (define-key map (kbd "M-_") #'undo-fu-only-redo)
            (define-key map (kbd "C-M-_") #'undo-fu-only-redo-all)
            (define-key map (kbd "C-x r u") #'undo-fu-session-save)
            (define-key map (kbd "C-x r U") #'undo-fu-session-recover)
            map)
  :init-value nil
  :global t)

(add-hook 'modules-editor-undo-mode-hook
          #'modules-editor--sync-undo-fu-session-mode)
(modules-editor-undo-mode 1)

(unless (advice-member-p #'modules-editor--use-emacs-state-after-tutorial
                         #'help-with-tutorial)
  (advice-add #'help-with-tutorial :after
              #'modules-editor--use-emacs-state-after-tutorial))

(provide 'editor)

;;; modules/editor.el ends here
