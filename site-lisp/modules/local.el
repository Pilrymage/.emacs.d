(require 'auth-source)
(require 'seq)
(require 'subr-x)

(defun my/auth-get (host &optional ascii-only)
  "Return the trimmed auth-source secret for HOST.
When ASCII-ONLY is non-nil, reject non-ASCII credentials and return
an explicitly unibyte string suitable for HTTP authorization headers."
  (let ((secret (auth-source-pick-first-password :host host)))
    (unless (stringp secret)
      (error "No string credential found in auth-source for %s" host))
    (setq secret (string-trim secret))
    (when (string-empty-p secret)
      (error "Empty credential found in auth-source for %s" host))
    (when ascii-only
      (unless (seq-every-p (lambda (char) (< char 128)) secret)
        (error "Credential for %s contains non-ASCII characters" host))
      (setq secret (encode-coding-string secret 'us-ascii)))
    secret))
(defvar my/local-directory (expand-file-name "site-lisp/local" user-emacs-directory

                                             ))

(use-package chord-highlight
  :straight (:type nil :local-repo "~/.emacs.d/site-lisp/local")
  :config
  (chord-highlight-mode 1))
(use-package org-wc-diff
  :straight (:type nil :local-repo "~/.emacs.d/site-lisp/local")
  :init
  (setq org-wc-diff-tracked-files '("D:/github/notes.org/2026.org"))
  :config
  (global-org-wc-diff-mode 1))

(use-package send-to-emacs
  :straight (:type nil :local-repo "~/.emacs.d/site-lisp/local")
  :defer t)

(use-package org-hydrus
  :defer t
  :straight (:type nil :local-repo "~/.emacs.d/site-lisp/local")
  :config
  (setq org-hydrus-api-key (my/auth-get "hydrus")))



(use-package elfeed-translate
  :straight (:type nil :local-repo "D:/github/elfeed-translate")
  :after elfeed
  :custom

  (elfeed-translate-target-lang "Chinese")
  (elfeed-translate-title-style 'target-first)
  (elfeed-translate-parallel t)
  (elfeed-translate-batch-size 50)
  :config
  ;; (elfeed-translate-api-key (my/auth-get "zai"))
  ;; (elfeed-translate-api-url "https://open.bigmodel.cn/api/paas/v4/chat/completions")
  ;; (elfeed-translate-model "glm-4-flash-250414")
  (setq
   elfeed-translate-api-key (my/auth-get "opencode" t)
   elfeed-translate-api-url "https://opencode.ai/zen/go/v1/chat/completions" 
   elfeed-translate-model "deepseek-v4-flash"
   elfeed-translate-max-concurrent 4)
  ;; (setq
  ;;  elfeed-translate-api-key (my/auth-get "opencode" t)
  ;;  elfeed-translate-api-url "https://opencode.ai/zen/v1/chat/completions" 
  ;;  elfeed-translate-model "deepseek-v4-flash-free"
  ;;  elfeed-translate-max-concurrent 1)
  ;; (setq
  ;;  elfeed-translate-api-key (my/auth-get "opencode" t)
  ;;  elfeed-translate-api-url "https://opencode.ai/zen/v1/chat/completions" 
  ;;  elfeed-translate-model "mimo-v2.5-free"
  ;;  elfeed-translate-max-concurrent 1)

  ;; (setq
  ;;  elfeed-translate-api-key (my/auth-get "deepseek" t)
  ;;  elfeed-translate-api-url "https://api.deepseek.com/chat/completions"
  ;;  elfeed-translate-model "deepseek-v4-flash"
  ;;  elfeed-translate-max-concurrent 2)
  (setq elfeed-translate-debug t)
  (setq elfeed-translate-auto-refresh t)
  (global-elfeed-translate-mode 1)
  )


(provide 'local)
