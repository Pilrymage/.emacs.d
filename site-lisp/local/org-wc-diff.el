;;; org-wc-diff.el --- Org word count delta in mode line -*- lexical-binding: t; -*-

(require 'org)
(require 'org-element)
(require 'subr-x)
(require 'vc-git)

(defgroup org-wc-diff nil
  "Track Org writing word counts against a git baseline."
  :group 'org)

(defcustom org-wc-diff-tracked-files nil
  "List of Org files tracked by `global-org-wc-diff-mode'."
  :type '(repeat file))

(defcustom org-wc-diff-tracked-directories nil
  "List of directories tracked by `global-org-wc-diff-mode'.

Only files directly inside these directories are matched."
  :type '(repeat directory))

(defcustom org-wc-diff-show-word-count t
  "Whether to show the current word count in the mode line."
  :type 'boolean)

(defcustom org-wc-diff-show-delta t
  "Whether to show the delta from today's git baseline in the mode line."
  :type 'boolean)

(defcustom org-wc-diff-day-boundary-hour 4
  "Hour used as the writing day boundary."
  :type 'integer)

(defcustom org-wc-diff-refresh-delay 0.5
  "Idle delay in seconds before refreshing after edits."
  :type 'number)

(defcustom org-wc-diff-mode-line-format " %s"
  "Format string used to render the mode line payload."
  :type 'string)

(defvar org-wc-diff--baseline-cache (make-hash-table :test #'equal))
(defvar org-wc-diff--tracked-files-cache nil)
(defvar org-wc-diff--tracked-directories-cache nil)

(defvar-local org-wc-diff--mode-line "")
(defvar-local org-wc-diff--refresh-timer nil)
(defvar-local org-wc-diff--current-count-cache nil)
(defvar-local org-wc-diff--current-count-tick nil)
(defvar-local org-wc-diff--boundary-key nil)
(defconst org-wc-diff--global-mode-string-symbol 'org-wc-diff--mode-line)

(defun org-wc-diff--normalize-paths (paths)
  "Return expanded truenames for PATHS."
  (delq nil
        (mapcar (lambda (path)
                  (when (and path (not (string-empty-p path)))
                    (file-truename (expand-file-name path))))
                paths)))

(defun org-wc-diff--refresh-tracked-caches ()
  "Refresh cached tracked path lists."
  (setq org-wc-diff--tracked-files-cache
        (org-wc-diff--normalize-paths org-wc-diff-tracked-files)
        org-wc-diff--tracked-directories-cache
        (org-wc-diff--normalize-paths org-wc-diff-tracked-directories)))

(defun org-wc-diff--tracked-file-p (file)
  "Return non-nil when FILE matches the tracking configuration."
  (let* ((truename (file-truename file))
         (directory (file-name-directory truename)))
    (or (member truename org-wc-diff--tracked-files-cache)
        (member directory org-wc-diff--tracked-directories-cache))))

(defun org-wc-diff--eligible-buffer-p (&optional buffer)
  "Return non-nil when BUFFER should use `org-wc-diff-mode'."
  (with-current-buffer (or buffer (current-buffer))
    (and (derived-mode-p 'org-mode)
         buffer-file-name
         (org-wc-diff--tracked-file-p buffer-file-name))))

(defun org-wc-diff--current-boundary-time ()
  "Return the start time of the current writing day."
  (let* ((decoded (decode-time (current-time)))
         (hour (nth 2 decoded))
         (day (nth 3 decoded))
         (month (nth 4 decoded))
         (year (nth 5 decoded))
         (today-boundary
          (encode-time 0 0 org-wc-diff-day-boundary-hour day month year)))
    (if (< hour org-wc-diff-day-boundary-hour)
        (time-subtract today-boundary (days-to-time 1))
      today-boundary)))

(defun org-wc-diff--current-boundary-key ()
  "Return a stable string key for the current writing day boundary."
  (format-time-string "%Y-%m-%dT%H:%M:%S%z"
                      (org-wc-diff--current-boundary-time)))

(defun org-wc-diff--git-root (file)
  "Return the git root for FILE, or nil."
  (vc-git-root file))

(defun org-wc-diff--git-relative-path (file root)
  "Return FILE relative to ROOT with POSIX separators."
  (subst-char-in-string
   ?\\ ?/
   (file-relative-name (file-truename file) (file-truename root))
   t))

(defun org-wc-diff--git-string (root &rest args)
  "Run git with ARGS in ROOT and return stdout on success."
  (with-temp-buffer
    (let ((default-directory root))
      (when (eq 0 (apply #'process-file "git" nil t nil args))
        (string-trim (buffer-string))))))

(defun org-wc-diff--baseline-cache-key (file boundary-key)
  "Return baseline cache key for FILE and BOUNDARY-KEY."
  (cons (file-truename file) boundary-key))

(defun org-wc-diff--clear-current-count-cache ()
  "Clear cached current buffer count."
  (setq org-wc-diff--current-count-cache nil
        org-wc-diff--current-count-tick nil))

(defun org-wc-diff--clear-baseline-cache (&optional file)
  "Clear baseline cache for FILE, or current buffer file when omitted."
  (let ((target (or file buffer-file-name)))
    (when target
      (let ((true-target (file-truename target))
            stale-keys)
        (maphash (lambda (key _value)
                   (when (string= (car key) true-target)
                     (push key stale-keys)))
                 org-wc-diff--baseline-cache)
        (dolist (key stale-keys)
          (remhash key org-wc-diff--baseline-cache))))))

(defun org-wc-diff--cjk-char-p (char)
  "Return non-nil when CHAR should count as one CJK word."
  (memq (aref char-script-table char)
        '(han kana hangul cjk-misc bopomofo)))

(defun org-wc-diff--count-plain-string (text)
  "Count words in TEXT using mixed CJK and Latin rules."
  (let ((cjk-count 0)
        (latin-count 0))
    (dolist (token (split-string text "[[:space:]\n\r\t]+" t))
      (if (seq-some #'org-wc-diff--cjk-char-p token)
          (dolist (char (string-to-list token))
            (when (org-wc-diff--cjk-char-p char)
              (setq cjk-count (1+ cjk-count))))
        (let ((start 0))
          (while (string-match
                  "\\(?:[[:alpha:][:digit:]]+\\(?:['_-][[:alpha:][:digit:]]+\\)*\\)"
                  token start)
            (setq latin-count (1+ latin-count)
                  start (match-end 0))))))
    (+ cjk-count latin-count)))

(defun org-wc-diff--count-org-buffer ()
  "Count visible Org writing words in the current buffer."
  (let ((tree (org-element-parse-buffer))
        (count 0))
    (org-element-map tree 'plain-text
      (lambda (text)
        (setq count
              (+ count (org-wc-diff--count-plain-string text)))))
    count))

(defun org-wc-diff--count-org-string (text)
  "Count words in Org TEXT."
  (with-temp-buffer
    (insert text)
    (let ((delay-mode-hooks t)
          (org-inhibit-startup t))
      (org-mode))
    (org-wc-diff--count-org-buffer)))

(defun org-wc-diff--compute-baseline-data (file)
  "Compute git baseline data for FILE."
  (let ((root (org-wc-diff--git-root file)))
    (if (not root)
        (list :repo nil :rev nil :count 0)
      (let* ((relative-path (org-wc-diff--git-relative-path file root))
             (cutoff (time-subtract (org-wc-diff--current-boundary-time)
                                    (seconds-to-time 1)))
             (rev (org-wc-diff--git-string
                   root
                   "log"
                   "--follow"
                   (format "--before=%s"
                           (format-time-string "%Y-%m-%dT%H:%M:%S%z" cutoff))
                   "-n" "1"
                   "--format=%H"
                   "--"
                   relative-path))
             (content (and (not (string-empty-p rev))
                           (org-wc-diff--git-string
                            root "show" (format "%s:%s" rev relative-path)))))
        (list :repo root
              :rev (unless (string-empty-p rev) rev)
              :count (if content
                         (org-wc-diff--count-org-string content)
                       0))))))

(defun org-wc-diff--baseline-data (file boundary-key)
  "Return cached baseline data for FILE at BOUNDARY-KEY."
  (let* ((cache-key (org-wc-diff--baseline-cache-key file boundary-key))
         (cached (gethash cache-key org-wc-diff--baseline-cache 'missing)))
    (if (eq cached 'missing)
        (let ((computed (org-wc-diff--compute-baseline-data file)))
          (puthash cache-key computed org-wc-diff--baseline-cache)
          computed)
      cached)))

(defun org-wc-diff--current-count ()
  "Return the cached current buffer word count."
  (let ((tick (buffer-chars-modified-tick)))
    (unless (and org-wc-diff--current-count-cache
                 (equal org-wc-diff--current-count-tick tick))
      (setq org-wc-diff--current-count-cache (org-wc-diff--count-org-buffer)
            org-wc-diff--current-count-tick tick))
    org-wc-diff--current-count-cache))

(defun org-wc-diff--format-delta (delta)
  "Return a display string for DELTA."
  (cond
   ((> delta 0) (format "+%d" delta))
   ((< delta 0) (number-to-string delta))
   (t "0")))

(defun org-wc-diff--compose-mode-line (current-count delta)
  "Return the mode line string for CURRENT-COUNT and DELTA."
  (let (parts)
    (when org-wc-diff-show-word-count
      (push (format "WC:%d" current-count) parts))
    (when org-wc-diff-show-delta
      (push (format "Δ:%s" (org-wc-diff--format-delta delta)) parts))
    (if parts
        (format org-wc-diff-mode-line-format
                (string-join (nreverse parts) " "))
      "")))

(defun org-wc-diff--update-mode-line ()
  "Refresh cached mode line text for the current buffer."
  (let ((boundary-key (org-wc-diff--current-boundary-key)))
    (unless (equal boundary-key org-wc-diff--boundary-key)
      (setq org-wc-diff--boundary-key boundary-key)
      (org-wc-diff--clear-current-count-cache))
    (if (and buffer-file-name (org-wc-diff--eligible-buffer-p))
        (let* ((current-count (org-wc-diff--current-count))
               (baseline (org-wc-diff--baseline-data buffer-file-name boundary-key))
               (delta (- current-count (plist-get baseline :count))))
          (setq org-wc-diff--mode-line
                (org-wc-diff--compose-mode-line current-count delta)))
      (setq org-wc-diff--mode-line ""))
    (force-mode-line-update)))

(defun org-wc-diff--cancel-refresh-timer ()
  "Cancel any pending refresh timer in the current buffer."
  (when (timerp org-wc-diff--refresh-timer)
    (cancel-timer org-wc-diff--refresh-timer)
    (setq org-wc-diff--refresh-timer nil)))

(defun org-wc-diff--run-refresh (buffer)
  "Refresh BUFFER when it is still live."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq org-wc-diff--refresh-timer nil)
      (when org-wc-diff-mode
        (org-wc-diff--update-mode-line)))))

(defun org-wc-diff--schedule-refresh (&rest _args)
  "Schedule a delayed refresh for the current buffer."
  (when org-wc-diff-mode
    (org-wc-diff--cancel-refresh-timer)
    (setq org-wc-diff--refresh-timer
          (run-with-idle-timer
           org-wc-diff-refresh-delay nil
           #'org-wc-diff--run-refresh
           (current-buffer)))))

(defun org-wc-diff--after-save ()
  "Refresh buffer state after saving."
  (org-wc-diff--clear-current-count-cache)
  (org-wc-diff--schedule-refresh))

(defun org-wc-diff--disable-local ()
  "Disable local hooks and cached display."
  (org-wc-diff--cancel-refresh-timer)
  (remove-hook 'after-change-functions #'org-wc-diff--schedule-refresh t)
  (remove-hook 'after-save-hook #'org-wc-diff--after-save t)
  (setq-local global-mode-string
              (delete org-wc-diff--global-mode-string-symbol global-mode-string))
  (setq org-wc-diff--mode-line ""))

(defun org-wc-diff--enable-mode-line-segment ()
  "Expose `org-wc-diff' through `global-mode-string' in the current buffer."
  (setq-local global-mode-string
              (delete org-wc-diff--global-mode-string-symbol global-mode-string))
  (setq-local global-mode-string
              (append global-mode-string
                      (list org-wc-diff--global-mode-string-symbol))))

;;;###autoload
(defun org-wc-diff-refresh (&optional clear-cache)
  "Refresh the current buffer's `org-wc-diff-mode' display.

With prefix argument CLEAR-CACHE, clear git baseline cache first."
  (interactive "P")
  (when clear-cache
    (org-wc-diff--clear-baseline-cache))
  (setq org-wc-diff--boundary-key nil)
  (org-wc-diff--clear-current-count-cache)
  (org-wc-diff--update-mode-line))

;;;###autoload
(define-minor-mode org-wc-diff-mode
  "Show current Org word count and today's delta in the mode line."
  :lighter nil
  (if org-wc-diff-mode
      (progn
        (add-hook 'after-change-functions #'org-wc-diff--schedule-refresh nil t)
        (add-hook 'after-save-hook #'org-wc-diff--after-save nil t)
        (org-wc-diff--enable-mode-line-segment)
        (setq org-wc-diff--boundary-key nil)
        (org-wc-diff--clear-current-count-cache)
        (org-wc-diff--update-mode-line))
    (org-wc-diff--disable-local)))

(defun org-wc-diff--sync-buffer (&optional buffer)
  "Enable or disable `org-wc-diff-mode' in BUFFER."
  (with-current-buffer (or buffer (current-buffer))
    (if (and global-org-wc-diff-mode (org-wc-diff--eligible-buffer-p))
        (unless org-wc-diff-mode
          (org-wc-diff-mode 1))
      (when org-wc-diff-mode
        (org-wc-diff-mode -1)))))

(defun org-wc-diff--sync-all-buffers ()
  "Synchronize `org-wc-diff-mode' across existing buffers."
  (dolist (buffer (buffer-list))
    (org-wc-diff--sync-buffer buffer)))

(defun org-wc-diff--global-buffer-hook ()
  "Update local mode state for the current buffer."
  (org-wc-diff--sync-buffer (current-buffer)))

;;;###autoload
(define-minor-mode global-org-wc-diff-mode
  "Automatically enable `org-wc-diff-mode' for tracked Org files."
  :global t
  (if global-org-wc-diff-mode
      (progn
        (org-wc-diff--refresh-tracked-caches)
        (add-hook 'find-file-hook #'org-wc-diff--global-buffer-hook)
        (add-hook 'after-change-major-mode-hook #'org-wc-diff--global-buffer-hook)
        (org-wc-diff--sync-all-buffers))
    (remove-hook 'find-file-hook #'org-wc-diff--global-buffer-hook)
    (remove-hook 'after-change-major-mode-hook #'org-wc-diff--global-buffer-hook)
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when org-wc-diff-mode
          (org-wc-diff-mode -1))))))


(setq org-wc-diff-tracked-files '("D:/github/notes.org/2026.org"))
(global-org-wc-diff-mode 1)

(provide 'org-wc-diff)

;;; org-wc-diff.el ends here
