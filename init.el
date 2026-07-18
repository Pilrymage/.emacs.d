;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

(dolist (path '("site-lisp"
                "site-lisp/core"
                "site-lisp/modules"
                "site-lisp/lang"
                "site-lisp/local"))
                (add-to-list 'load-path (expand-file-name path user-emacs-directory)))

(require 'platform)

(setq url-proxy-services
      (when my/proxy-url
        (let ((proxy (replace-regexp-in-string
                      "\\`https?://" "" my/proxy-url)))
          `(("no_proxy" . "^\\(localhost\\|10\\..*\\|192\\.168\\..*\\)")
            ("http" . ,proxy)
            ("https" . ,proxy)))))

(setq package-archives '(("gnu"    . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                         ("nongnu" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/")
                         ("melpa"  . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))

                                        ; core
(require 'bootstrap)
(straight-use-package '(org :branch "bugfix"))
(require 'options)

                                        ; modules
(require 'completion)
(require 'ui)
(require 'editor)
(require 'os)
(require 'terminal)
(require 'apps)
(require 'local)

                                        ; lang
(require 'init-lang)
(require 'init-org)

                                        ; local

(message "emacs init time %s" (emacs-init-time))

;;; init.el ends here
