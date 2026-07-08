;;; org-hydrus.el --- Hydrus integration for Org mode -*- lexical-binding: t; -*-

(require 'org)
(require 'cl-lib)
(require 'url)
(require 'json)
(require 'subr-x)

;;; Configuration

(defgroup org-hydrus nil
  "Embed Hydrus files in Org mode via a `hydrus:' link protocol."
  :group 'org)

(defcustom org-hydrus-api-url "http://127.0.0.1:45869"
  "Base URL of the Hydrus Client API server."
  :type 'string)

(defcustom org-hydrus-api-key ""
  "Access key for the Hydrus Client API.

If empty, requests are sent without authentication (read-only
access must be permitted on the Hydrus side)."
  :type 'string)

(defcustom org-hydrus-cache-dir
  (concat (if (boundp 'cache-dir)
              (symbol-value 'cache-dir)
            (file-name-as-directory
             (expand-file-name "cache" user-emacs-directory)))
          "org-hydrus/")
  "Directory for caching downloaded Hydrus files and thumbnails."
  :type 'directory)

(defcustom org-hydrus-default-description 'notes
  "Default description used when inserting a `hydrus:' link without one.

`notes'   — first Hydrus file note, falling back to truncated hash.
`tags'    — first tag across all tag services.
`hash'    — first 12 characters of the hash.
A string  — used verbatim."
  :type '(choice (const :tag "File notes" notes)
                 (const :tag "First tag" tags)
                 (const :tag "Truncated hash" hash)
                 (string :tag "Custom string")))

(defcustom org-hydrus-search-page-size 30
  "Maximum number of search results to fetch and display."
  :type 'integer)

(defcustom org-hydrus-search-thumbnail-width 200
  "Display width in pixels for thumbnails in the search buffer."
  :type 'integer)

;;; Internal state

(defvar org-hydrus--metadata-cache (make-hash-table :test #'equal)
  "Cache mapping file hashes to metadata hash tables.")

(defvar-local org-hydrus-search--target-buffer nil
  "Buffer where the selected link will be inserted.")
(defvar-local org-hydrus-search--target-marker nil
  "Marker for the insertion position in the target buffer.")
(defvar-local org-hydrus-search--items nil
  "List of (START-POS . HASH) entries for navigation.")
(defvar-local org-hydrus-search--current-tags nil
  "List of tags used for the current search filter.")
(defvar org-hydrus-search--tags-history nil
  "History of tag strings used in `org-hydrus-insert-by-search'.")

;;; --- API utilities ---

(defun org-hydrus--build-query (params)
  "Build a URL query string from PARAMS.
PARAMS is an alist.  List values are JSON-encoded (the Hydrus API
expects e.g. hashes=[\"a\",\"b\"] rather than repeated keys).
Booleans are encoded as JSON true/false."
  (mapconcat
   (lambda (pair)
     (let ((key (url-hexify-string (symbol-name (car pair))))
           (val (cdr pair)))
       (let* ((encoded
               (cond
                ((eq val t)   "true")
                ((null val)   "false")
                ((listp val)  (json-encode val))
                (t            (json-encode (format "%s" val)))))
              ;; json-encode wraps strings in quotes; strip them for
              ;; scalar strings so the value is not double-quoted.
              (clean
               (if (and (stringp val)
                        (string-prefix-p "\"" encoded))
                   (substring encoded 1 -1)
                 encoded)))
         (concat key "=" (url-hexify-string clean)))))
   params "&"))

(defun org-hydrus--api-url (path &optional params)
  "Construct a full Hydrus API URL from PATH and PARAMS."
  (concat org-hydrus-api-url path
          (and params (concat "?" (org-hydrus--build-query params)))))

(defun org-hydrus--request-json (path &optional params)
  "Make a synchronous GET request to PATH with PARAMS and parse JSON.
Returns the parsed JSON (hash-table) or nil on failure."
  (let* ((url (org-hydrus--api-url path params))
         (url-request-method "GET")
         (url-request-extra-headers
          (when (and org-hydrus-api-key (not (string-empty-p org-hydrus-api-key)))
            `(("Hydrus-Client-API-Access-Key" . ,org-hydrus-api-key)))))
    (condition-case err
        (let ((buffer (url-retrieve-synchronously url t nil)))
          (if (not buffer)
              nil
            (with-current-buffer buffer
              (unwind-protect
                  (progn
                    (goto-char (point-min))
                    (when (re-search-forward "\r?\n\r?\n" nil t)
                      (condition-case nil
                          (let ((json-object-type 'hash-table)
                                (json-array-type 'list)
                                (json-false :false)
                                (json-null :null))
                            (let ((json (json-read)))
                              (if (and (hash-table-p json)
                                       (gethash "error" json))
                                  (progn
                                    (message "org-hydrus: API error: %s"
                                             (gethash "error" json))
                                    nil)
                                json)))
                        (error nil))))
                (kill-buffer buffer)))))
      (error
       (message "org-hydrus: API request failed: %s" (error-message-string err))
       nil))))

(defun org-hydrus--download-to-file (url file)
  "Download URL to FILE, handling binary content correctly."
  (let ((url-request-method "GET")
        (url-request-extra-headers
         (when (and org-hydrus-api-key (not (string-empty-p org-hydrus-api-key)))
           `(("Hydrus-Client-API-Access-Key" . ,org-hydrus-api-key)))))
    (condition-case err
        (let ((buffer (url-retrieve-synchronously url t nil)))
          (if (not buffer)
              nil
            (with-current-buffer buffer
              (unwind-protect
                  (progn
                    (goto-char (point-min))
                    (when (re-search-forward "\r?\n\r?\n" nil t)
                      (let ((coding-system-for-write 'binary))
                        (write-region (point) (point-max) file nil 'silent))))
                (kill-buffer buffer)))))
      (error
       (message "org-hydrus: download failed: %s" (error-message-string err))
       nil))))

;;; --- Cache utilities ---

(defun org-hydrus--ensure-cache-dir ()
  "Create the cache directory if it does not exist."
  (unless (file-directory-p org-hydrus-cache-dir)
    (make-directory org-hydrus-cache-dir t)))

(defun org-hydrus--cache-file-path (hash)
  "Return the local cache file path for HASH."
  (org-hydrus--ensure-cache-dir)
  (expand-file-name hash org-hydrus-cache-dir))

(defun org-hydrus--thumbnail-cache-path (hash)
  "Return the local thumbnail cache file path for HASH."
  (org-hydrus--ensure-cache-dir)
  (expand-file-name (concat hash "-thumb") org-hydrus-cache-dir))

(defun org-hydrus--auth-params ()
  "Return an alist with the access-key parameter if configured."
  (when (and org-hydrus-api-key (not (string-empty-p org-hydrus-api-key)))
    `((Hydrus-Client-API-Access-Key . ,org-hydrus-api-key))))

(defun org-hydrus--file-url (hash)
  "Return the API URL for downloading the file with HASH."
  (org-hydrus--api-url "/get_files/file"
                       (cons `(hash . ,hash) (org-hydrus--auth-params))))

(defun org-hydrus--thumbnail-url (hash)
  "Return the API URL for the thumbnail of HASH."
  (org-hydrus--api-url "/get_files/thumbnail"
                       (cons `(hash . ,hash) (org-hydrus--auth-params))))

(defun org-hydrus--ensure-file-cached (hash)
  "Download the file for HASH to cache if not already present.
Return the cache file path."
  (let ((file (org-hydrus--cache-file-path hash)))
    (unless (file-exists-p file)
      (org-hydrus--download-to-file (org-hydrus--file-url hash) file))
    file))

(defun org-hydrus--ensure-thumbnail-cached (hash)
  "Download the thumbnail for HASH to cache if not already present.
Return the cache file path."
  (let ((file (org-hydrus--thumbnail-cache-path hash)))
    (unless (file-exists-p file)
      (org-hydrus--download-to-file (org-hydrus--thumbnail-url hash) file))
    file))

(defun org-hydrus--read-binary-file (file)
  "Read FILE contents as a unibyte string."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert-file-contents file)
    (buffer-string)))

;;; --- Metadata helpers ---

(defun org-hydrus--normalize-hash (hash)
  "Normalize a hash string to trimmed lowercase."
  (downcase (string-trim hash)))

(defun org-hydrus--image-p (mime)
  "Return non-nil if MIME is an image type."
  (and (stringp mime) (string-prefix-p "image/" mime)))

(defun org-hydrus--get-metadata (hash)
  "Fetch and cache metadata for HASH from the API.
Returns the metadata hash-table or nil."
  (let ((hash (org-hydrus--normalize-hash hash)))
    (or (gethash hash org-hydrus--metadata-cache)
        (let ((result (org-hydrus--request-json
                       "/get_files/file_metadata"
                       `((hashes . (,hash))))))
          (when (and result (gethash "metadata" result))
            (let ((md (car (gethash "metadata" result))))
              (when md
                (puthash hash md org-hydrus--metadata-cache)
                md)))))))

(defun org-hydrus--get-metadata-batch (hashes)
  "Fetch and cache metadata for all HASHES in a single API request."
  (let ((result (org-hydrus--request-json
                 "/get_files/file_metadata"
                 `((hashes . ,(mapcar #'org-hydrus--normalize-hash hashes))))))
    (when (and result (gethash "metadata" result))
      (dolist (md (gethash "metadata" result))
        (let ((hash (gethash "hash" md)))
          (when hash
            (puthash hash md org-hydrus--metadata-cache)))))))

(defun org-hydrus--get-mime (hash)
  "Return the MIME type string for HASH."
  (let ((md (org-hydrus--get-metadata hash)))
    (and md (gethash "mime" md))))

(defun org-hydrus--extract-tag-names (tag-container)
  "Extract tag name strings from a TAG-CONTAINER hash table.

The Hydrus API nests tags under `display_tags' (or
`storage_tags'), keyed by status code (\"0\" = current,
\"1\" = deleted, \"2\" = pending).  Each status maps to a list
of tag strings.  Only current tags (status \"0\") are returned."
  (when (and tag-container (hash-table-p tag-container))
    (let (all-tags)
      (maphash
       (lambda (status tag-list)
         (when (string= status "0")
           (dolist (tag tag-list)
             (push (if (hash-table-p tag)
                       (gethash "name" tag)
                     tag)
                   all-tags))))
       tag-container)
      (nreverse all-tags))))

(defun org-hydrus--get-tags (hash)
  "Return an alist of (SERVICE-NAME . TAG-LIST) for HASH.
Only current tags (display status 0) are included."
  (let* ((md (org-hydrus--get-metadata hash))
         (tags (and md (gethash "tags" md))))
    (when (and tags (hash-table-p tags))
      (let (result)
        (maphash
         (lambda (_ service-data)
           (when (hash-table-p service-data)
             (let* ((service-name (gethash "name" service-data))
                    (display-tags (gethash "display_tags" service-data))
                    (storage-tags (gethash "storage_tags" service-data))
                    (names (or (org-hydrus--extract-tag-names display-tags)
                               (org-hydrus--extract-tag-names storage-tags))))
               (when names
                 (push (cons (or service-name "unknown") names) result)))))
         tags)
        (nreverse result)))))

(defun org-hydrus--get-known-tags (hash)
  "Return a list of tag strings from the \"all known tags\" service for HASH."
  (let ((tag-pairs (org-hydrus--get-tags hash)))
    (cl-some (lambda (pair)
               (when (string= (car pair) "all known tags")
                 (cdr pair)))
             tag-pairs)))

(defun org-hydrus--get-urls (hash)
  "Return a list of known source URLs for HASH."
  (let ((md (org-hydrus--get-metadata hash)))
    (and md (gethash "known_urls" md))))

(defun org-hydrus--get-notes (hash)
  "Return an alist of (NAME . CONTENT) for HASH."
  (let* ((md (org-hydrus--get-metadata hash))
         (notes (and md (gethash "notes" md))))
    (when (and notes (hash-table-p notes))
      (let (result)
        (maphash (lambda (k v) (push (cons k v) result)) notes)
        (nreverse result)))))

(defun org-hydrus--generate-description (hash &optional metadata)
  "Generate a description string for HASH from optional METADATA."
  (let ((md (or metadata (org-hydrus--get-metadata hash)))
        (short (substring (org-hydrus--normalize-hash hash) 0 12)))
    (cond
     ((stringp org-hydrus-default-description)
      org-hydrus-default-description)
     ((eq org-hydrus-default-description 'notes)
      (let ((notes (and md (gethash "notes" md))))
        (if (and notes (hash-table-p notes))
            (let (first)
              (maphash (lambda (_ v) (unless first (setq first v))) notes)
              (or first short))
          short)))
     ((eq org-hydrus-default-description 'tags)
      (let ((tag-pairs (org-hydrus--get-tags hash)))
        (or (and tag-pairs
                 (cdar tag-pairs)
                 (car (cdar tag-pairs)))
            short)))
     (t short))))

;;; --- Search ---

(defun org-hydrus--search-files (tags)
  "Search Hydrus for files matching TAGS.
TAGS is a list of tag strings.  Returns a list of hash strings."
  (let ((result (org-hydrus--request-json
                 "/get_files/search_files"
                 `((tags . ,tags)
                   (return_hashes . t)))))
    (cond
     ((and result (gethash "hashes" result))
      (gethash "hashes" result))
     ((and result (gethash "file_ids" result))
      (let* ((file-ids (gethash "file_ids" result))
             (md-result (org-hydrus--request-json
                         "/get_files/file_metadata"
                         `((file_ids . ,file-ids)))))
        (when (and md-result (gethash "metadata" md-result))
          (mapcar (lambda (md) (gethash "hash" md))
                  (gethash "metadata" md-result)))))
     (t nil))))

;;; --- Search result buffer ---

(defvar org-hydrus-search-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n")   #'org-hydrus-search-next)
    (define-key map (kbd "p")   #'org-hydrus-search-prev)
    (define-key map (kbd "y")   #'org-hydrus-search-copy-link)
    (define-key map (kbd "v")   #'org-hydrus-search-preview-current)
    (define-key map (kbd "b")   #'org-hydrus-search-open-external)
    (define-key map (kbd "g")   #'org-hydrus-search-refresh)
    (define-key map (kbd "RET") #'org-hydrus-search-open-current)
    (define-key map (kbd "q")   #'org-hydrus-search-quit)
    map)
  "Keymap for `org-hydrus-search-mode'.")

(define-derived-mode org-hydrus-search-mode special-mode "Hydrus Search"
  "Mode for browsing Hydrus search results in a single-column list.

\{org-hydrus-search-mode-map}")

(defvar org-hydrus-search--hash-width 6
  "Width of the truncated hash column in the search buffer.")

;;; --- Image preview mode ---

(defvar org-hydrus-image-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n") #'org-hydrus-image-next)
    (define-key map (kbd "p") #'org-hydrus-image-prev)
    (define-key map (kbd "y") #'org-hydrus-image-copy-link)
    (define-key map (kbd "b") #'org-hydrus-image-open-external)
    (define-key map (kbd "q") #'org-hydrus-image-quit)
    map)
  "Keymap for `org-hydrus-image-mode'.")

(define-derived-mode org-hydrus-image-mode special-mode "Hydrus Image"
  "Mode for viewing a full Hydrus image with navigation.

\{org-hydrus-image-mode-map}")

(defvar-local org-hydrus-image--hash nil
  "Hash of the image currently displayed.")
(defvar-local org-hydrus-image--search-buffer nil
  "The *Hydrus Search* buffer this image viewer belongs to.")

;;; --- OS external open ---

(defun org-hydrus--open-external (file)
  "Open FILE with the system default application."
  (cond
   ((eq system-type 'windows-nt)
    (call-process "cmd" nil 0 nil "/c" "start" "" file))
   ((eq system-type 'darwin)
    (call-process "open" nil 0 nil file))
   (t
    (call-process "xdg-open" nil 0 nil file))))

;;; --- Tags and notes helpers ---

(defun org-hydrus--format-tags-column (hash filter-tags)
  "Return a propertized string for the tags column of HASH.
FILTER-TAGS are the tags used in the current search; they are
placed first and highlighted.  Only tags from the 'all known tags'
service are included."
  (let* ((all-tags (org-hydrus--get-known-tags hash))
         (filter-set (mapcar #'downcase filter-tags))
         (matched (cl-remove-if-not
                   (lambda (tag) (member (downcase tag) filter-set))
                   all-tags))
         (rest (cl-remove-if
                (lambda (tag) (member (downcase tag) filter-set))
                all-tags))
         (ordered (append matched rest)))
    (mapconcat
     (lambda (tag)
       (if (member (downcase tag) filter-set)
           (propertize tag 'face 'font-lock-keyword-face)
         (propertize tag 'face 'font-lock-string-face)))
     ordered
     ", ")))

(defun org-hydrus--notes-string (hash)
  "Return a semicolon-separated string of all notes for HASH."
  (let ((notes (org-hydrus--get-notes hash)))
    (if notes
        (mapconcat #'cdr notes "; ")
      "")))

(defun org-hydrus--build-link (hash)
  "Build a `hydrus:' org link string for HASH."
  (let* ((md (org-hydrus--get-metadata hash))
         (desc (org-hydrus--generate-description hash md)))
    (format "[[hydrus:%s][%s]]" hash desc)))

;;; --- Search buffer display ---

(defun org-hydrus--display-search-results (hashes target-buffer target-marker filter-tags)
  "Display HASHES as a single-column list in a *Hydrus Search* buffer.
TARGET-BUFFER and TARGET-MARKER record where the inserted link
should go when the user selects an entry.
FILTER-TAGS is the list of tags used for this search."
  (let ((buffer (get-buffer-create "*Hydrus Search*"))
        (total (length hashes))
        (n 0))
    (org-hydrus--get-metadata-batch hashes)
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (org-hydrus-search-mode)
        (setq org-hydrus-search--target-buffer target-buffer
              org-hydrus-search--target-marker target-marker
              org-hydrus-search--items nil
              org-hydrus-search--current-tags filter-tags)
        (insert (propertize "Filter: " 'face 'font-lock-comment-face))
        (insert (propertize (mapconcat #'identity filter-tags " ")
                            'face 'font-lock-keyword-face))
        (insert "
")
        (insert (propertize (make-string 60 ?-) 'face 'font-lock-comment-face))
        (insert "
")
        (dolist (hash hashes)
          (setq n (1+ n))
          (message "Hydrus: loading metadata %d/%d..." n total)
          (let* ((short-hash (substring hash 0 (min org-hydrus-search--hash-width
                                                    (length hash))))
                 (tags-str (org-hydrus--format-tags-column hash filter-tags))
                 (notes-str (org-hydrus--notes-string hash))
                 (start (point)))
            (insert (propertize short-hash 'face 'font-lock-constant-face))
            (insert "  ")
            (insert tags-str)
            (insert "  ")
            (insert (propertize notes-str 'face 'font-lock-comment-face))
            (insert "
")
            (put-text-property start (point) 'org-hydrus-hash hash)
            (push (cons start hash) org-hydrus-search--items)))
        (setq org-hydrus-search--items
              (nreverse org-hydrus-search--items))
        (goto-char (point-min))
        (forward-line 2)
        (hl-line-mode 1))
      (message "Hydrus: search complete (%d results)." total))
    (pop-to-buffer buffer)))

;;; --- Search buffer navigation ---

(defun org-hydrus-search--current-hash ()
  "Return the hash at the current line, or nil."
  (or (get-text-property (point) 'org-hydrus-hash)
      (get-text-property (max (point-min) (1- (point)))
                         'org-hydrus-hash)))

(defun org-hydrus-search-next ()
  "Move point to the next search result."
  (interactive)
  (let ((next (cl-some (lambda (item)
                         (and (> (car item) (point)) (car item)))
                       org-hydrus-search--items)))
    (when next (goto-char next))))

(defun org-hydrus-search-prev ()
  "Move point to the previous search result."
  (interactive)
  (let ((prev (cl-some (lambda (item)
                         (and (< (car item) (point)) (car item)))
                       (reverse org-hydrus-search--items))))
    (when prev (goto-char prev))))

(defun org-hydrus-search-copy-link ()
  "Copy the `hydrus:' link for the result at point to the kill ring."
  (interactive)
  (let ((hash (org-hydrus-search--current-hash)))
    (unless hash
      (user-error "No search result at point"))
    (let ((link (org-hydrus--build-link hash)))
      (kill-new link)
      (message "Copied: %s" link))))

(defun org-hydrus-search-open-external ()
  "Open the file at point with the system image viewer."
  (interactive)
  (let ((hash (org-hydrus-search--current-hash)))
    (unless hash
      (user-error "No search result at point"))
    (let ((file (org-hydrus--ensure-file-cached hash)))
      (if (and file (file-exists-p file))
          (org-hydrus--open-external file)
        (message "File not cached for hash: %s" hash)))))

(defun org-hydrus-search-open-current ()
  "Open the image at point in a full-screen `*Hydrus Image*' buffer."
  (interactive)
  (let ((hash (org-hydrus-search--current-hash)))
    (unless hash
      (user-error "No search result at point"))
    (org-hydrus--show-image hash (current-buffer))))

(defun org-hydrus-search-insert-current ()
  "Insert the `hydrus:' link for the result at point into the target buffer."
  (interactive)
  (let ((hash (org-hydrus-search--current-hash)))
    (unless hash
      (user-error "No search result at point"))
    (let ((link (org-hydrus--build-link hash)))
      (with-current-buffer org-hydrus-search--target-buffer
        (save-excursion
          (goto-char (marker-position org-hydrus-search--target-marker))
          (insert link)))
      (message "Inserted: %s" link)
      (quit-window))))

(defun org-hydrus-search-preview-current ()
  "Preview the image for the result at point in a separate buffer."
  (interactive)
  (org-hydrus-search-open-current))

(defun org-hydrus-search-quit ()
  "Quit the Hydrus Search buffer and clean up."
  (interactive)
  (when (get-buffer "*Hydrus Image*")
    (kill-buffer "*Hydrus Image*"))
  (quit-window))

(defun org-hydrus-search-refresh ()
  "Re-run the search with the current filter tags."
  (interactive)
  (if (and org-hydrus-search--current-tags
           (consp org-hydrus-search--current-tags))
      (let* ((tags org-hydrus-search--current-tags)
             (hashes (org-hydrus--search-files tags)))
        (if (not hashes)
            (message "No results found for tags: %s"
                     (mapconcat #'identity tags " "))
          (let ((limited (cl-subseq hashes 0
                                    (min (length hashes)
                                         org-hydrus-search-page-size))))
            (org-hydrus--display-search-results
             limited org-hydrus-search--target-buffer
             org-hydrus-search--target-marker tags))))
    (message "No filter tags in current search buffer.")))

;;; --- Image viewer ---

(defun org-hydrus--show-image (hash search-buffer)
  "Show the image for HASH in a `*Hydrus Image*' buffer.
SEARCH-BUFFER is the parent `*Hydrus Search*' buffer so
navigation can cycle through the search results."
  (let* ((mime (org-hydrus--get-mime hash))
         (buffer (get-buffer-create "*Hydrus Image*")))
    (if (not (org-hydrus--image-p mime))
        (message "File %s is not an image (mime: %s)" hash mime)
      (let ((file (org-hydrus--ensure-file-cached hash)))
        (when (and file (file-exists-p file))
          (with-current-buffer buffer
            (let ((inhibit-read-only t))
              (erase-buffer)
              (org-hydrus-image-mode)
              (setq org-hydrus-image--hash hash
                    org-hydrus-image--search-buffer search-buffer)
              (insert-image (create-image file))
              (goto-char (point-min))))
          (pop-to-buffer buffer))))))

(defun org-hydrus-image--navigate (direction)
  "Navigate to the next or previous image in the search results.
DIRECTION is 'next or 'prev."
  (let* ((search-buffer org-hydrus-image--search-buffer)
         (current-hash org-hydrus-image--hash))
    (when (and search-buffer (buffer-live-p search-buffer))
      (with-current-buffer search-buffer
        ;; Position point at the current hash in the search buffer
        (let ((items org-hydrus-search--items))
          (goto-char (point-min))
          (cl-loop for item in items
                   when (string= (cdr item) current-hash)
                   do (goto-char (car item))))
        ;; Move to next or prev
        (if (eq direction 'next)
            (org-hydrus-search-next)
          (org-hydrus-search-prev))
        ;; Open the image at the new position
        (let ((new-hash (org-hydrus-search--current-hash)))
          (when (and new-hash (not (string= new-hash current-hash)))
            (org-hydrus--show-image new-hash search-buffer)))))))

(defun org-hydrus-image-next ()
  "Show the next image from the search results."
  (interactive)
  (org-hydrus-image--navigate 'next))

(defun org-hydrus-image-prev ()
  "Show the previous image from the search results."
  (interactive)
  (org-hydrus-image--navigate 'prev))

(defun org-hydrus-image-copy-link ()
  "Copy the `hydrus:' link for the current image to the kill ring."
  (interactive)
  (when org-hydrus-image--hash
    (let ((link (org-hydrus--build-link org-hydrus-image--hash)))
      (kill-new link)
      (message "Copied: %s" link))))

(defun org-hydrus-image-open-external ()
  "Open the current image with the system image viewer."
  (interactive)
  (when org-hydrus-image--hash
    (let ((file (org-hydrus--ensure-file-cached org-hydrus-image--hash)))
      (when (and file (file-exists-p file))
        (org-hydrus--open-external file)))))

(defun org-hydrus-image-quit ()
  "Quit the image viewer and return to the search buffer."
  (interactive)
  (let ((search-buffer org-hydrus-image--search-buffer))
    (quit-window)
    (when (and search-buffer (buffer-live-p search-buffer))
      (pop-to-buffer search-buffer))))

;;; --- Link type: follow (C-c C-o) ---

(defun org-hydrus--follow (hash)
  "Display metadata for HASH in a `*Hydrus Metadata*' buffer."
  (let ((md (org-hydrus--get-metadata hash))
        (buffer (get-buffer-create "*Hydrus Metadata*")))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (org-mode)
        (insert "* Hydrus Metadata\n\n")
        (when md
          (insert (format "  - Hash: =%s=\n" hash))
          (insert (format "  - MIME: =%s=\n"
                          (or (gethash "mime" md) "unknown")))
          (let ((width (gethash "width" md))
                (height (gethash "height" md)))
            (when (and width height)
              (insert (format "  - Dimensions: =%dx%d=\n" width height))))
          (let ((size (gethash "size" md)))
            (when size
              (insert (format "  - File size: =%s bytes=\n" size))))
          (let ((tags (org-hydrus--get-tags hash)))
            (when tags
              (insert "\n** Tags\n")
              (dolist (pair tags)
                (insert (format "\n*** %s\n" (car pair)))
                (dolist (tag (cdr pair))
                  (insert (format "  - %s\n" tag))))))
          (let ((urls (org-hydrus--get-urls hash)))
            (when urls
              (insert "\n** Known URLs\n")
              (dolist (url urls)
                (insert (format "  - [[%s][%s]]\n" url url)))))
          (let ((notes (org-hydrus--get-notes hash)))
            (when notes
              (insert "\n** Notes\n")
              (dolist (note notes)
                (insert (format "  - *%s*: %s\n" (car note) (cdr note))))))
          (let ((file (org-hydrus--ensure-file-cached hash)))
            (when (and file (file-exists-p file))
              (insert (format "\n** Cached file: =%s=\n" file)))))
        (goto-char (point-min))
        (org-show-subtree))
      (read-only-mode 1))
    (display-buffer buffer)))

;;; --- Link type: export ---

(defun org-hydrus--file-export-url (hash)
  "Return the API URL for the file with HASH, including the auth key."
  (org-hydrus--api-url "/get_files/file"
                       (cons `(hash . ,hash) (org-hydrus--auth-params))))

(defun org-hydrus--export (path description backend)
  "Export a `hydrus:' link for various backends.
PATH is the hash, DESCRIPTION is the link description (may be nil),
BACKEND is the org export backend object."
  (require 'ox)
  (let* ((hash (org-hydrus--normalize-hash path))
         (mime (org-hydrus--get-mime hash))
         (desc (or description hash))
         (url (org-hydrus--file-export-url hash)))
    (cond
     ((and backend (org-export-derived-backend-p backend 'html))
      (if (org-hydrus--image-p mime)
          (format "<img src=\"%s\" alt=\"%s\" />" url desc)
        (format "<a href=\"%s\">%s</a>" url desc)))
     ((and backend (org-export-derived-backend-p backend 'latex))
      (if (org-hydrus--image-p mime)
          (let ((file (org-hydrus--ensure-file-cached hash)))
            (format "\\includegraphics[width=\\linewidth]{%s}" file))
        (format "\\url{%s}" url)))
     (t
      (format "[[%s][%s]]" url desc)))))

;;; --- Link type: inline image preview ---

(defun org-hydrus--make-image (file link)
  "Create an image object from FILE for LINK element.
Returns the image object or nil."
  (let* ((width (when (fboundp 'org-display-inline-image--width)
                  (org-display-inline-image--width link)))
         (type (and (image-type-available-p 'imagemagick)
                    width
                    'imagemagick))
         (props (delq nil (list (and width :width) width))))
    (condition-case err
        (if props
            (apply #'create-image file type nil props)
          (create-image file nil nil))
      (error
       (message "org-hydrus: create-image failed: %s" (error-message-string err))
       nil))))

(defun org-hydrus--place-image-overlay (image link)
  "Place IMAGE as an overlay on LINK element.
Registers the overlay in `org-link-preview-overlays' so that
`org-link-preview-clear' can clean it up."
  (let ((ov (make-overlay
             (org-element-begin link)
             (save-excursion
               (goto-char (org-element-end link))
               (unless (eolp) (skip-chars-backward " 	"))
               (point)))))
    (image-flush image)
    (overlay-put ov 'display image)
    (overlay-put ov 'face 'default)
    (overlay-put ov 'org-image-overlay t)
    (overlay-put
     ov 'modification-hooks
     (list (if (fboundp 'org-link-preview--remove-overlay)
               'org-link-preview--remove-overlay
             'org-display-inline-remove-overlay)))
    (when (boundp 'image-map)
      (overlay-put ov 'keymap image-map))
    (when (boundp 'org-link-preview-overlays)
      (cl-pushnew ov org-link-preview-overlays))
    t))

(defun org-hydrus--preview (ov path link)
  "Render a `hydrus:' link as an inline image preview.
OV is the overlay to display the image in.  PATH is the link
path (the hash).  LINK is the Org element for the link.
Returns non-nil on success."
  (when (display-graphic-p)
    (require 'image)
    (condition-case err
        (let* ((hash (org-hydrus--normalize-hash path))
               (mime (org-hydrus--get-mime hash)))
          (when (org-hydrus--image-p mime)
            (let ((file (org-hydrus--ensure-file-cached hash)))
              (when (and file (file-exists-p file))
                (let ((image (org-hydrus--make-image file link)))
                  (when image
                    (image-flush image)
                    (overlay-put ov 'display image)
                    (overlay-put ov 'face 'default)
                    (when (boundp 'image-map)
                      (overlay-put ov 'keymap image-map))
                    t))))))
      (error
       (message "org-hydrus: preview error: %s" (error-message-string err))
       nil))))

(defun org-hydrus--preview-linked-descriptions (&rest args)
  "Preview `hydrus:' links that have descriptions.

`org-link-preview-region' skips links with descriptions unless
INCLUDE-LINKED is non-nil.  This advice runs after it and handles
those skipped `hydrus:' links manually."
  (when (display-graphic-p)
    (require 'org-element)
    (condition-case err
        ;; org-link-preview-region signature: (include-linked refresh beg end)
        (let* ((beg (or (nth 2 args) (point-min)))
               (end (or (nth 3 args) (point-max))))
          (org-with-point-at beg
            (let ((case-fold-search t))
              (while (re-search-forward org-link-any-re end t)
                (forward-char -1)
                (let ((link (org-element-lineage (org-element-context) 'link t)))
                  (when (and link
                             (equal "hydrus" (org-element-property :type link))
                             (org-element-contents-begin link))
                    (let ((existing (get-char-property-and-overlay
                                     (org-element-begin link) 'org-image-overlay)))
                      (unless (car-safe existing)
                        (let* ((hash (org-hydrus--normalize-hash
                                      (org-element-property :path link)))
                               (mime (org-hydrus--get-mime hash)))
                          (when (org-hydrus--image-p mime)
                            (let ((file (org-hydrus--ensure-file-cached hash)))
                              (when (and file (file-exists-p file))
                                (let ((image (org-hydrus--make-image file link)))
                                  (when image
                                    (org-hydrus--place-image-overlay image link)))))))))))))))
      (error
       (message "org-hydrus: preview-linked-descriptions error: %s"
                (error-message-string err))
       nil))))

;;; --- Interactive commands ---

;;;###autoload
(defun org-hydrus-insert-by-hash (hash description)
  "Insert a `hydrus:' link for HASH at point.
If DESCRIPTION is empty, one is generated from Hydrus metadata."
  (interactive
   (let ((hash (read-string "Hydrus hash: "))
         (desc (read-string "Description (optional): ")))
     (list hash desc)))
  (let* ((hash (org-hydrus--normalize-hash hash))
         (desc (if (or (not description) (string-empty-p description))
                   (org-hydrus--generate-description hash)
                 description))
         (link (if (and desc (not (string-empty-p desc)))
                   (format "[[hydrus:%s][%s]]" hash desc)
                 (format "[[hydrus:%s]]" hash))))
    (insert link)))

;;;###autoload
(defun org-hydrus-insert-by-search (tags)
  "Search Hydrus for TAGS and display results for selection.
TAGS is a space-separated string of Hydrus tags.  Results appear
in a `*Hydrus Search*' buffer; press RET on an entry to insert
the link at the original cursor position.

When called with no prefix argument and a `*Hydrus Search*'
buffer already exists, reuses that buffer's current filter tags.
Otherwise uses the last tags from `org-hydrus-search--tags-history'.
With a prefix argument, always prompts for new tags."
  (interactive
   (let* ((search-buffer (get-buffer "*Hydrus Search*"))
          (existing-tags
           (when (and search-buffer (buffer-live-p search-buffer))
             (with-current-buffer search-buffer
               (when org-hydrus-search--current-tags
                 (mapconcat #'identity org-hydrus-search--current-tags " ")))))
          (default-tag (or existing-tags (car org-hydrus-search--tags-history)))
          (prompt (if default-tag
                      (format "Tags (space-separated) [default: %s]: " default-tag)
                    "Tags (space-separated): "))
          (input (if current-prefix-arg
                     (read-string prompt nil 'org-hydrus-search--tags-history)
                   (read-string prompt default-tag 'org-hydrus-search--tags-history))))
     (list (if (string-empty-p input) (or default-tag "") input))))
  (let* ((tag-list (split-string tags))
         (hashes (org-hydrus--search-files tag-list)))
    (if (not hashes)
        (message "No results found for tags: %s" tags)
      (let ((limited (cl-subseq hashes 0
                                (min (length hashes)
                                     org-hydrus-search-page-size))))
        (org-hydrus--display-search-results
         limited (current-buffer) (point-marker) tag-list)))))

;;; --- Registration ---

(org-link-set-parameters "hydrus"
                         :follow         #'org-hydrus--follow
                         :export         #'org-hydrus--export
                         :preview        #'org-hydrus--preview
                         :face           'org-link)

(with-eval-after-load 'org
  (when (fboundp 'org-link-preview-region)
    (advice-add 'org-link-preview-region :after
                #'org-hydrus--preview-linked-descriptions)))
(if (featurep 'evil)
    (prog1
        (evil-set-initial-state 'org-hydrus-search-mode 'emacs)
      (evil-set-initial-state 'org-hydrus-image-mode 'emacs)
      )
  t)


(provide 'org-hydrus)

;;; org-hydrus.el ends here
