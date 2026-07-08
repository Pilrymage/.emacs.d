# AGENTS.md

Personal Emacs configuration at `~/.emacs.d/` — modular, layered, purpose-built.

## Architecture

```
init.el                          # entry point: proxy, ELPA mirrors, load-path, requires
early-init.el                    # runs before init.el: GC, native-comp, frame setup
custom.el                        # managed by M-x customize (safe-local-variable-values only)
site-lisp/
  core/                          # bootstrap (straight.el + use-package), options, platform
  modules/                       # editor (evil), UI, completion, terminal, OS, apps
  lang/                          # language support (tree-sitter, org-mode, langs)
  local/                         # personal single-file utilities ← see AGENTS.md there
```

Each layer is loaded by `init.el` via `require`. Module files use `provide` matching their filename.

## Package manager

**straight.el** (declarative, git-based), with **use-package** as the declaration macro. Bootstrapped in `core/bootstrap.el`, which installs straight.el on first run if not present. `straight-use-package-by-default` is `t`, so `(use-package foo)` implies `:straight t`.

**ELPA mirrors** point to Tsinghua University mirrors (set in `init.el`).

## Key conventions

- **`lexical-binding: t`** in all `.el` files.
- **`provide`** at the end of each file, matching the filename (e.g., `(provide 'completion)` from `completion.el`).
- **`use-package`** is the standard form; packages are always declared with `:defer t` or a hook unless they must load immediately.
- **`--` for private functions** (e.g., `modules-ui--neotree-no-confirm`).
- **No `defgroup`/`defcustom`** unless the file is intended as user-configurable.
- **No autoloads** — files are loaded unconditionally in `init.el`.
- **No build system, no test framework, no linter.** Reload interactively with `M-x eval-buffer` or restart Emacs.
- **`normal-top-level-add-subdirs-to-load-path`** is used in bootstrap plus explicit `add-to-list` in `init.el`.

## Platform

**Primary: Windows** (`windows-nt`). macOS (`darwin`) and Linux (`gnu/linux`) are also supported.

Platform detection is centralized in `core/platform.el` via three boolean constants:

```elisp
my/macos-p    ;; (eq system-type 'darwin)
my/linux-p    ;; (memq system-type '(gnu/linux gnu/kfreebsd))
my/windows-p  ;; (eq system-type 'windows-nt)
```

Two additional platform-aware constants are defined there:

| Constant | Purpose | Windows value | Elsewhere |
|---|---|---|---|
| `my/org-notes-repository` | Org journal/notes root | `"D:/github/notes.org"` | `"~/notes.org"` |
| `my/open-command` | OS file opener | `"start"` | `"open"` (macOS) / `"xdg-open"` (Linux) |

All other config files should use these constants rather than raw `(eq system-type ...)` checks. Exception: `early-init.el` uses `(featurep 'ns)` for the NS transparent titlebar — this is a GUI toolkit check, not an OS check, and `platform.el` is not yet loaded when `early-init.el` runs.

**Proxy**: HTTP/HTTPS via `127.0.0.1:7897` (set in `init.el:3-6` and `apps.el` for elfeed). `url-proxy-services` configured at the very top so `straight.el` bootstrap also goes through proxy.

Path separators use Unix-style forward slashes everywhere (including on Windows).

## `local/` compatibility policy

Files under `local/` are designed as **standalone, potentially redistributable utilities**. They must not depend on this config's internal conventions (platform constants, `data-dir`, `cache-dir`, etc.) and should contain their own platform detection logic. This keeps them extractable as independent packages.

## Module summary

