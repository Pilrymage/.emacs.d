;;; lang/init-lang.el --- Programming language support -*- lexical-binding: t; -*-

(require 'subr-x)

;; Language infrastructure

(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  (treesit-font-lock-level 4)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))

(use-package gdb-mi
  :straight nil
  :defer t
  :init
  (setq gdb-many-windows t
        gdb-show-main t))

(use-package dape
  :defer t
  :init
  (setq dape-key-prefix nil
        dape-buffer-window-arrangement 'right))

;; Python

(defun my/python--venv-interpreter (venv)
  "Return the Python executable in VENV when it exists."
  (when venv
    (let ((python (expand-file-name
                   (if my/windows-p
                       "Scripts/python.exe"
                     "bin/python")
                   venv)))
      (when (file-executable-p python)
        python))))

(defun my/python-resolve-interpreter (&optional directory)
  "Return the Python executable for DIRECTORY.
Prefer a project-local .venv, then an activated virtual environment,
and finally the platform's normal Python command."
  (let* ((directory (or directory default-directory))
         (project-root (locate-dominating-file directory ".venv"))
         (project-venv (and project-root
                            (expand-file-name ".venv" project-root))))
    (or (my/python--venv-interpreter project-venv)
        (my/python--venv-interpreter (getenv "VIRTUAL_ENV"))
        (executable-find (if my/windows-p "python" "python3"))
        (executable-find "python")
        (executable-find "python3"))))

(defun my/python--configure-buffer ()
  "Use the Python environment associated with the current project."
  (when-let ((python (my/python-resolve-interpreter)))
    (setq-local python-shell-interpreter python)))

(use-package python
  :straight nil
  :hook ((python-mode python-ts-mode) . my/python--configure-buffer))

;; Ansible and configuration files

(defun my/lang--ansible-project-p ()
  "Return non-nil when the current buffer belongs to an Ansible project."
  (or (locate-dominating-file default-directory "ansible.cfg")
      (locate-dominating-file default-directory "roles")
      (locate-dominating-file default-directory "group_vars")
      (locate-dominating-file default-directory "host_vars")))

(defun my/lang--maybe-enable-ansible ()
  "Enable Ansible helpers in YAML buffers that belong to Ansible projects."
  (when (my/lang--ansible-project-p)
    (ansible-mode 1)
    (ansible-doc-mode 1)))

(use-package ansible
  :commands ansible-mode
  :hook ((yaml-mode yaml-ts-mode) . my/lang--maybe-enable-ansible))

(use-package ansible-doc
  :commands (ansible-doc ansible-doc-mode)
  :config
  (evil-set-initial-state 'ansible-doc-module-mode 'emacs))

(use-package yaml-mode
  :defer t)

;; Agda

(defun my/lang--load-agda-mode ()
  "Load the Emacs mode supplied by the installed Agda executable."
  (when-let* ((agda-mode (executable-find "agda-mode"))
              (mode-file (car (ignore-errors
                                (process-lines agda-mode "locate")))))
    (when (file-readable-p mode-file)
      (load mode-file nil 'nomessage)
      (add-to-list 'auto-mode-alist '("\\.agda\\'" . agda2-mode))
      (add-to-list 'auto-mode-alist '("\\.lagda\\.md\\'" . agda2-mode)))))

(my/lang--load-agda-mode)

;; Emacs Lisp

(use-package rainbow-delimiters
  :defer t)

(use-package elisp-mode
  :straight nil
  :mode ("\\(?:^\\|/\\)Cask\\'" . emacs-lisp-mode)
  :hook ((emacs-lisp-mode . outline-minor-mode)
         (emacs-lisp-mode . rainbow-delimiters-mode)))

;; Common and occasional languages

(use-package rust-mode
  :defer t)

(use-package markdown-mode
  :defer t
  :mode ("/README\\(?:\\.md\\)?\\'" . gfm-mode)
  :init
  (setq markdown-italic-underscore t
        markdown-asymmetric-header t
        markdown-gfm-additional-languages '("sh")
        markdown-make-gfm-checkboxes-buttons t
        markdown-fontify-whole-heading-line t
        markdown-fontify-code-blocks-natively t))

(use-package tuareg
  :defer t)

(use-package haskell-mode
  :defer t)

(use-package bison-mode
  :defer t
  :straight (:host github :repo "Wilfred/bison-mode" :files ("*.el")))

(provide 'init-lang)

;;; lang/init-lang.el ends here
