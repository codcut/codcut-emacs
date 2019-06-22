(defgroup codcut nil
  "Codcut settings."
  :group 'convenience)

(defcustom codcut-token nil
  "Codcut access token."
  :type '(string)
  :group 'codcut)

(defconst post-endpoint
  "http://localhost:8080/api/posts")

(defun get-selected-text ()
  "Retrieve the current selected text or nil."
  (if (use-region-p)
      (buffer-substring (region-beginning) (region-end)) nil))

(defun get-file-extension ()
  "Retrieve the file extension or nil."
  (if (buffer-file-name)
      (file-name-extension (buffer-file-name)) nil))

(defun get-major-mode ()
  "Retrieve the current major mode."
  (symbol-name major-mode))

(defun handle-response (status)
  "Handle Codcut response."
  (kill-buffer (current-buffer)))

(defun post-code (code description language)
  "Send a new post to Codcut."
  (if (not codcut-token)
      (throw 'request-error (error "You must set codcut-token first.")))
  (let ((url-request-method "POST")
        (url-request-extra-headers
         `(("Authorization" . ,(format "Bearer %s" codcut-token))
           ("Content-Type" . "application/json")))
        (url-request-data
         (json-encode-alist
          `(("code" . ,code)
            ("body" . ,description)
            ("language" . ,language)))))
    (url-retrieve post-endpoint 'handle-response)))

(defun share-to-codcut ()
  "Entry point function."
  (interactive)
  (let ((code 'get-selected-text)
        (description (read-string "Enter a description (optional): "))
        (language 'get-file-extension))
    (catch 'request-error
      (post-code code description language))))
