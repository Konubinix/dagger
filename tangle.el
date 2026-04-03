;; [[id:0474ada9-a621-4c1a-97aa-270cf96e32c4][Tangle configuration:1]]
;;; tangle.el --- Self-contained org-babel tangling for dagger lib -*- lexical-binding: t; -*-

;; Don't prompt for code block evaluation
(setq org-confirm-babel-evaluate nil)

;; Load pinned org-mode from .tangle-deps BEFORE anything else loads the
;; built-in org.  This must happen before (require 'ob-shell) since that
;; transitively loads org.
(let ((org-lisp-dir
       (expand-file-name ".tangle-deps/org/lisp"
                         (file-name-directory (or load-file-name buffer-file-name)))))
  (when (file-directory-p org-lisp-dir)
    (push org-lisp-dir load-path)
    (let ((contrib (expand-file-name "../contrib/lisp" org-lisp-dir)))
      (when (file-directory-p contrib)
        (push contrib load-path)))
    ;; Force load of pinned org (unload built-in if already loaded)
    (require 'org)))

;; Load babel languages needed for tangling
(require 'ob-shell)
(require 'ob-python)

;; Add link comments and blank lines between blocks in tangled output
(setq org-babel-default-header-args
      (cons '(:comments . "yes")
            (cons '(:padline . "yes")
                  (assq-delete-all :comments
                    (assq-delete-all :padline
                      org-babel-default-header-args)))))

;; Preserve indentation in Python blocks so that org-level indentation
;; does not interfere with Python's significant whitespace.
(add-to-list 'org-babel-default-header-args:python
             '(:preserve-indentation . t))

;; check-result support — transforms check-result(name) into shell test
;; functions during noweb expansion, comparing actual output against cached
;; #+RESULTS blocks.  Adapted from ~/prog/clk/tangle.el.

(unless (fboundp 'first) (defalias 'first #'car))
(unless (fboundp 'second) (defalias 'second #'cadr))

(defun dagger-tangle--get-cached-result (name)
  "Extract the #+RESULTS content for block NAME from the current org buffer.
Handles both `: value` and `#+begin_example...#+end_example` formats."
  (save-match-data
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward
           (format "^[ \t]*#\\+RESULTS\\[.*\\]:[ \t]+%s[ \t]*$" (regexp-quote name))
           nil t)
      (forward-line 1)
      (let ((start (point))
            (lines nil))
        (cond
         ;; #+begin_example block — include trailing newline to match org-babel behavior
         ((looking-at "^[ \t]*#\\+begin_example")
          (forward-line 1)
          (while (not (looking-at "^[ \t]*#\\+end_example"))
            (let ((line (buffer-substring-no-properties
                         (line-beginning-position) (line-end-position))))
              (push line lines))
            (forward-line 1))
          (concat (mapconcat #'identity (nreverse lines) "\n") "\n"))
         ;; : prefixed results
         (t
          (while (looking-at "^[ \t]*: \\(.*\\)$\\|^[ \t]*:$")
            (let ((line (or (match-string 1) "")))
              (push line lines))
            (forward-line 1))
          (mapconcat #'identity (nreverse lines) "\n"))))))))

(defun konix/org-babel-expand-noweb-references/add-check-result (orig-func info &optional parent-buffer context)
  (let ((code (second info)))
    (setq code
          (replace-regexp-in-string
           "^[ \t]*check-result(\\([a-zA-Z0-9_-]+\\))"
           (lambda (match)
             (let* ((name (match-string 1 match))
                    (result (dagger-tangle--get-cached-result name)))
               (concat
                "\n" name "_code () {\n"
                "      <<" name ">>\n"
                "}\n"
                "\n" name "_expected () {\n"
                "      cat<<\"EOEXPECTED\"\n"
                (or result "") "\n"
                "EOEXPECTED\n"
                "}\n"
                "\necho 'Run " name "'\n"
                "\n{ " name "_code || true ; } > \"${TMP}/code.txt\" 2>/dev/null\n"
                name "_expected > \"${TMP}/expected.txt\"\n"
                "diff -uBw \"${TMP}/code.txt\" \"${TMP}/expected.txt\" || {\n"
                "echo \"Something went wrong when trying " name "\"\n"
                "exit 1\n"
                "}\n")))
           code nil t))
    (funcall
     orig-func
     ;; info with the code replaced
     (cons (first info) (cons code (cddr info)))
     parent-buffer)))
(advice-add 'org-babel-expand-noweb-references :around 'konix/org-babel-expand-noweb-references/add-check-result)

;;; tangle.el ends here
;; Tangle configuration:1 ends here
