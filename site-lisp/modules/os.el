;;; modules/os.el --- OS integration -*- lexical-binding: t; -*-

(use-package tramp
  :defer t)
(setq tramp-default-method "ssh")
(setq xterm-set-window-title t)
(setq visible-cursor nil)
(add-hook 'tty-setup-hook #'xterm-mouse-mode)
(use-package xclip
  :defer t)
(use-package clipetty
  :defer t)
(use-package evil-terminal-cursor-changer
  :defer t
  :hook (tty-setup . evil-terminal-cursor-changer-activate))
(use-package kkp
  :defer t
  :hook (after-init . global-kkp-mode))
(provide 'os)

;;; modules/os.el ends here
