;;; modules/completion.el --- Minibuffer completion -*- lexical-binding: t; -*-

(when (fboundp 'global-completion-preview-mode)
  (global-completion-preview-mode +1))

;; 不使用横向的选框而是使用 vertico 纵向选择
(ido-mode -1)

(use-package vertico
  :init
  (vertico-mode)
  :custom
  (vertico-resize nil)
  (vertico-count 17)
  (vertico-scroll-margin 3)
  (vertico-cycle t))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(defun modules-completion-project-root ()
  "Resolve the current project root for Consult."
  (when-let ((project (project-current)))
    (car (project-roots project))))

(defun modules-completion--fd-args ()
  "Compute arguments for fd/fdfind across different platforms."
  (let* ((fd-binary (or (executable-find "fdfind")
                        (executable-find "fd")
                        "fd"))
         (path-separator (when my/windows-p "--path-separator=/")))
    (delq nil
          (list fd-binary
                "--color=never"
                "--full-path"
                "--absolute-path"
                "--hidden"
                "--exclude" ".git"
                path-separator))))

(use-package consult
  :config
  (setq consult-project-function #'modules-completion-project-root
        consult-narrow-key "<"
        consult-line-numbers-widen t
        consult-async-min-input 2
        consult-async-refresh-delay 0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1
        consult-fd-args (modules-completion--fd-args)))

(use-package consult-dir
  :defer t)

(use-package consult-flycheck
  :after (consult flycheck))

(use-package consult-yasnippet
  :defer t)

(use-package embark
  :defer t)

(use-package marginalia
  :init
  (marginalia-mode))

(use-package wgrep
  :defer t
  :config
  (setq wgrep-auto-save-buffer t))

(use-package vertico-posframe
  :hook (vertico-mode . vertico-posframe-mode)
  :config
  (add-hook 'kill-emacs-hook #'posframe-delete-all))

(provide 'completion)

;;; modules/completion.el ends here
