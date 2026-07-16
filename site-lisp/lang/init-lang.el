;;; lang/general.el --- Language support -*- lexical-binding: t; -*-

(require 'subr-x)

(use-package treesit-auto
  :custom
  ;; 将 Tree-sitter 高亮级别开到最大（默认是 3）
  ;; 级别 4 会包含变量、属性、甚至部分标点符号的极致高亮，这正是你需要的！
  (treesit-font-lock-level 4)
  :config
  ;; 启用全局的 treesit-auto
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; ansible
(use-package ansible
  :defer t)
(use-package ansible-doc
  :defer t
  :config
  (evil-set-initial-state '(ansible-doc-module-mode) 'emacs))
(use-package jinja2-mode
  :defer t
  :disabled t
  :mode "\\.j2\\"
  :config
  (setq jinja2-enable-indent-on-save nil))
(use-package yaml-mode
  :defer t)

;; 因为 git 上的 Agda2-mode 太新了，于是使用 PLFA 要求的 Agda 版本
;;(agda +local)              ; types of types of types of types...
;; (use-package agda2-mode
;;   :ensure nil
;; :straight (agda2-mode :host github :repo "agda/agda"
;;                       :files ("src/data/emacs-mode/*.el" (:exclude "agda-input.el"))
;;                       :nonrecursive t)
;; :config
(add-to-list 'auto-mode-alist '("\\.agda\\'" . agda2-mode))
(add-to-list 'auto-mode-alist '("\\.lagda.md\\'" . agda2-mode))
(when-let ((agda-mode (executable-find "agda-mode")))
  (let ((coding-system-for-read 'utf-8))
    (ignore-errors
      (load-file
       (string-trim
        (shell-command-to-string (format "%s locate" agda-mode)))))))
;; )
;;(cc +lsp)         ; C > C++ == 1
;; (use-package cmake-mode
;;   :defer t)
;; (use-package cuda-mode
;;   :defer t)
;; (use-package demangle-mode
;;   :defer t)
;; (use-package disaster
;;   :defer t)
;; (use-package opencl-c-mode
;;   :defer t)
;; (use-package ccls
;;   :defer t)

(use-package rust-mode
  :defer t)

;;common-lisp       ; if you've seen one lisp, you've seen them all
;;coq               ; proofs-as-programs
;;emacs-lisp         ; drown in parentheses
(use-package rainbow-delimiters
  :defer t)
(use-package elisp-mode
  :straight nil
  :defer t
  :ensure nil
  :mode ("\\.Cask\\'" . emacs-lisp-mode)
  :config
  (add-hook 'emacs-lisp-mode-hook #'outline-minor-mode)
  (add-hook 'emacs-lisp-mode-hook #'rainbow-delimiters-mode))
(use-package highlight-quoted
  :defer t)
(use-package helpful
  :defer t
  :init
  (global-set-key (kbd "C-h f") #'helpful-callable)
  (global-set-key (kbd "C-h v") #'helpful-variable)
  (global-set-key (kbd "C-h k") #'helpful-key)
  (global-set-key (kbd "C-h x") #'helpful-command)
  ;; Lookup the current symbol at point. C-c C-d is a common keybinding
  ;; for this in lisp modes.
  (global-set-key (kbd "C-c C-d") #'helpful-at-point)

  ;; Look up *F*unctions (excludes macros).
  ;;
  ;; By default, C-h F is bound to `Info-goto-emacs-command-node'. Helpful
  ;; already links to the manual, if a function is referenced there.
  (global-set-key (kbd "C-h F") #'helpful-function)
  :config
  (evil-set-initial-state 'helpful-mode 'emacs)
  )

(use-package elisp-def
  :defer t)
(use-package elisp-demos
  :defer t)
                                        ;(use-package buttercup
                                        ;:defer t
                                        ;:commands (buttercup-run-tests)
                                        ;:config
                                        ;("/test[/-].+\\.el$" . buttercup-minor-mode)
                                        ;(add-hook 'buttercup-minor-mode-hook #'yas-minor-mode)
                                        ;(add-hook 'buttercup-minor-mode-hook #'evil-normalize-keymaps))

;;ess               ; R 语言统计包
;;fsharp            ; ML stands for Microsoft's Language
;;(latex +fold +cdlatex)             ; writing papers in Emacs has never been so fun
;;lean              ; for folks with too much o prove
;;lua               ; one-based indices? one-based indices
;;(markdown +grip)          ; writing docs for people to ignore
(use-package markdown-mode
  :defer t
  :mode ("/README\\(?:\\.md\\)?\\'" . gfm-mode)
  :init
  (let ((renderer (or (executable-find "pandoc")
                      (executable-find "markdown")
                      (executable-find "cmark"))))
    (setq markdown-italic-underscore t
          markdown-asymmetric-header t
          markdown-gfm-additional-languages '("sh")
          markdown-make-gfm-checkboxes-buttons t
          markdown-fontify-whole-heading-line t
          markdown-fontify-code-blocks-natively t
          markdown-command renderer
          markdown-open-command my/open-command
          markdown-content-type "application/xhtml+xml"
          markdown-css-paths
          '("https://cdn.jsdelivr.net/npm/github-markdown-css/github-markdown.min.css"
            "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/styles/github.min.css")
          markdown-xhtml-header-content
          (concat "<meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>"
                  "<style> body { box-sizing: border-box; max-width: 740px; width: 100%; margin: 40px auto; padding: 0 10px; } </style>"
                  "<script id='MathJax-script' async src='https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'></script>"
                  "<script src='https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/highlight.min.js'></script>"
                  "<script>document.addEventListener('DOMContentLoaded', () => { document.body.classList.add('markdown-body'); document.querySelectorAll('pre[lang] > code').forEach((code) => { code.classList.add(code.parentElement.lang); }); document.querySelectorAll('pre > code').forEach((code) => { hljs.highlightBlock(code); }); });</script>"))))
(use-package markdown-toc :defer t)
;;nix               ; I hereby declare "nix geht mehr!"
;;ocaml             ; an objective camel
(use-package tuareg :defer t)
(use-package haskell-mode :defer t)
;;(org +dragndrop +journal +hugo +present +pomodoro)               ; contacts 与 jupyter 还没相活
(use-package htmlize
  :defer t)
(use-package ox-clip
  :defer t)
(use-package centered-window
  :defer t)
(use-package revealjs
  :defer t
  :straight (revealjs :host github :repo "hakimel/reveal.js" :files ("css" "dist" "js" "plugin")))
(use-package ob-async
  :defer t)
(use-package ox-pandoc
  :defer t)
;;php               ; perl's insecure younger brother
;;plantuml          ; diagrams for confusing people more
;;(python +conda)            ; beautiful is better than ugly
;;(racket +xp +lsp)            ; a DSL for DSLs
;;(scheme +guile)   ; a fully conniving family of lisps
;;(sh +fish +powershell)  ; she sells {ba,z,fi}sh shells on the C xor
;;web               ; the tubes
;;yaml                ; JSON, but readable
;;:config

;;literate                    ;
;;(default +bindings +smartparens))
(use-package avy
  :defer t
  :config
  (setq avy-all-windows nil
        avy-all-windows-alt t
        avy-background t
        ;; the unpredictability of this (when enabled) makes it a poor default
        avy-single-candidate-jump nil))
(use-package link-hint
  :defer t)
(use-package grip-mode :defer t)
(use-package ox-gfm
  :defer t
  :straight (:host github
                   :repo "larstvei/ox-gfm"
                   :files ("*.el")))
(use-package helm-bibtex :defer t)
(use-package ob-powershell
  :defer t
  :straight (:host github :repo "rkiggen/ob-powershell"))
(use-package bison-mode
  :defer t
  :straight (:host github :repo "Wilfred/bison-mode" :files ("*.el")))
(use-package flex-mode
  :defer t
  :straight (:host github :repo "manateelazycat/flex" :files ("*.el")))
(use-package anki-editor :defer t)


(provide 'init-lang)

;;; lang/general.el ends here
