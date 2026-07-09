;;; modules/apps.el --- Productivity apps -*- lexical-binding: t; -*-

(use-package elfeed
  :defer t
  :config
  (setq elfeed-curl-extra-arguments '("-xhttp://localhost:7897"))
  (setq elfeed-search-trailing-width 20)
  (setq elfeed-search-title-max-width 160)
  (setf url-queue-timeout 30
        elfeed-set-max-connections 1)
  (setq elfeed-search-filter "@1-month-ago +unread -translate_title")
  (with-eval-after-load 'evil
    (evil-set-initial-state 'elfeed-search-mode 'emacs)
    (evil-set-initial-state 'elfeed-show-mode 'emacs)))


(use-package verb
  :defer t
  :mode ("\\.org\\'" . org-mode)
  :general (my/org-leader-def "r" '(:keymap verb-command-map :which-key "verb")))

(use-package telega
  :defer t
  :config
  (with-eval-after-load 'evil
    (evil-set-initial-state 'telega-mode 'emacs))
  (setq telega-proxies
        (list '(:server "127.0.0.1" :port 7897 :enable t))))

(use-package elfeed-org

  :ensure t
  :init (elfeed-org))


(provide 'apps)



