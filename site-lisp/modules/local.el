(defun my/auth-get (host)
  (let ((cred (car (auth-source-search :host host :require '(:secret)))))
    (when cred
      (funcall (plist-get cred :secret)))))

(use-package chord-highlight
  :config
  (chord-highlight-mode 1))
(use-package 'org-wc-diff
  :init
  (setq org-wc-diff-tracked-files '("D:/github/notes.org/2026.org"))
  :config
  (global-org-wc-diff-mode 1))

(use-package send-to-emacs
  :defer t)

(use-package org-hydrus
  :defer t
  :config
  (setq org-hydrus-api-key (my/auth-get "hydrus")))



(use-package elfeed-translate
  :defer t
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

