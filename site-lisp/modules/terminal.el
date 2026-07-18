;;; modules/terminal.el --- Terminal & tooling -*- lexical-binding: t; -*-

(defun modules-terminal--hide-mode-line ()
  "Hide the mode line in the current buffer."
  (setq-local mode-line-format nil))

(defun modules-terminal--finish-quickrun ()
  "Normalize the Quickrun output window after execution."
  (when-let ((window (get-buffer-window quickrun--buffer-name)))
    (with-selected-window window
      (goto-char (point-min))
      (let ((ignore-window-parameters t))
        (shrink-window-if-larger-than-buffer)))))

(unless my/windows-p
  (use-package vterm
    :defer t
    :hook (vterm-mode . modules-terminal--hide-mode-line)
    :config
    (setq vterm-kill-buffer-on-exit t
          vterm-max-scrollback 5000)
    (evil-set-initial-state 'vterm-mode 'emacs)))

(use-package quickrun
  :defer t
  :config
  (setq quickrun-focus-p nil)
  (add-hook 'quickrun-after-run-hook #'modules-terminal--finish-quickrun))

(use-package eros
  :defer t
  :hook (emacs-lisp-mode . eros-mode))

(use-package transient
  :defer t
  :init
  (make-directory (concat data-dir "transient/") t)
  (setq transient-default-level 5
        transient-levels-file (concat data-dir "transient/levels")
        transient-values-file (concat data-dir "transient/values")
        transient-history-file (concat data-dir "transient/history"))
  :config
  (define-key transient-map [escape] #'transient-quit-one))

(use-package magit
  :defer t
  :init
  (setq magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  :config
  (setq magit-diff-refine-hunk 'all
        magit-save-repository-buffers nil
        magit-push-current-set-remote-if-missing t
        magit-revision-insert-related-refs nil)
  (magit-auto-revert-mode 1)
  (add-hook 'magit-process-mode-hook #'goto-address-mode))

(when (executable-find "delta")
  (use-package magit-delta
    :hook (magit-mode . magit-delta-mode)))

(use-package forge
  :defer t
  :init
  (make-directory (concat data-dir "forge/") t)
  (setq forge-database-file (concat data-dir "forge/forge-database.sqlite")))

(provide 'terminal)

;;; modules/terminal.el ends here
