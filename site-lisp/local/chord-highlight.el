;;; local/chord-highlight.el --- Highlight chords -*- lexical-binding: t; -*-

(defvar chord-highlight-keywords
  '(("\\bIIImΔ?7?\\b\\|\\bIIIΔ?7?\\b\\|\\bVΔ?7?\\b" . 'chord-red-face)
    ("\\bIVΔ?7?\\b\\|\\bIImΔ?7?\\b\\|\\bIIΔ?7?\\b" . 'chord-orange-face)
    ("\\bIΔ?7?\\b\\|\\bVImΔ?7?\\b\\|\\bVIΔ?7?\\b" . 'chord-green-face)
    ("\\bVmΔ?7?\\b" . 'chord-dark-red-face)
    ("\\bIVmΔ?7?\\b" . 'chord-dark-orange-face)
    ("\\bImΔ?7?\\b" . 'chord-dark-green-face)
    ("-..X>" . 'chord-bad-face)
    ("2↑\\|3↑\\|5↑\\|2↓\\|3↓\\|5↓" . 'chord-black-face)
    ))


(defface chord-black-face
  '((t :background "#000000" :foreground "white" :weight bold))
  "Face for nexus"
  :group 'chord-faces)

(defface chord-bad-face
  '((t :foreground "red" :weight bold))
  "Face for bad connection"
  :group 'chord-faces)
(defface chord-green-face
  '((t :background "#22c55e" :foreground "white" :weight bold))
  "Face for I and VIm chords"
  :group 'chord-faces)

(defface chord-orange-face
  '((t :background "#f59e0b" :foreground "white" :weight bold))
  "Face for IV and IIm chords"
  :group 'chord-faces)

(defface chord-red-face
  '((t :background "#ef4444" :foreground "white" :weight bold))
  "Face for V and IIIm chords"
  :group 'chord-faces)

(defface chord-dark-green-face
  '((t :background "#115e59" :foreground "white" :weight bold))
  "Face for V and IIIm chords"
  :group 'chord-faces)

(defface chord-dark-orange-face
  '((t :background "#ca8a04" :foreground "white" :weight bold))
  "Face for V and IIIm chords"
  :group 'chord-faces)

(defface chord-dark-red-face
  '((t :background "#b91c1c" :foreground "white" :weight bold))
  "Face for V and IIIm chords"
  :group 'chord-faces)

(define-minor-mode chord-highlight-mode
  "Minor mode for highlighting specific chord patterns."
  :lighter " ChordHL"
  (if chord-highlight-mode
      (progn
        (font-lock-add-keywords nil chord-highlight-keywords)
        (font-lock-flush)
        (font-lock-ensure))
    (font-lock-remove-keywords nil chord-highlight-keywords)
    (font-lock-flush)))

(provide 'chord-highlight-mode)

(provide 'chord-highlight)

;;; local/chord-highlight.el ends here
