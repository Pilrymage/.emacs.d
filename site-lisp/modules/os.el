;;; modules/os.el --- OS integration -*- lexical-binding: t; -*-

(when (and (or my/macos-p my/linux-p)
           (or (daemonp) (display-graphic-p)))
  (use-package exec-path-from-shell
    :demand t
    :config
    (exec-path-from-shell-initialize)))

(defun modules-os--emacsclient-program ()
  "Return the emacsclient executable that ships with this Emacs."
  (let ((names (if my/windows-p
                   ;; emacsclientw does not pop up a console window.
                   '("emacsclientw.exe" "emacsclient.exe")
                 '("emacsclient"))))
    (or (seq-some (lambda (name)
                    (let ((file (expand-file-name name invocation-directory)))
                      (and (file-executable-p file) file)))
                  names)
        (seq-some #'executable-find names))))

(defun modules-os--open-client-frame-h ()
  "Open a graphical emacsclient frame right after the daemon has started.
Runs from `emacs-startup-hook', which fires after `server-start' in
daemon mode, so the server already accepts connections.  Skipped on
Linux when no graphical display is available (e.g. a systemd unit)."
  (when (and (daemonp)
             (or my/windows-p my/macos-p
                 (getenv "DISPLAY") (getenv "WAYLAND_DISPLAY")))
    (if-let* ((client (modules-os--emacsclient-program)))
        ;; Destination 0: run detached, don't wait for the client.
        ;; -a "" lets emacsclient find the server on its own (and start a
        ;; daemon if none is reachable) instead of erroring out.
        (call-process client nil 0 nil "-c" "-n" "-a" "")
      (message "emacsclient not found; no client frame opened"))))

(add-hook 'emacs-startup-hook #'modules-os--open-client-frame-h)

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
