;;; lang/init-org.el --- Org-mode writing environment -*- lexical-binding: t; -*-

(require 'subr-x)

;; Core editing

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

(use-package cdlatex
  :hook (org-mode . turn-on-org-cdlatex))

(use-package auctex
  :defer t)

(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

(with-eval-after-load 'org
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
        (plist-put org-format-latex-options :scale 1.5)))

;; Export and Babel extensions

(use-package ox-hugo
  :after ox)

(use-package ob-powershell
  :after org
  :straight (:host github :repo "rkiggen/ob-powershell")
  :init
  (setq org-babel-powershell-os-command
        (if (executable-find "pwsh") "pwsh" "powershell")))

(provide 'init-org)

;;; lang/init-org.el ends here
