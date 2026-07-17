;;; modules/completion.el --- Minibuffer completion -*- lexical-binding: t; -*-

(defconst modules-completion--recentf-excluded-paths
  '("/\\.emacs\\.d/\\(?:straight\\|elpa\\|cache\\|data\\|url\\|tree-sitter\\)/"
    "/AppData/Local/cabal/"
    "/scoop/apps/emacs/")
  "Paths excluded from the recent-file history.")

(use-package recentf
  :straight nil
  :init
  (setq recentf-max-saved-items 200)
  :config
  (setq recentf-exclude
        (delete-dups
         (append recentf-exclude modules-completion--recentf-excluded-paths)))
  (recentf-mode 1)
  (recentf-cleanup))

(use-package savehist
  :straight nil
  :config
  (savehist-mode 1))

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
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(defun modules-completion--fd-args ()
  "Compute arguments for fd/fdfind across different platforms."
  (when-let ((fd-binary (or (executable-find "fdfind")
                            (executable-find "fd"))))
    (delq nil
          (list fd-binary
                "--color=never"
                "--full-path"
                "--absolute-path"
                "--hidden"
                "--exclude" ".git"
                (when my/windows-p "--path-separator=/")))))

(use-package consult
  :config
  (setq consult-narrow-key "<"
        consult-line-numbers-widen t)
  (when-let ((fd-args (modules-completion--fd-args)))
    (setq consult-fd-args fd-args)))

(use-package consult-dir
  :defer t
  :commands consult-dir)

(use-package marginalia
  :init
  (marginalia-mode))

(use-package wgrep
  :defer t
  :config
  (setq wgrep-auto-save-buffer t))

(provide 'completion)

;;; modules/completion.el ends here
