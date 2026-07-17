(use-package web-server
  :defer t)

(require 'subr-x)
(require 'web-server)

(defvar send-to-emacs-server nil)

(defun send-to-emacs--escape-html (text)
  (let ((escaped (or text "")))
    (setq escaped (replace-regexp-in-string "&" "&amp;" escaped t t))
    (setq escaped (replace-regexp-in-string "<" "&lt;" escaped t t))
    (setq escaped (replace-regexp-in-string ">" "&gt;" escaped t t))
    (setq escaped (replace-regexp-in-string "\"" "&quot;" escaped t t))
    escaped))

(defun send-to-emacs--response (process code content-type body)
  (ws-response-header
   process code
   (cons "Content-Type" content-type)
   (cons "Content-Length" (string-bytes body)))
  (ws-send process body))
(defun send-to-emacs--page (&optional notice message)
  (format
   (concat
    "<!doctype html>\n"
    "<html lang=\"zh-CN\">\n"
    "<head>\n"
    "<meta charset=\"utf-8\">\n"
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
    "<title>Send to Emacs</title>\n"
    "<style>\n"
    ":root{color-scheme:light;--bg:#f4efe7;--panel:#fffdf8;--text:#1f1a17;"
    "--muted:#6b625b;--accent:#b85c38;--accent-strong:#8f3f20;--border:#e4d7ca;}\n"
    "*{box-sizing:border-box;}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"
    "\"Segoe UI\",sans-serif;background:linear-gradient(180deg,#f7f1e8 0%%,#efe4d6 100%%);"
    "color:var(--text);min-height:100vh;display:flex;align-items:center;justify-content:center;"
    "padding:16px;}\n"
    ".card{width:min(100%%,560px);background:var(--panel);border:1px solid var(--border);"
    "border-radius:20px;box-shadow:0 18px 50px rgba(90,59,35,.12);padding:20px;}\n"
    "h1{margin:0 0 8px;font-size:clamp(1.4rem,5vw,2rem);}p{margin:0 0 16px;color:var(--muted);"
    "line-height:1.5;}\n"
    "textarea{width:100%%;min-height:220px;border:1px solid var(--border);border-radius:16px;"
    "padding:14px 16px;font:inherit;resize:vertical;background:#fff;line-height:1.6;"
    "outline:none;}textarea:focus{border-color:var(--accent);box-shadow:0 0 0 4px "
    "rgba(184,92,56,.12);}\n"
    ".actions{display:flex;gap:12px;align-items:center;justify-content:space-between;"
    "margin-top:14px;flex-wrap:wrap;}\n"
    "button{appearance:none;border:0;border-radius:999px;background:var(--accent);color:#fff;"
    "padding:12px 18px;font:inherit;font-weight:600;min-width:120px;}button:active{transform:"
    "translateY(1px);}button:hover{background:var(--accent-strong);}\n"
    ".hint{font-size:.92rem;color:var(--muted);} .notice{margin:0 0 14px;padding:12px 14px;"
    "border-radius:14px;background:#f7e2d8;color:#7f341b;line-height:1.5;}\n"
    "@media (max-width:480px){body{padding:10px;}.card{padding:16px;border-radius:16px;}"
    "textarea{min-height:180px;}.actions{align-items:stretch;}button{width:100%%;}}\n"
    "</style>\n"
    "</head>\n"
    "<body>\n"
    "<main class=\"card\">\n"
    "<h1>Send to Emacs</h1>\n"
    "<p>输入文本后发送到当前 Emacs 缓冲区。支持多行，按 <strong>Ctrl+Enter</strong> 也可发送。</p>\n"
    "%s\n"
    "<form method=\"get\" action=\"/\">\n"
    "<textarea name=\"message\" placeholder=\"在这里输入要发送到 Emacs 的文字...\">%s</textarea>\n"
    "<div class=\"actions\">\n"
    "<span class=\"hint\">发送后页面会保留，便于继续输入。</span>\n"
    "<button type=\"submit\">发送</button>\n"
    "</div>\n"
    "</form>\n"
    "</main>\n"
    "<script>\n"
    "const form=document.querySelector('form');\n"
    "const textarea=document.querySelector('textarea');\n"
    "textarea.focus();\n"
    "textarea.addEventListener('keydown',event=>{if(event.key==='Enter'&&event.ctrlKey){"
    "event.preventDefault();form.requestSubmit();}});\n"
    "</script>\n"
    "</body>\n"
    "</html>\n")
   (if (string-empty-p (or notice ""))
       ""
     (format "<div class=\"notice\">%s</div>"
             (send-to-emacs--escape-html notice)))
   (send-to-emacs--escape-html message)))

(defun send-to-emacs-handler (req)
  (pcase-let (((eieio process headers body) req))
    (ignore body)
    (if-let* ((message (assoc-default "message" headers))
              (decoded (decode-coding-string message 'utf-8)))
        (progn
          (insert decoded)
          (send-to-emacs--response
           process 200 "text/html; charset=utf-8"
           (send-to-emacs--page "已发送到 Emacs。" "")))
      (send-to-emacs--response
       process 200 "text/html; charset=utf-8"
       (send-to-emacs--page)))))

(defun send-to-emacs-stop ()
  (interactive)
  (when send-to-emacs-server
    (message "Close old server")
    (ws-stop send-to-emacs-server)
    (setq send-to-emacs-server nil)))

(defun send-to-emacs-start ()
  (interactive)
  (send-to-emacs-stop)
  (message "Start server")
  (setq send-to-emacs-server
        (ws-start #'send-to-emacs-handler 8080
                  nil :host "0.0.0.0")))

(provide 'send-to-emacs)
