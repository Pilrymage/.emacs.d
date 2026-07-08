;;; modules/terminal.el --- Terminal & tooling -*- lexical-binding: t; -*-

(use-package hide-mode-line
  :defer t)

(use-package vterm
  :defer t
  :hook (vterm-mode . hide-mode-line-mode)
  :config
  (setq vterm-kill-buffer-on-exit t
        vterm-max-scrollback 5000)
  (evil-set-initial-state 'vterm-mode 'emacs))

(setq eval-expression-print-length nil
      eval-expression-print-level nil)

(use-package quickrun
  :defer t
  :config
  (setq quickrun-focus-p nil)
  (add-hook 'quickrun-after-run-hook
            (defun +eval-quickrun-shrink-window-h ()
              "Shrink the quickrun output window once code evaluation is complete."
              (when-let (win (get-buffer-window quickrun--buffer-name))
                (with-selected-window win
                  (let ((ignore-window-parameters t))
                    (shrink-window-if-larger-than-buffer))))))
  (add-hook 'quickrun-after-run-hook
            (defun +eval-quickrun-scroll-to-bof-h ()
              "Ensure window is scrolled to BOF on invocation."
              (when-let (win (get-buffer-window quickrun--buffer-name))
                (with-selected-window win
                  (goto-char (point-min)))))))

(use-package eros
  :defer t
  :hook (emacs-lisp-mode . eros-mode))

(defvar +magit-open-windows-in-direction 'right
  "What direction to open new windows from the status buffer.")

(defvar +magit-fringe-size '(13 . 1)
  "Size of the fringe in magit-mode buffers.")

(use-package magit
  :defer t
  :bind (:map magit-mode-map
              ("q" . magit-mode-bury-buffer))
  :init
  (setq magit-refresh-status-buffer t
        magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1
        magit-auto-revert-mode nil
        transient-levels-file (concat data-dir "transient/levels")
        transient-values-file (concat data-dir "transient/values")
        transient-history-file (concat data-dir "transient/history"))
  :config
  (setq transient-default-level 5
        magit-diff-refine-hunk 'all
        magit-save-repository-buffers nil
        magit-push-current-set-remote-if-missing t
        magit-revision-insert-related-refs nil)
  (add-hook 'magit-process-mode-hook #'goto-address-mode)
  (define-key transient-map [escape] #'transient-quit-one))

(use-package forge
  :defer t
  :preface
  (setq forge-database-file (concat data-dir "forge/forge-database.sqlite")
        forge-add-default-bindings t))

(use-package makefile-executor :defer t)

(defvar +tree-sitter-hl-enabled-modes '(not web-mode typescript-tsx-mode))

(use-package ssh-deploy
  :defer t
  :init
  (setq ssh-deploy-revision-folder (concat cache-dir "ssh-revisions/")
        ssh-deploy-on-explicit-save 1
        ssh-deploy-automatically-detect-remote-changes nil))

(use-package consult-lsp
  :defer t)

(provide 'terminal)

;;; modules/terminal.el ends here
