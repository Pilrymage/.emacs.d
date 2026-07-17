;;; lang/org.el --- Org-mode setup -*- lexical-binding: t; -*-

;; 
(use-package org
  :hook (((org-babel-after-execute org-mode) . org-redisplay-inline-images) ; display image
         (visual-line-mode . org-mode))
  :config
  ;; Define a custom face for list markers

  ;; Apply the custom face to unordered and ordered list markers
  (with-eval-after-load 'org
    (defvar org-hide-space-keywords
      '(("\\cc\\( \\)[*/_=~+]\\cc.*?[*/_=~+]"
         (0 (prog1 () (when org-hide-emphasis-markers (add-text-properties (match-beginning 1) (match-end 1) '(invisible t))))))
        ("[*/_=~+].*?\\cc[*/_=~+]\\( \\)\\cc"
         (0 (prog1 () (when org-hide-emphasis-markers (add-text-properties (match-beginning 1) (match-end 1) '(invisible t))))))))
    (font-lock-add-keywords 'org-mode org-hide-space-keywords 'append)
    ;; (define-key org-mode-map (kbd "SPC") nil)
    (add-to-list 'org-src-lang-modes '("python" . python-ts))
    (add-to-list 'org-src-lang-modes '("c" . c-ts))
    (add-to-list 'org-src-lang-modes '("cpp" . c++-ts))
    (add-to-list 'org-src-lang-modes '("json" . json-ts))
    (add-to-list 'org-src-lang-modes '("java" . java-ts))
    (add-to-list 'org-src-lang-modes '("js" . js-ts))
    (add-to-list 'org-src-lang-modes '("javascript" . js-ts))
    (add-to-list 'org-src-lang-modes '("rust" . rust-ts))
    (add-to-list 'org-src-lang-modes '("bash" . bash-ts)))

  ;; 在 org mode 中添加无序列表和有序列表的颜色
  (font-lock-add-keywords
   'org-mode
   '(("^\\( *[-+*]\\) " 1 'org-level-1 prepend)  ;; Unordered lists
     ;; ("^\\( *[0-9]+\\(?:\\.\\|)\\) )" 1 'org-level-1 prepend)
     ("^\\( *[0-9]+[\\.)]\\) " 1 'org-level-1 prepend)
     )) ;; Ordered lists
  (setq org-modules nil
        org-todo-keywords
        '((sequence "TODO(t)" "DOING(i)" "HANGUP(h)" "|" "DONE(d)" "CANCEL(c)")
          (sequence "⚑(T)" "🏴(I)" "❓(H)" "|" "✔(D)" "✘(C)"))
        org-todo-keyword-faces '(("HANGUP" . warning)
                                 ("❓" . warning))
        org-priority-faces '((?A . error)
                             (?B . warning)
                             (?C . success))
        ;; org-tags-column -80
        org-log-done 'time
        org-catch-invisible-edits 'smart
        org-startup-indented t
        org-startup-truncated nil
        org-ellipsis (if (char-displayable-p ?⏷) "\t⏷" nil)
        org-pretty-entities nil
        org-attach-auto-tag nil
        org-image-actual-width nil
        org-hide-emphasis-markers t)
  )

(defun my/org-timer-record-and-stop-and-done ()
  "Record and stop the current Org timer, then mark the entry done."
  (interactive)
  (org-timer)
  (org-timer-stop)
  (org-todo 'done))

(defun my/org-clock-out-and-done ()
  "Clock out of the current Org entry, then mark it done."
  (interactive)
  (org-clock-out)
  (org-todo 'done))

                                        ;(use-package org-contrib :straight (org-contrib :host github :repo "emacsmirror/org-conrtib"))


;; Prettify UI
(use-package org-modern
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))
(use-package org-modern-indent
  :straight (org-modern-indent :type git :host github :repo "jdtsmith/org-modern-indent")
  :config
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))
(use-package avy
  :defer t)
(use-package htmlize
  :defer t)
(use-package ox-clip
  :defer t)
(use-package toc-org
  :defer t
  :hook (org-mode . toc-org-mode))
(use-package org-cliplink
  :defer t)

(use-package org-rich-yank
  :bind (:map org-mode-map
              ("C-M-y" . org-rich-yank)))
(use-package orgit
  :defer t)
(use-package orgit-forge
  :defer t)
(use-package org-download
  :defer t
  :config
  ;; 关键修改：必须使用 setq-default 全局修改这两个 buffer-local 变量
  (setq-default org-download-image-dir "./images")
  (setq-default org-download-heading-lvl nil)
  
  (setq org-download-timestamp "_%Y%m%d-%H%M%S")
  (add-hook 'dired-mode-hook 'org-download-enable))
;; Preview
(use-package org-preview-html
  :diminish
  :bind (:map org-mode-map
              ("C-c C-h" . org-preview-html-mode))
  :init (when (and (featurep 'xwidget-internal) (display-graphic-p))
          (setq org-preview-html-viewer 'xwidget)))

(use-package gnuplot
  :defer t)
(use-package gnuplot-mode
  :defer t)

(use-package verb
  :defer t
  :mode ("\\.org\\'" . org-mode))

(use-package org-journal
  :defer t
  :config
  (setq org-journal-file-type 'yearly)    ; 就要一年的
  (setq org-journal-date-format "%Y/%m/%d W%W D%j（%a）")
  (setq org-journal-dir my/org-notes-repository)
  (setq org-journal-file-format "%Y.org")
  )
(use-package org-noter
  :defer t)

(defgroup my/org-bullets nil
  "Bold + colored bullets by list indent level."
  :group 'org)

(defcustom my/org-bullet-colors
  ;; 可按主题自行调整
  '("DodgerBlue" "DarkOrange" "ForestGreen" "MediumOrchid"
    "Goldenrod" "IndianRed" "SteelBlue" "DarkCyan")
  "Colors used for list bullets by indent level (cycled)."
  :type '(repeat string))

(defun my/org--ensure-bullet-faces ()
  (cl-loop for i from 1 to (length my/org-bullet-colors) do
           (let* ((name (format "my/org-list-bullet-level-%d" i))
                  (face (intern name))
                  (color (nth (1- i) my/org-bullet-colors)))
             (unless (facep face) (make-face face))
             (set-face-attribute face nil :weight 'bold :foreground color))))

(defun my/org--indent-level-at (pos)
  "Compute list indent level at POS by indentation and org-list-indent-offset."
  (save-excursion
    (goto-char pos)
    (back-to-indentation)
    (let* ((indent (current-column))
           (offset (if (boundp 'org-list-indent-offset)
                       (max 1 org-list-indent-offset)
                     2)))
      (1+ (/ indent offset)))))

(defun my/org--bullet-face-for-level (level)
  (let* ((n (length my/org-bullet-colors))
         (idx (1+ (mod (1- level) n)))
         (sym (intern (format "my/org-list-bullet-level-%d" idx))))
    sym))

(defun my/org--fontify-list-bullets (limit)
  "Font-lock matcher to apply faces to list bullets by indent level."
  (my/org--ensure-bullet-faces)
  (let (found)
    (while (and (not found)
                (re-search-forward
                 ;; 匹配无序列表 (- + *) 或有序列表 (1. 1)
                 "^[ \\t]*\\\\([-*+]\\\\|[0-9]+[.)]\\\\)\\\\([ \\t]\\\\|$\\\\)"
                 limit t))
      (let* ((beg (match-beginning 1))
             (end (match-end 1))
             (lvl (my/org--indent-level-at beg))
             (face (my/org--bullet-face-for-level lvl)))
        (add-text-properties beg end `(face ,face))
        (setq found t)))
    found))
(defun my/org-bullets-enable ()
  "Enable colored bold bullets for org lists in this buffer."
  (font-lock-add-keywords
   nil
   '((my/org--fontify-list-bullets 0 nil))
   'append)
  (when (fboundp 'font-lock-flush) (font-lock-flush))
  (when (fboundp 'font-lock-ensure) (font-lock-ensure)))
(add-hook 'org-mode-hook #'my/org-bullets-enable)
(use-package org-superstar
  :defer t
  :hook (org-mode . org-superstar-mode)
  :config
  (setq org-superstar-headline-bullets-list '("●" "○" "◆" "◇" "►" "▸")
        org-superstar-item-bullet-alist
        '((?* . ?•) (?+ . ?◦) (?- . ?▪ ))))
(use-package centered-window
  :defer t)
;; Presentation
(use-package org-tree-slide
  :diminish
  :functions (org-display-inline-images
              org-remove-inline-images)
  :bind (:map org-mode-map
              ("s-<f7>" . org-tree-slide-mode)
              :map org-tree-slide-mode-map
              ("<left>" . org-tree-slide-move-previous-tree)
              ("<right>" . org-tree-slide-move-next-tree)
              ("S-SPC" . org-tree-slide-move-previous-tree)
              ("SPC" . org-tree-slide-move-next-tree))
  :hook ((org-tree-slide-play . (lambda ()
                                  (text-scale-increase 4)
                                  (org-display-inline-images)
                                  (read-only-mode 1)))
         (org-tree-slide-stop . (lambda ()
                                  (text-scale-increase 0)
                                  (org-remove-inline-images)
                                  (read-only-mode -1))))
  :init (setq org-tree-slide-header nil
              org-tree-slide-slide-in-effect t
              org-tree-slide-heading-emphasis nil
              org-tree-slide-cursor-init t
              org-tree-slide-modeline-display 'outside
              org-tree-slide-skip-done nil
              org-tree-slide-skip-comments t
              org-tree-slide-skip-outline-level 3))
(use-package org-re-reveal
  :defer t)
(require 'org-tempo)
(use-package revealjs
  :defer t
  :straight (revealjs :host github :repo "hakimel/reveal.js" :files ("css" "dist" "js" "plugin")))
(use-package ob-async
  :defer t)
(use-package ox-pandoc
  :defer t)
(use-package ox-hugo
  :after ox)
(use-package cdlatex
  :hook (org-mode . turn-on-org-cdlatex)
  )

(use-package auctex
  :defer t)
(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :config
  ;; 这一行必须为 t，否则 org-appear 不会工作
  (setq org-hide-emphasis-markers t)
  ;; 以下设置为可选，开启更多自动展开功能
  (setq org-appear-autoentities t)  ; 光标进入时展开 HTML 实体，如 \alpha
  (setq org-appear-autolinks t)     ; 光标进入链接描述时，展开显示完整的 URL
  (setq org-appear-autosubmarkers t)) ; 展开下标/上标标记，如 text_{sub}
(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

(use-package org-super-links
  :straight (org-super-links :type git :host github :repo "toshism/org-super-links" :branch "develop"))

(setq org-startup-numerated t)          ; 设置 org 目录编号
(setq org-structure-template-alist ; org 模板，其他语言
      (append org-structure-template-alist
              '(("el" . "src emacs-lisp")
                ("sh" . "src bash")
                ("py" . "src python :results output")
                ("fi" . "src fish")
                ("js" . "src javascript")
                ("cc" . "src c")
                ("ru" . "src rust")
                ("cp" . "src cpp")
                ("plm" . "src plantuml\n@startmindmap")
                ("pw" . "src powershell"))))
(add-hook 'org-mode-hook
          (lambda ()
            (setq-local electric-pair-inhibit-predicate
                        (lambda (c)
                          (if (char-equal c ?<) t (electric-pair-default-inhibit c))))))

                                        ; org 主目录，也是很多东西被 organized 的主目录，简短仅次于根目录
(setq my/org-agenda-inbox "~/org/agenda/inbox.org") ; inbox.org 的路径
(setq org-agenda-files `(,my/org-notes-repository))
(setq org-startup-numerated t)          ; 设置 org 目录编号
(setq org-confirm-babel-evaluate nil
      org-src-fontify-natively t
      org-src-tab-acts-natively t)

;; 用于 Windows 的 Latex
(if my/windows-p
    (setq temporary-file-directory "C:/Users/pilrymage/AppData/Local/Temp/"))
(setq org-format-latex-options (plist-put org-format-latex-options :scale 1.5))
(setq org-preview-latex-default-process 'imagemagick)
(with-eval-after-load 'org
  ;; 1. 先将默认的 dvisvgm 配置从列表中完全删除
  (setq org-preview-latex-process-alist
        (assq-delete-all 'dvisvgm org-preview-latex-process-alist))
  
  ;; 2. 重新加入一个干净的、专为 xelatex 定制的 dvisvgm 节点
  (add-to-list 'org-preview-latex-process-alist
               '(imagemagick
                 :programs ("xelatex" "magick")
                 :description "pdf > png"
                 :message
                 "you need to install the programs: xelatex and imagemagick."
                 :image-input-type "pdf" :image-output-type "png"
                 :image-size-adjust (1.0 . 1.0) :latex-compiler
                 ("xelatex -interaction nonstopmode -output-directory %o %f")
                 :image-converter
                 ("magick -density %D %f -trim -antialias -quality 100 %O"))))

(modify-syntax-entry ?> "w" org-mode-syntax-table)
(modify-syntax-entry ?> "w" org-mode-syntax-table)

(defun my/org-git-sync-silent ()
  "检查 Org 笔记目录是否有变动，如果有则执行静默提交和推送 (Windows 兼容版)。"
  (interactive)
  ;; *** 请将这里的路径替换为你的实际 Windows 路径 ***
  ;; 注意：在 Emacs 中表示 Windows 路径，请务必使用正斜杠 "/" 而不是反斜杠 "\"
  (let ((org-dir my/org-notes-repository)) 
    (when (file-directory-p org-dir)
      (let ((default-directory org-dir))
        (unless (string-empty-p (shell-command-to-string "git status -s"))
          (message "Org-sync: 发现变动，正在后台同步...")
          (start-process-shell-command
           "org-git-sync-process" ;; 进程的内部名称
           nil                    ;; 不需要输出到任何 Buffer
           (format "git pull && git add . && git commit -m \"Auto-sync: %s\" && git push"
                   (format-time-string "%Y-%m-%d %H:%M:%S")))
          
          (message "Org-sync: 同步任务已启动"))))))

;; 定时器设置保持不变
(run-at-time "1 min" 1200 'my/org-git-sync-silent)
(add-hook 'kill-emacs-hook 'my/org-git-sync-silent)

(setq org-default-notes-file (concat my/org-notes-repository "/capture.org"))
;; 定义 capture 模板
(setq org-capture-templates
      '(("n" "Note" entry (file org-default-notes-file)
         "* TODO %?\n\n%i"
         :empty-lines 1)))

(provide 'init-org)
;; Babel

(provide 'init-org)

;;; lang/org.el ends here
