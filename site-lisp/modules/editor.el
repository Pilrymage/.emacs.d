;;; modules/editor.el --- Editing enhancements -*- lexical-binding: t; -*-

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
  (general-create-definer my/evil-normal-def
    :states '(normal visual))

  (general-create-definer my/evil-insert-def
    :states '(insert))

  (general-create-definer my/leader-def
    :states '(normal visual motion)
    :prefix "SPC")

  (general-create-definer my/mode-leader-def
    :states '(normal)
    :prefix "SPC n"))
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

(defvar +snippets-dir (expand-file-name "snippets" user-emacs-directory)
  "Directory that stores personal snippets.")

(defvar evil-want-Y-yank-to-eol t)                  ; Y 是 y$ 而非 yy
(defvar evil-want-abbrev-expand-on-insert-exit nil) ; 退出插入模式不展开缩写
(defvar evil-respect-visual-line-mode t)            ; j k 视觉行移动而非逻辑行
(defvar evil-want-C-g-bindings t)                   ; Evil 处理 C-g 行为
(defvar evil-want-C-i-jump nil)                     ; dont car
(defvar evil-want-C-u-scroll nil)                   ; dont car
(defvar evil-want-C-u-delete nil)                     ; dont car
(defvar evil-want-C-w-delete nil)                     ; dont car
(use-package evil
  :defer t
  :hook (after-init . evil-mode)
  :ensure t
  :preface
  (setq evil-ex-search-vim-style-regexp t ; vim 正则而非 emacs
        evil-ex-visual-char-range t  ; ex 命令按列范围
        evil-mode-line-format 'nil   ; doom modeline 配合显示 evil 状态
        ;; more vim-like behavior
        evil-symbol-word-search t    ; 横线分隔单词看作一个词： this-is-a-symbol 是一词
        ;; if the current state is obvious from the cursor's color/shape, then
        ;; we won't need superfluous indicators to do it instead.
        evil-default-cursor '+evil-default-cursor-fn
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
  ;; C-h t 应当是 Emacs state，使用动态注入逻辑
  (advice-add #'help-with-tutorial :after (lambda (&rest _) (evil-emacs-state +1))))

;; Ensure `evil-shift-width' always matches `tab-width'; evil does not police
;; this itself, so we must.
(use-package evil-surround
  :defer t
  :hook (after-init . evil-surround-mode)
  :config
  (global-evil-surround-mode 1)
  (add-to-list 'evil-surround-pairs-alist '(?$ . ("\\(" . "\\)"))))

;; 注释：vgc, gcc
(use-package evil-commentary
  :ensure t
  :hook (after-init . evil-commentary-mode)
  :config
  (evil-commentary-mode))
(use-package evil-numbers :defer t)
                                        ; avy 代替
(use-package evil-easymotion
  :ensure t
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

(with-eval-after-load 'evil
  (my/evil-normal-def
    ;; Colemak movement
    "u" #'evil-previous-line
    "e" #'evil-next-line
    "n" #'evil-backward-char
    "i" #'evil-forward-char
    "U" #'my/previous-five-line
    "E" #'my/next-five-line
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
    ;; Word and search motions
    "h" #'evil-backward-word-begin
    "H" #'evil-backward-WORD-begin
    "k" #'evil-ex-search-next
    "K" #'evil-ex-search-previous
    "w" #'evilem-motion-forward-word-begin
    "W" #'evilem-motion-forward-WORD-begin
    "b" #'evilem-motion-backward-word-begin
    "B" #'evilem-motion-backward-WORD-begin
    ;; Numbers and windows
    "C-c +" #'evil-numbers/inc-at-pt
    "C-c -" #'evil-numbers/dec-at-pt
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
    "f e" '(my/jump-to-user-emacs-directory :which-key "Emacs config")
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
    "n" '(:ignore t :which-key "notes")
    "n c" '(org-capture :which-key "capture")
    "n j" '(org-journal-new-entry :which-key "new journal entry")
    "n J" '(org-journal-open-current-journal-file :which-key "today's journal")
    "o" '(:ignore t :which-key "open")
    "o d" '(dired :which-key "Dired")
    "o e" '(elfeed :which-key "Elfeed")
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
    (my/leader-def "o t" '(vterm :which-key "terminal"))))

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
