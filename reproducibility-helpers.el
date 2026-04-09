;; [[file:TECHNICAL.org::*Reproducibility helpers][Reproducibility helpers:1]]
;;; reproducibility-helpers.el --- Post-tangle hooks and fixtureyaml language

(defun fixtureyaml--call-generator (yaml-body root)
  "Call generate_tests.py with YAML-BODY, return output.
Also writes the spec file when a name is present."
  (let ((script (expand-file-name "tests/generate_tests.py" root)))
    (string-trim
     (shell-command-to-string
      (format "echo %s | python3 %s %s"
              (shell-quote-argument yaml-body)
              (shell-quote-argument script)
              (shell-quote-argument root))))))

(defun org-babel-execute:fixtureyaml (body params)
  "Generate drawer content from a fixtureyaml block (no execution)."
  (let* ((info (org-babel-get-src-block-info t))
         (name (nth 4 info))
         (root (expand-file-name
                (locate-dominating-file default-directory ".git")))
         (augmented (concat body "\nname: " name "\n")))
    (fixtureyaml--call-generator augmented root)))

;; :cache yes skips execution when the block hasn't changed.
;; :results drawer wraps the output so org can replace it cleanly.
;; :exports results shows only the CLI + result on export, hiding the YAML.
(setq org-babel-default-header-args:fixtureyaml
      '((:cache . "yes")
        (:results . "drawer")
        (:exports . "results")))

;;; reproducibility-helpers.el ends here
;; Reproducibility helpers:1 ends here
