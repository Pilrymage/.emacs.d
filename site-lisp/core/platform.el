;;; core/platform.el --- Platform detection and constants -*- lexical-binding: t; -*-

(defconst my/macos-p   (eq system-type 'darwin)
  "Non-nil if running on macOS.")

(defconst my/linux-p   (memq system-type '(gnu/linux gnu/kfreebsd))
  "Non-nil if running on Linux or GNU/kFreeBSD.")

(defconst my/windows-p (eq system-type 'windows-nt)
  "Non-nil if running on Microsoft Windows.")

(defvar my/proxy-url
  (let ((proxy (getenv "EMACS_PROXY_URL")))
    (cond
     ((and proxy (member (downcase proxy) '("" "none" "off"))) nil)
     (proxy proxy)
     (my/windows-p "http://127.0.0.1:7897")))
  "Optional HTTP proxy URL used by network-aware modules.

The `EMACS_PROXY_URL' environment variable takes precedence.  Set it
to \"none\", \"off\", or an empty string to disable the Windows default.")

(defvar my/org-notes-repository
  (cond (my/windows-p "D:/github/notes.org")
        (t            "~/notes.org"))
  "Root directory for Org notes and journal files.

Platform-specific: uses `D:/github/notes.org` on Windows,
`~/notes.org` elsewhere.")

(if my/windows-p
    (custom-set-variables '(epg-gpg-program "C:/Program Files/GnuPG/bin/gpg.EXE")))

(defconst my/open-command
  (cond (my/macos-p   "open")
        (my/linux-p   "xdg-open")
        (my/windows-p "start"))
  "Default command to open files with the OS default application.

On macOS this is `open`, on Linux `xdg-open`, on Windows `start`.")

(provide 'platform)

;;; platform.el ends here