| File | Purpose | Key packages |
|---|---|---|
| `core/bootstrap.el` | straight.el setup, `use-package`, `el-patch`, load-path, GC tuning | straight.el, use-package, el-patch |
| `core/options.el` | Global Emacs options, frame defaults, data/cache dirs, encoding | better-defaults |
| `core/platform.el` | Platform detection constants and OS-specific paths/vars | — (no packages) |
| `modules/editor.el` | Evil mode with Colemak-friendly bindings, Org keybindings, snippets, formatting, undo, VC, dirvish, pangu-spacing | evil (+surround, commentary, args, easymotion, embrace, exchange, lion, nerd-commenter, traces, quick-diff), apheleia, dirvish, undo-fu (+session), which-key |
| `modules/completion.el` | Vertico/consult/orderless/marginalia/embark minibuffer completion | vertico, orderless, consult, marginalia, embark |
| `modules/ui.el` | Doom modeline, themes, fonts, neotree, writeroom, line numbers, scrolling | doom-modeline, modus-operandi-deuteranopia theme, Iosevka Term, LXGW WenKai Mono TC, neotree, writeroom, mixed-pitch, indent-bars, diff-hl, blamer, pixel-scroll-precision |
| `modules/terminal.el` | vterm, magit, forge, quickrun, tree-sitter, ssh-deploy | vterm, magit (+delta), forge, quickrun, treesit-auto |
| `modules/os.el` | tramp, clipboard, terminal cursor | tramp, xclip, clipetty, evil-terminal-cursor-changer, kkp |
| `modules/apps.el` | elfeed (RSS), verb (HTTP client in Org), telega (Telegram) | elfeed, elfeed-org, elfeed-translate, verb, telega |
| `lang/lang-general.el` | Tree-sitter, Agda2, Rust, Markdown, OCaml, Haskell, bison, flex, anki-editor | treesit-auto, agda2-mode, rust-mode, markdown-mode, tuareg, haskell-mode, avy, helpful, rainbow-delimiters, ox-gfm, ob-powershell |
| `lang/lang-org.el` | Full Org-mode config: TODO states, LaTeX preview (imagemagick), bullets, capture, journal, presentation, git auto-sync | org-modern, org-modern-indent, org-superstar, org-download, org-journal, org-tree-slide, org-appear, org-fragtog, org-super-links, cdlatex, ox-hugo, org-re-reveal |
| `local/*` | Personal single-file utilities (self-contained, redistributable) | See `site-lisp/local/AGENTS.md` |

## Gotchas

1. **Hardcoded personal paths**: Several absolute paths are hardcoded:
   - `init.el`: `"D:/github/notes.org/2026.org"` (org-wc-diff tracked file)
   - `apps.el`: `"D:/github/elfeed-translate"` (local repo for elfeed-translate)
   - `platform.el`: `my/org-notes-repository` → `"D:/github/notes.org"` on Windows
   - `lang-org.el`: `temporary-file-directory` override for Windows
   - `editor.el`: scoop paths for librime and Emacs headers on Windows

2. **Duplicate init**: `org-wc-diff` configuration appears both at the bottom of `org-wc-diff.el` and in `init.el`. Changing one without the other causes confusion.

3. **Evil keybindings are Colemak-remapped**: The `my/evil-global-binding` alist in `editor.el` remaps standard Evil keys to Colemak positions (`u/e/n/i` for movement, `h` for backward-word-end, `k/K` for search). This is not standard Evil and affects all modes.

4. **`lang-org.el` ends with two `provide` directives** (`init-org` and `lang-org`). Only `lang-org` is required.

5. **`agda-mode locate`** is called at the end of `init.el` via `shell-command-to-string` — if agda is not installed, this may error silently.

6. **Hook-like functions named with `-h` suffix**: e.g., `+evil-embrace-latex-mode-hook-h`, `+zen-enable-mixed-pitch-mode-h`. These are actual hook functions, not hooks themselves.

7. **`vterm` vs `eshell`**: On Windows, `SPC \`` opens eshell; on non-Windows it opens vterm (configured in `editor.el`).

8. **API keys in plaintext**: `init.el:42` (org-hydrus) and `apps.el` (elfeed-translate) contain API keys. Never commit these.

9. **`local/` files are self-contained**: They do not use `my/*` platform constants or other config-internal symbols. Any platform logic is inline.

## How to reload

```elisp
M-x eval-buffer   ;; reload current file
M-x load-file     ;; reload any .el file
;; Full restart: M-x restart-emacs or close and reopen
```

## Related files

| File | Purpose |
|---|---|
| `~/.emacs.d/AGENTS.md` | This file |
| `~/.emacs.d/site-lisp/local/AGENTS.md` | Detailed docs for personal utilities |
| `~/.emacs.d/straight/repos/` | straight.el package clones |
| `~/.emacs.d/cache/` | undo-fu sessions, org-hydrus thumbnails |
| `~/.emacs.d/data/` | transient and forge persistent data |
