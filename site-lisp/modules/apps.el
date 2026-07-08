;;; modules/apps.el --- Productivity apps -*- lexical-binding: t; -*-

(use-package elfeed
  :ensure t
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
  :mode ("\\.org\\'" . org-mode)
  :general (my/org-leader-def "r" '(:keymap verb-command-map :which-key "verb")))

(use-package telega
  :config
  (with-eval-after-load 'evil
    (evil-set-initial-state 'telega-mode 'emacs))
  (setq telega-proxies
        (list '(:server "127.0.0.1" :port 7897 :enable t))))

(use-package elfeed-org

  :ensure t
  :init (elfeed-org))

(defun my/auth-get (host)
  (let ((cred (car (auth-source-search :host host :require '(:secret)))))
    (when cred
      (funcall (plist-get cred :secret)))))

(use-package elfeed-translate
  :straight (elfeed-translate
             ;; :type nil
             ;; :host github
             ;; :repo "Pilrymage/elfeed-translate"
             :local-repo "D:/github/elfeed-translate"
             )
  :custom

  (elfeed-translate-target-lang "Chinese")
  (elfeed-translate-title-style 'target-first)
  (global-elfeed-translate-mode t)
  (elfeed-translate-parallel t)
  (elfeed-translate-batch-size 50)
  :config
  ;; (elfeed-translate-api-key (my/auth-get "zai"))
  ;; (elfeed-translate-api-url "https://open.bigmodel.cn/api/paas/v4/chat/completions")
  ;; (elfeed-translate-model "glm-4-flash-250414")
  ;; (setq
  ;;  elfeed-translate-api-key (my/auth-get "opencode") 
  ;;  elfeed-translate-api-url "https://opencode.ai/zen/go/v1/chat/completions" 
  ;;  elfeed-translate-model "deepseek-v4-flash"
  ;; elfeed-translate-max-concurrent 4)
  (setq
   elfeed-translate-api-key (my/auth-get "opencode")
   elfeed-translate-api-url "https://opencode.ai/zen/v1/chat/completions" 
   elfeed-translate-model "deepseek-v4-flash-free"
   elfeed-translate-max-concurrent 2)
  ;; (setq
  ;;  elfeed-translate-api-key (my/auth-get "opencode") 
  ;;  elfeed-translate-api-url "https://opencode.ai/zen/v1/chat/completions" 
  ;;  elfeed-translate-model "mimo-v2.5-free"
  ;;  elfeed-translate-max-concurrent 1)

  (setq elfeed-translate-debug t)
  (setq elfeed-translate-auto-refresh t)
  ;; (setq
  ;;  elfeed-translate-api-key (my/auth-get "deepseek")
  ;;  elfeed-translate-api-url "https://api.deepseek.com/chat/completions"
  ;;  elfeed-translate-model "deepseek-v4-flash"
  ;; elfeed-translate-max-concurrent 16)
  )

(provide 'apps)



