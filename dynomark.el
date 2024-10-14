;;; dynomark.el --- Package to use dynomark within markdown files -*- lexical-binding: t -*-

;; Author: K_Lar
;; Version: 0.1
;; Keywords: markdown, cli
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; This package scans markdown files for fenced code blocks marked
;; `dynomark`, queries the external CLI tool `dynomark` with their content,
;; and displays the results as virtual text (via overlays) covering the query.

;;; Code:

(defvar dynomark--overlays nil
  "List of active overlays created by dynomark.")

(defun dynomark--extract-code-blocks ()
  "Extract all fenced code blocks marked with `dynomark`."
  (let (code-blocks)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "```dynomark" nil t)
        (let ((start (point))
              (end (when (re-search-forward "```" nil t)
                     (match-beginning 0))))
          (when end
            (let ((block-content (buffer-substring-no-properties start end)))
              (push (list start end block-content) code-blocks))))))
    code-blocks))

(defun dynomark--run-cli (query)
  "Run the dynomark CLI with the given QUERY and return the result."
  (shell-command-to-string (format "dynomark --query '%s'" query)))

(defun dynomark--create-overlay (start end content)
  "Create an overlay from START to END and display CONTENT as virtual text over the code block."
  (let ((ov (make-overlay start end)))
    ;; Replace the code block content with the dynomark result
    (overlay-put ov 'display (concat "\n" content))
    ;; Apply markdown-mode syntax highlighting to the overlay content
    (with-temp-buffer
      (insert content)
      ;; Set the buffer to markdown mode to enable font-lock
      (markdown-mode)
      ;; Apply font-lock (syntax highlighting) to the region
      (font-lock-fontify-region (point-min) (point-max))
      ;; Now copy the text properties from the temp buffer to the overlay
      (let ((formatted-content (buffer-substring (point-min) (point-max))))
        (overlay-put ov 'display (concat "\n" formatted-content))))
    ;; Store the overlay in the list
    (push ov dynomark--overlays)
    ov))

(defun dynomark--clear-overlays ()
  "Clear all active overlays created by dynomark."
  (when dynomark--overlays
    (dolist (ov dynomark--overlays)
      (delete-overlay ov))
    (setq dynomark--overlays nil)))

(defun dynomark-process-blocks ()
  "Find `dynomark` fenced code blocks, run `dynomark` CLI, and overlay the results on top of the query."
  (interactive)
  (dynomark--clear-overlays)  ;; Clear any existing overlays before re-creating them
  (let ((code-blocks (dynomark--extract-code-blocks)))
    (dolist (block code-blocks)
      (let* ((start (nth 0 block))  ;; Start of the block content
             (end (nth 1 block))    ;; End of the block content
             (content (nth 2 block)) ;; The code block query text
             (result (dynomark--run-cli content))) ;; Query the dynomark CLI
        ;; Create an overlay that covers the query text with the result
        (dynomark--create-overlay start end result)))))

(defun dynomark-insert-results ()
  "Process the current buffer and insert results for all `dynomark` blocks."
  (interactive)
  (when (eq major-mode 'markdown-mode)
    (dynomark-process-blocks)))

;;;###autoload
(defun dynomark-toggle ()
  "Toggle the visibility of dynomark overlays."
  (interactive)
  (if dynomark--overlays
      (dynomark--clear-overlays)  ;; Remove overlays if they exist
    (dynomark-process-blocks)))   ;; Recreate overlays if none exist

;;;###autoload
(defun dynomark-compile-in-new-buffer ()
  "Evaluate all `dynomark` blocks in the current file, replace them with the result, and put the final content in a new buffer."
  (interactive)
  (let ((new-buffer (generate-new-buffer "*dynomark-output*" ))
        (content (buffer-substring-no-properties (point-min) (point-max))))
    (with-current-buffer new-buffer
      (insert content)  ;; Copy original content to new buffer
      (markdown-mode)  ;; Activate markdown-mode in new buffer
      (goto-char (point-min))
      ;; Replace all `dynomark` blocks with their evaluated results
      (while (re-search-forward "```dynomark\\(\\(.\\|\n\\)*?\\)```" nil t)
        (let* ((block-start (match-beginning 0))
               (block-end (match-end 0))
               (query (match-string 1))  ;; Extract the dynomark query
               (result (dynomark--run-cli query)))  ;; Get dynomark result
          ;; Replace the entire fenced block with the dynomark result
          (delete-region block-start block-end)
          (goto-char block-start)
          (insert result)))
      ;; Switch to the new buffer with results
      (pop-to-buffer new-buffer))))

;; Example keybinding:
;; (define-key markdown-mode-map (kbd "C-c d") 'dynomark-insert-results)
;; (define-key markdown-mode-map (kbd "C-c t") 'dynomark-toggle-overlays)

(provide 'dynomark)

;;; dynomark.el ends here
