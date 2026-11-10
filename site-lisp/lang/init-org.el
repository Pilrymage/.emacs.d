;;; lang/init-org.el --- Org-mode writing environment -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'seq)

;; Core editing

(defconst my/org--unpaired-opening-chars '(?< ?‘ ?“)
  "Opening characters that should remain unpaired in Org buffers.")

(defun my/org--electric-pair-inhibit-p (char)
  "Return non-nil when Electric Pair should not pair CHAR in Org buffers."
  (or (memq char my/org--unpaired-opening-chars)
      (let ((predicate (default-value 'electric-pair-inhibit-predicate)))
        (and predicate (funcall predicate char)))))

(defun my/org--configure-electric-pair ()
  "Leave Org Tempo's `<` and Chinese opening quotes unpaired."
  (setq-local electric-pair-inhibit-predicate
              #'my/org--electric-pair-inhibit-p))

(defconst my/org--cjk-emphasis-spacing-keywords
  '(("\\cc\\( \\)[*/_=~+]\\cc.*?[*/_=~+]"
     (0 (prog1 nil
          (when org-hide-emphasis-markers
            (add-text-properties
             (match-beginning 1) (match-end 1) '(invisible t))))))
    ("[*/_=~+].*?\\cc[*/_=~+]\\( \\)\\cc"
     (0 (prog1 nil
          (when org-hide-emphasis-markers
            (add-text-properties
             (match-beginning 1) (match-end 1) '(invisible t)))))))
  "Font-lock rules that hide markup spacing around CJK text.")

(defun my/org-timer-record-and-stop-and-done ()
  "Record and stop the current Org timer, then mark the entry done."
  (interactive)
  (org-timer)
  (org-timer-stop)
  (org-todo 'done))

(defun my/org-clock-out-and-done ()
  "Clock out of the current Org entry, then mark it done."
  (interactive)
  (org-clock-out)
  (org-todo 'done))

(defun my/org--in-notes-repository-p ()
  "Return non-nil when the current file is in the notes repository."
  (and buffer-file-name
       (file-in-directory-p buffer-file-name my/org-notes-repository)))

(defun my/org-confirm-babel-evaluate (language _body)
  "Ask before evaluating LANGUAGE except trusted local Python blocks."
  (not (and (string= language "python")
            (my/org--in-notes-repository-p))))

(defun my/org--configure-babel-python ()
  "Use the current project's Python for Babel and Python sessions."
  (when-let ((python (my/python-resolve-interpreter)))
    (setq-local org-babel-python-command python
                python-shell-interpreter python)))

(defun my/org-babel-select-python (python)
  "Select PYTHON for Babel and Python sessions in the current buffer."
  (interactive
   (list (read-file-name "Python executable: "
                         nil (my/python-resolve-interpreter) t)))
  (unless (file-executable-p python)
    (user-error "Not an executable file: %s" python))
  (setq-local org-babel-python-command (expand-file-name python)
              python-shell-interpreter (expand-file-name python))
  (message "Org Babel Python: %s" org-babel-python-command))

(defun my/org-babel-python-environment ()
  "Display the Python executable, version, and installed packages."
  (interactive)
  (let ((directory default-directory)
        (python (or (and (boundp 'org-babel-python-command)
                         (stringp org-babel-python-command)
                         org-babel-python-command)
                    (my/python-resolve-interpreter))))
    (unless python
      (user-error "No Python interpreter found"))
    (with-current-buffer (get-buffer-create "*Org Python Environment*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "Directory: %s\nInterpreter: %s\n\n"
                        directory python))
        (let ((default-directory directory))
          (call-process python nil t nil "--version")
          (insert "\nInstalled packages:\n\n")
          (unless (zerop (call-process python nil t nil "-m" "pip" "list"))
            (insert "\nUnable to query packages with pip.\n")))
        (goto-char (point-min))
        (special-mode))
      (display-buffer (current-buffer)))))

(defun my/org-notes-status ()
  "Open Magit for the Org notes repository."
  (interactive)
  (magit-status my/org-notes-repository))

(defun my/org-hugo-export-all ()
  "Export every valid Hugo subtree in the current Org file."
  (interactive)
  (org-hugo-export-wim-to-md :all-subtrees))

;; Line width.  Widths are counted in columns: ASCII = 1, CJK = 2, so
;; `fill-column' 80 holds 80 Latin characters or 40 Han characters.
;; Org buffers are soft-wrapped by `visual-line-mode' inside the
;; `writeroom-mode' margins (see ui.el), so the file is never modified.

;; Break lines between CJK characters (not only at spaces) and respect
;; kinsoku rules, so punctuation such as ，。」never starts a line.
(setq word-wrap-by-category t)

(defun my/org--refresh-text-width ()
  "Recompute `visual-fill-column' margins after a text-scale change."
  (when (bound-and-true-p visual-fill-column-mode)
    (visual-fill-column-adjust)))

(add-hook 'text-scale-mode-hook #'my/org--refresh-text-width)

(defun my/visual-fill-column--set-margins (window)
  "Set WINDOW margins so the text area is a fixed number of columns.
Replacement for `visual-fill-column--set-margins'.  Upstream measures
columns in the remapped default face, which under `mixed-pitch-mode'
is the proportional CJK font (one column ≈ one Han character), so
\"80 columns\" became ~80 Han characters.  Here a column is always the
frame's monospace character width, scaled by `text-scale-mode', so 80
columns = 80 Latin characters = 40 Han characters at any zoom level."
  (with-current-buffer (window-buffer window)
    (let* ((char-px (frame-char-width (window-frame window)))
           (scale (if (bound-and-true-p text-scale-mode)
                      (expt text-scale-mode-step text-scale-mode-amount)
                    1.0))
           (cols (or visual-fill-column-width fill-column))
           (margins (window-margins window))
           (avail-px (+ (window-body-width window t)
                        (* char-px (+ (or (car margins) 0)
                                      (or (cdr margins) 0)))))
           (total (max 0 (floor (- avail-px (* cols char-px scale))
                                char-px)))
           (left (if visual-fill-column-center-text (/ total 2) 0))
           (right (- total left)))
      (when visual-fill-column-extra-text-width
        (setq left (max 0 (- left (car visual-fill-column-extra-text-width)))
              right (max 0 (- right (cdr visual-fill-column-extra-text-width)))))
      (when (and (eq bidi-paragraph-direction 'right-to-left) (= left 0))
        (setq left right right 0))
      (set-window-margins window left right))))

(with-eval-after-load 'visual-fill-column
  (advice-add 'visual-fill-column--set-margins
              :override #'my/visual-fill-column--set-margins))

(defun my/org-check-line-width (&optional width)
  "List lines in the current buffer wider than WIDTH columns.
WIDTH defaults to `fill-column'; CJK characters count as two
columns.  Src blocks, tables, and link-only lines are skipped.
Only meaningful for hard-wrapped text."
  (interactive "P")
  (let* ((width (if width (prefix-numeric-value width) fill-column))
         (source (current-buffer))
         (file (or (buffer-file-name) (buffer-name)))
         (hits '()))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (let* ((line (buffer-substring-no-properties
                      (line-beginning-position) (line-end-position)))
               (cols (string-width line)))
          (when (and (> cols width)
                     (not (string-match-p "\\`[ \t]*\\(|\\|#\\+\\|\\[\\[[^] ]+\\]\\]\\'\\)" line))
                     (not (and (derived-mode-p 'org-mode)
                               (org-in-src-block-p t))))
            (push (format "%s:%d:%d: %d columns (> %d)\n"
                          file (line-number-at-pos) (1+ width) cols width)
                  hits)))
        (forward-line 1)))
    (with-current-buffer (get-buffer-create "*Line Width*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "-*- line width check: %s, limit %d -*-\n\n"
                        (buffer-name source) width))
        (apply #'insert (nreverse hits))
        (compilation-mode)
        (goto-char (point-min)))
      (display-buffer (current-buffer)))
    (message "%d line(s) wider than %d columns" (length hits) width)))

(use-package org
  :straight nil
  :hook ((org-mode . visual-line-mode)
         (org-mode . my/org--configure-electric-pair)
         (org-mode . my/org--configure-babel-python)
         (org-babel-after-execute . org-redisplay-inline-images))
  :init
  (setq org-directory my/org-notes-repository
        org-agenda-files (list my/org-notes-repository)
        org-default-notes-file
        (expand-file-name "capture.org" my/org-notes-repository)
        org-todo-keywords
        '((sequence "TODO(t)" "DOING(i)" "HANGUP(h)" "|"
                    "DONE(d)" "CANCEL(c)"))
        org-todo-keyword-faces '(("HANGUP" . warning))
        org-priority-faces '((?A . error)
                             (?B . warning)
                             (?C . success))
        org-log-done 'time
        org-catch-invisible-edits 'smart
        org-startup-indented t
        org-startup-numerated t
        org-ellipsis (if (char-displayable-p ?⏷) " ⏷" nil)
        org-image-actual-width nil
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-confirm-babel-evaluate #'my/org-confirm-babel-evaluate
        org-capture-templates
        '(("n" "Note" entry (file org-default-notes-file)
           "* TODO %?\n\n%i"
           :empty-lines 1)))
  :config
  (font-lock-remove-keywords 'org-mode my/org--cjk-emphasis-spacing-keywords)
  (font-lock-add-keywords
   'org-mode my/org--cjk-emphasis-spacing-keywords 'append)
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python . t))))

(use-package org-tempo
  :straight nil
  :after org
  :config
  (dolist (template '(("el" . "src emacs-lisp")
                      ("sh" . "src bash")
                      ("py" . "src python :results output")
                      ("js" . "src javascript")
                      ("cc" . "src c")
                      ("cp" . "src cpp")
                      ("ru" . "src rust")
                      ("pw" . "src powershell")))
    (add-to-list 'org-structure-template-alist template)))

;; Appearance

(use-package org-modern
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))

(use-package org-modern-indent
  :straight (:type git :host github :repo "jdtsmith/org-modern-indent")
  :config
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :init
  (setq org-appear-autoentities t
        org-appear-autolinks t
        org-appear-autosubmarkers t))

;; Links, images, and clipboard

(use-package htmlize
  :defer t)

(use-package ox-clip
  :defer t)

(use-package org-cliplink
  :defer t)

(use-package org-rich-yank
  :defer t)

(use-package orgit
  :defer t)

(use-package orgit-forge
  :defer t)

(use-package org-download
  :defer t
  :hook (dired-mode . org-download-enable)
  :init
  (setq-default org-download-image-dir "./images"
                org-download-heading-lvl nil)
  (setq org-download-timestamp "_%Y%m%d-%H%M%S"))

;; Journal

(use-package org-journal
  :defer t
  :init
  (setq org-journal-file-type 'yearly
        org-journal-date-format "%Y/%m/%d W%W D%j（%a）"
        org-journal-dir my/org-notes-repository
        org-journal-file-format "%Y.org"))

;; LaTeX editing and preview

(defconst my/org--latex-preview-header
  (concat "\\documentclass{article}\n"
          "\\usepackage[usenames]{color}\n"
          "\\usepackage{amsmath}\n"
          "\\usepackage{amssymb}\n"
          "\\usepackage{fontspec}\n"
          "\\usepackage{xeCJK}\n"
          "\\IfFontExistsTF{LXGW WenKai Mono}\n"
          "  {\\setCJKmainfont{LXGW WenKai Mono}}\n"
          "  {\\IfFontExistsTF{LXGW WenKai}\n"
          "    {\\setCJKmainfont{LXGW WenKai}}\n"
          "    {\\setCJKmainfont{FandolSong-Regular}}}\n"
          "\\pagestyle{empty}")
  "XeLaTeX header used only for Org fragment previews.")

(defun my/org--create-formula-image-from-temp-directory
    (function &rest arguments)
  "Run Org preview FUNCTION with ARGUMENTS from its temporary directory.

This avoids a dvisvgm Windows error when an Org buffer and the
system temporary directory are on different drive letters."
  (let ((default-directory
         (file-name-as-directory
          (expand-file-name temporary-file-directory))))
    (apply function arguments)))

(use-package cdlatex
  :hook (org-mode . turn-on-org-cdlatex))

(use-package auctex
  :defer t)

(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

(defvar my/org-latex-preview-base-scale 1.0
  "LaTeX preview scale at zoom level 0; multiplied by the text-scale factor.")

(defun my/org--latex-preview-follow-text-scale ()
  "Re-render LaTeX previews in this Org buffer at the current zoom level."
  (when (derived-mode-p 'org-mode)
    (let ((factor (if (bound-and-true-p text-scale-mode)
                      (expt text-scale-mode-step text-scale-mode-amount)
                    1.0)))
      (setq-local org-format-latex-options
                  (plist-put (copy-sequence
                              (default-value 'org-format-latex-options))
                             :scale (* my/org-latex-preview-base-scale factor)))
      ;; Only re-render when previews are actually shown.  Images are
      ;; cached per scale in ltximg/, so zooming back is cheap.
      (when (seq-some (lambda (ov)
                        (eq (overlay-get ov 'org-overlay-type)
                            'org-latex-overlay))
                      (overlays-in (point-min) (point-max)))
        (org-latex-preview '(64))       ; clear all in buffer
        (org-latex-preview '(16))))))   ; preview all in buffer

(add-hook 'text-scale-mode-hook #'my/org--latex-preview-follow-text-scale)

(with-eval-after-load 'org
  (when my/windows-p
    (advice-add
     #'org-create-formula-image :around
     #'my/org--create-formula-image-from-temp-directory))
  (setq org-preview-latex-default-process
        (if (and (executable-find "xelatex")
                 (executable-find "dvisvgm")
                 (assq 'xelatex org-preview-latex-process-alist))
            'xelatex
          'dvisvgm))
  (when-let ((process (assq 'xelatex org-preview-latex-process-alist)))
    (setcdr process
            (plist-put (cdr process)
                       :latex-header my/org--latex-preview-header)))
  (setq org-format-latex-options
        (plist-put org-format-latex-options
                   :scale my/org-latex-preview-base-scale)))

;; Export and Babel extensions

(use-package ox-hugo
  :after ox)

(use-package ob-powershell
  :after org
  :straight (:host github :repo "rkiggen/ob-powershell")
  :init
  (setq org-babel-powershell-os-command
        (if (executable-find "pwsh") "pwsh" "powershell")))

;; Notes auto-sync: commit local changes first, then rebase onto the remote
;; and push.  Output goes to *org-git-sync*; only failures are reported.

(defvar my/org-git-sync-interval (* 20 60)
  "Seconds between automatic syncs of `my/org-notes-repository'.")

(defvar my/org-git-sync-timer nil
  "The single timer driving `my/org-git-sync-silent'.")

(defun my/org-git-sync--commit-command ()
  "Return a shell command that commits all changes, if there are any."
  (format "git add -A && (git diff --cached --quiet || git commit -q -m \"Auto-sync: %s\")"
          (format-time-string "%Y-%m-%d %H:%M:%S")))

(defun my/org-git-sync--sentinel (process _event)
  "Report a failed sync PROCESS."
  (when (and (memq (process-status process) '(exit signal))
             (/= (process-exit-status process) 0))
    (message "Org-sync: 同步失败（退出码 %d），详见 %s"
             (process-exit-status process)
             (buffer-name (process-buffer process)))))

(defun my/org-git-sync-silent ()
  "Commit, pull --rebase and push the Org notes repository in the background."
  (interactive)
  (let ((default-directory (file-name-as-directory my/org-notes-repository)))
    (when (and (file-directory-p default-directory)
               (not (process-live-p (get-process "org-git-sync"))))
      (let ((buffer (get-buffer-create "*org-git-sync*")))
        (with-current-buffer buffer
          (let ((inhibit-read-only t)) (erase-buffer)))
        (set-process-sentinel
         (start-process-shell-command
          "org-git-sync" buffer
          (concat (my/org-git-sync--commit-command)
                  " && git pull --rebase -q && git push -q"))
         #'my/org-git-sync--sentinel)))))

(defun my/org-git-sync-on-exit ()
  "Commit pending note changes synchronously before Emacs exits.
Pushing is left to the next sync, so exiting never waits on the network."
  (let ((default-directory (file-name-as-directory my/org-notes-repository)))
    (when (file-directory-p default-directory)
      (call-process-shell-command (my/org-git-sync--commit-command)))))

;; Keep exactly one timer, even when this file is reloaded.
(when (timerp my/org-git-sync-timer)
  (cancel-timer my/org-git-sync-timer))
(setq my/org-git-sync-timer
      (run-at-time 60 my/org-git-sync-interval #'my/org-git-sync-silent))
(add-hook 'kill-emacs-hook #'my/org-git-sync-on-exit)

;; Real-time HTML preview in an external browser (Firefox etc.)
;; maple-preview runs a local websocket server and pushes re-exported HTML
;; to the browser page on every change (no save needed).

(use-package websocket
  :straight t)

(defconst my/maple-preview-org-style
  "<style id=\"my-maple-preview-org-content\">
html, body {
  margin: 0;
  padding: 0;
  width: 100%;
  min-height: 100%;
  overflow-x: hidden;
}
body {
  box-sizing: border-box;
  padding: 2rem 0 4rem;
  color: #24292f;
  background: #fff;
  font-family: system-ui, -apple-system, \"Segoe UI\", \"Microsoft YaHei\", sans-serif;
  font-size: 16px;
  line-height: 1.75;
}
#content {
  box-sizing: border-box;
  width: calc(100% - 3rem);
  max-width: 72rem;
  margin: 0 auto;
  padding: 0 1rem;
}
.title {
  margin: 0 0 2rem;
  line-height: 1.25;
}
.outline-2,
.outline-3,
.outline-4 {
  margin-top: 2rem;
}
pre, table {
  max-width: 100%;
}
pre {
  overflow-x: auto;
  white-space: pre;
}
img, video, iframe {
  max-width: 100%;
}
</style>"
  "Additional CSS used only by the live Org preview.")

(defun my/maple-preview-org-html-content ()
  "Export the current Org buffer as HTML with preview-only layout CSS."
  (let ((html (maple-preview-html-content)))
    (replace-regexp-in-string
     "</head>"
     (concat my/maple-preview-org-style "</head>")
     html t t)))

(defconst my/maple-preview-layout-style
  "<style id=\"my-maple-preview-layout\">
html, body {
  width: 100%;
  height: 100%;
  margin: 0 !important;
  padding: 0 !important;
  overflow-x: hidden;
}
.container {
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
}
#preview.markdown-body {
  box-sizing: border-box;
  width: 100vw;
  min-width: 0;
  max-width: none;
  height: 100vh;
  margin: 0;
  padding: 0;
}
#preview > iframe {
  position: fixed !important;
  top: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  left: 0 !important;
  inset: 0 !important;
  display: block !important;
  box-sizing: border-box !important;
  width: 100vw !important;
  height: 100vh !important;
  margin: 0 !important;
  padding: 0 !important;
  border: 0 !important;
  overflow: auto !important;
}
</style>"
  "Shell CSS that keeps maple-preview's iframe flush with the viewport.
Upstream creates the iframe with an inline position:absolute and no
left/top, so it can start mid-viewport and overflow horizontally; the
!important rules here override those inline styles.")

(defun my/maple-preview--windows-newline-fix (text)
  "Replace LF with CR in websocket TEXT (fix from maple-preview's README)."
  (replace-regexp-in-string "\n" "\r" text))

(use-package maple-preview
  :straight (:host github :repo "honmaple/emacs-maple-preview"
                   :files ("*.el" "index.html" "static"))
  :commands (maple-preview-mode)
  :custom
  (maple-preview-render-modes '(org-mode markdown-mode html-mode web-mode))
  (maple-preview-auto-update t)
  (maple-preview-auto-scroll t)
  (maple-preview-auto-browser t)
  ;; Org is exported as HTML (not downsourced to markdown) so LaTeX/fragments
  ;; travel through; MathJax handles the formulas in the browser page.
  (maple-preview-render-alist '((org-mode . my/maple-preview-org-html-content)
                                (t . maple-preview-markdown-content)))
  :config
  (add-to-list 'maple-preview-styles my/maple-preview-layout-style t)
  ;; maple-preview's websocket breaks on Windows CRLF newlines upstream.
  (when my/windows-p
    (advice-add 'maple-preview-websocket-text :filter-return
                #'my/maple-preview--windows-newline-fix)))

(provide 'init-org)

;;; lang/init-org.el ends here
