;;; modules/os.el --- OS integration -*- lexical-binding: t; -*-

(when (and (or my/macos-p my/linux-p)
           (or (daemonp) (display-graphic-p)))
  (use-package exec-path-from-shell
    :demand t
    :config
    (exec-path-from-shell-initialize)))

(use-package tramp
  :straight nil
  :defer t
  :init
  (setq tramp-default-method
        (if (and my/windows-p
                 (not (executable-find "ssh"))
                 (executable-find "plink"))
            "plink"
          "ssh")))

(setq xterm-set-window-title t)
(add-hook 'tty-setup-hook #'xterm-mouse-mode)

(unless (display-graphic-p)
  (use-package clipetty
    :hook (after-init . global-clipetty-mode)))
(provide 'os)

;;; modules/os.el ends here
