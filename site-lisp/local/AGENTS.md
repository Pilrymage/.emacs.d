# AGENTS.md

This directory (`04-local`) is one subdirectory of a personal Emacs configuration located at `~/.emacs.d/`. It contains **locally-authored, single-purpose Elisp files** that are not general-purpose packages — they are personal utilities loaded after core, modules, and language layers.

## Project overview

The Emacs config follows a layered `site-lisp` architecture loaded by `~/.emacs.d/init.el`:

1. `01-core/` — bootstrap (straight.el, use-package) and global options
2. `02-modules/` — editor (evil), UI (doom-modeline, themes), completion (vertico/consult/orderless), terminal (vterm), OS integration, apps (elfeed)
3. `03-lang/` — language support (tree-sitter, org-mode)
4. `04-local/` — **this directory** — personal single-file utilities

No build system, no test framework, no linter. Files are loaded via `require` in `init.el`.

## Files in this directory

### `chord-highlight.el`
A `font-lock-add-keywords` minor mode that colorizes **musical chord notation** (roman numeral analysis with extensions like `IVΔ7`, `IIIm7`, chromatic alterations `2↑`, `3↓`, and the special pattern `-..X>`) using predefined faces with distinct background colors. Uses exact regex character classes (`\\bIIImΔ?7?\\b`).

### `org-wc-diff.el`
Displays an Org buffer's **word count** and the **delta from a git baseline** (last commit before today's writing-day boundary) in the mode line. Key behaviors:

- The "writing day" boundary is configurable via `org-wc-diff-day-boundary-hour` (default: 4, meaning 4:00 AM).
- Word counting handles both Latin (regex-based) and CJK (per-character) text.
- Git operations use `vc-git-root` and `process-file` to invoke `git log`/`git show` directly — no external library.
- Tracked files come from `org-wc-diff-tracked-files` (explicit list) or `org-wc-diff-tracked-directories` (all Org files directly in listed dirs). Cache uses `(cons truename boundary-key)` as keys.
- Global minor mode `global-org-wc-diff-mode` auto-enables per-buffer via `find-file-hook` and `after-change-major-mode-hook`.
- **Gotcha**: Line 369-370 sets hardcoded defaults (`org-wc-diff-tracked-files` and activates the global mode) — this runs on `require`, not lazily. The same lines are duplicated in `init.el:38-39`.

### `send-to-emacs.el`
An HTTP server (port 8080, bound to `0.0.0.0`) that presents a web form; submitted text is `insert`ed into the current Emacs buffer. Uses the `web-server` package (must be installed). Functions: `send-to-emacs-start`, `send-to-emacs-stop`. Serves a self-contained HTML page with inline CSS.

## Conventions

- **`lexical-binding: t`** in all files.
- **`provide`** at end of each file matching the filename (e.g., `(provide 'chord-highlight)`).
- **Double-hyphen private functions**: `org-wc-diff--schedule-refresh`, `send-to-emacs--escape-html`.
- **`use-package`** is the standard declaration macro (bootstrapped via straight.el in `01-core/bootstrap.el`).
- **No `defgroup`/`defcustom`** unless the file is meant to be user-configurable (`org-wc-diff.el` is the exception).
- **No autoloads** — files are loaded unconditionally in `init.el`.
- **Package manager**: straight.el (declarative, git-based), with `use-package` as the configuration layer. Packages referenced in `04-local` files (like `web-server`) are expected to already be installed.
- **Platform**: Windows (primary), with macOS fallback paths in some modules. Paths use Unix-style forward slashes.

## Commands

There is no build, test, or lint step. To reload a file interactively: `M-x eval-buffer` or `M-x load-file`. To reload the full config: restart Emacs or `M-x eval-buffer` on `init.el`.

## Related files outside this directory

| File | Relevance |
|---|---|
| `~/.emacs.d/init.el` | Loads all `04-local` files via `require`, duplicates some `org-wc-diff` init |
| `~/.emacs.d/site-lisp/01-core/bootstrap.el` | Sets up straight.el, use-package, load-path |
| `~/.emacs.d/site-lisp/02-modules/apps.el` | Configures elfeed and elfeed-translate (a separate straight.el package from GitHub) |
| `~/.emacs.d/site-lisp/02-modules/editor.el` | Defines `my/org-leader-def` keybindings used by org-wc-diff user |
| `~/.emacs.d/site-lisp/03-lang/lang-org.el` | Org-mode configuration (tree-sitter src modes, emphasis hiding, etc.) |
