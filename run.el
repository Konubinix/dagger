;; [[file:TECHNICAL.org::*Run configuration][Run configuration:1]]
;;; run.el --- Batch-execute org-babel bash blocks -*- lexical-binding: t; -*-

(defun dagger-run-ignore-cache ()
  "Override :cache to \"no\" so all blocks re-execute."
  (setq org-babel-default-header-args
        (cons '(:cache . "no")
              (assq-delete-all :cache org-babel-default-header-args))))

(defun dagger-run-file (orgfile)
  "Execute bash blocks in ORGFILE."
  (find-file orgfile)
  (org-babel-map-src-blocks nil
    (when (string= lang "bash")
      (message "%s Executing %s %s..." (format-time-string "%H:%M:%S") lang
               (or (org-element-property :name (org-element-at-point)) "(unnamed)"))
      (org-babel-execute-src-block)))
  (save-buffer)
  (kill-buffer))

(defun dagger-init-file (orgfile)
  "Execute init bash blocks (those with :init yes) in ORGFILE."
  (find-file orgfile)
  (org-babel-map-src-blocks nil
    (let* ((info (org-babel-get-src-block-info t))
           (params (nth 2 info)))
      (when (and (string= lang "bash")
                 (assq :init params))
        (message "%s Init %s..." (format-time-string "%H:%M:%S")
                 (or (org-element-property :name (org-element-at-point)) "(unnamed)"))
        (org-babel-execute-src-block))))
  (save-buffer)
  (kill-buffer))

;;; run.el ends here
;; Run configuration:1 ends here
