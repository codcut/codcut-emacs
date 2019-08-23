;;; codcut-emacs.el --- Codcut plugin for the Emacs editor
     
;; Copyright (C) 2010-2019 Diego Pasquali

;; Author: Diego Pasquali <hello@dgopsq.space>
;; Keywords: codcut, share
;; Homepage: https://github.com/codcut/codcut-emacs

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Usage:
;; Highlight the code you want to
;; share and execute either `share-to-codcut`
;; or `share-to-codcut-redirect`.

;;; Code:

(defgroup codcut nil
  "Codcut settings."
  :group 'external)

(defcustom codcut-token nil
  "Codcut access token."
  :type '(string)
  :group 'codcut)

(defconst codcut-post-endpoint
  "https://resource.codcut.com/api/posts")

(defconst codcut-post-format-string
  "https://codcut.com/posts/%d")

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

(defun get-language ()
  "Retrieve the code language for Codcut"
  (or (get-file-extension) (get-major-mode)))

(defun get-id-from-post (json-string)
  "Get the id from a post JSON string"
  (cdr (assoc 'id
              (json-read-from-string json-string))))

(defun generate-codcut-url (post-id)
  (format codcut-post-format-string post-id))

(defun make-post-request (code description language)
  "Make a new post request to Codcut getting the resulting post id"
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
    (let (status
          data
          headers)
      (with-current-buffer
          (url-retrieve-synchronously codcut-post-endpoint)
        (setq status url-http-response-status)
        (goto-char (point-min))
        (if (re-search-forward "^$" nil t)
            (setq headers (buffer-substring (point-min) (point))
                  data (buffer-substring (1+ (point)) (point-max)))
          (throw 'request-error (error "Something went wrong.")))
        (get-id-from-post data)))))

;;;###autoload
(defun share-to-codcut ()
  "Share the selected code to Codcut"
  (interactive)
  (let ((code (get-selected-text))
        (description (read-string "Enter a description (optional): "))
        (language (get-language)))
    (catch 'request-error
      (let ((post-id (make-post-request code description language)))
         (message (format "New shared code at %s"
                          (generate-codcut-url post-id)))))))
;;;###autoload
(defun share-to-codcut-redirect ()
  "Share the selected code to Codcut and open the browser to the new code"
  (interactive)
  (let ((code (get-selected-text))
        (description (read-string "Enter a description (optional): "))
        (language (get-language)))
    (catch 'request-error
      (let ((post-id (make-post-request code description language)))
        (browse-url (generate-codcut-url post-id))))))

;;; codcut-emacs.el ends here