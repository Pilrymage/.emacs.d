;;; modules/apps.el --- Productivity apps -*- lexical-binding: t; -*-

(defconst modules-apps--elfeed-page-boundary-margin 4
  "Number of lines kept at the bottom of an Elfeed search window.")

(defface modules-apps-elfeed-page-boundary
  '((t :inherit shadow))
  "Face used for the Elfeed page boundary marker.")

(define-fringe-bitmap 'modules-apps--elfeed-page-boundary
  [3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3] 16 2 'center)

(defvar-local modules-apps--elfeed-page-boundary-overlay nil)

(defun modules-apps--elfeed-point-on-last-window-line-p (&optional window)
  "Return non-nil when point reaches the Elfeed boundary in WINDOW."
  (let ((window (or window (selected-window))))
    (>= (count-lines (window-start window) (line-beginning-position))
        (- (window-body-height window)
           modules-apps--elfeed-page-boundary-margin))))

(defun modules-apps--elfeed-update-page-boundary (&optional window)
  "Put the Elfeed page boundary marker at its visible position in WINDOW."
  (let ((window (or window (get-buffer-window (current-buffer)))))
    (when (window-live-p window)
      (save-excursion
        (goto-char (window-start window))
        (let ((line-offset
               (max 0 (- (window-body-height window)
                         modules-apps--elfeed-page-boundary-margin))))
          (if (or (not (zerop (forward-line line-offset)))
                  (eobp))
              (when (overlayp modules-apps--elfeed-page-boundary-overlay)
                (delete-overlay modules-apps--elfeed-page-boundary-overlay)
                (setq modules-apps--elfeed-page-boundary-overlay nil))
            (unless (overlayp modules-apps--elfeed-page-boundary-overlay)
              (setq modules-apps--elfeed-page-boundary-overlay
                    (make-overlay (point) (point) nil t t))
              (overlay-put
               modules-apps--elfeed-page-boundary-overlay 'before-string
               (propertize
                " " 'display
                '(left-fringe modules-apps--elfeed-page-boundary
                              modules-apps-elfeed-page-boundary))))
            (move-overlay modules-apps--elfeed-page-boundary-overlay
                          (point) (point) (current-buffer))
            (overlay-put modules-apps--elfeed-page-boundary-overlay
                         'window window)))))))

(defun modules-apps--elfeed-window-scrolled (window _window-start)
  "Update the page boundary marker after WINDOW scrolls."
  (with-current-buffer (window-buffer window)
    (modules-apps--elfeed-update-page-boundary window)))

(defun modules-apps--elfeed-search-setup ()
  "Set up scrolling and its boundary marker in an Elfeed search buffer."
  (setq-local scroll-margin modules-apps--elfeed-page-boundary-margin)
  (add-hook 'post-command-hook
            #'modules-apps--elfeed-update-page-boundary nil t)
  (add-hook 'window-scroll-functions
            #'modules-apps--elfeed-window-scrolled nil t)
  (add-hook 'window-configuration-change-hook
            #'modules-apps--elfeed-update-page-boundary nil t)
  (modules-apps--elfeed-update-page-boundary))

(defun modules-apps--elfeed-mark-read-and-scroll ()
  "Mark selected Elfeed entries read and put the next edge entry on top."
  (interactive)
  (let ((had-region (use-region-p))
        (window (selected-window)))
    (call-interactively #'elfeed-search-untag-all-unread)
    (when (and (not had-region)
               (not (eobp))
               (modules-apps--elfeed-point-on-last-window-line-p window))
      (recenter 0))))

;; elfeed is currently disabled: `:straight nil' keeps straight from
;; installing or activating it, so nothing below ever loads.
(use-package elfeed
  :straight nil
  :defer t
  :hook (elfeed-search-mode . modules-apps--elfeed-search-setup)
  :init
  (setq elfeed-db-directory (concat data-dir "elfeed/")
        elfeed-search-trailing-width 10
        elfeed-search-title-max-width 120
        elfeed-search-filter "@1-month-ago +unread -translate_title"
        elfeed-curl-program-name "C:/Users/pilrymage/scoop/apps/curl/current/bin/curl.exe")
  :config
  (setq elfeed-curl-extra-arguments
        (when my/proxy-url
          (list "--proxy" my/proxy-url)))
  (elfeed-set-timeout 30)
  (elfeed-set-max-connections 4)
  (keymap-set elfeed-search-mode-map
              "r" #'modules-apps--elfeed-mark-read-and-scroll)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'elfeed-search-mode)
        (modules-apps--elfeed-search-setup))))
  (with-eval-after-load 'evil
    (evil-set-initial-state 'elfeed-search-mode 'emacs)
    (evil-set-initial-state 'elfeed-show-mode 'emacs)))
(use-package elfeed-org
  :straight nil
  :after elfeed
  :config
  (elfeed-org))

(use-package verb
  :defer t)

(provide 'apps)

;;; modules/apps.el ends here
