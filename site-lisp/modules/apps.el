;;; modules/apps.el --- Productivity apps -*- lexical-binding: t; -*-

(use-package elfeed
  :defer t
  :init
  (setq elfeed-db-directory (concat data-dir "elfeed/")
        elfeed-search-trailing-width 20
        elfeed-search-title-max-width 120
        elfeed-search-filter "@1-month-ago +unread -translate_title")
  :config
  (setq elfeed-curl-extra-arguments
        (when my/proxy-url
          (list "--proxy" my/proxy-url)))
  (elfeed-set-timeout 30)
  (elfeed-set-max-connections 4)
  (with-eval-after-load 'evil
    (evil-set-initial-state 'elfeed-search-mode 'emacs)
    (evil-set-initial-state 'elfeed-show-mode 'emacs)))
(use-package elfeed-org
  :after elfeed
  :config
  (elfeed-org))

(use-package verb
  :defer t)

(provide 'apps)

;;; modules/apps.el ends here
