;; [[file:TECHNICAL.org::*Reproducibility helpers][Reproducibility helpers:1]]
;;; reproducibility-helpers.el --- Tangle helpers for test commands

(defun daggerlib-tangle-test (name)
  "Return the tangle path for test command NAME."
  (expand-file-name (concat "tests/commands/" name)
                    (locate-dominating-file default-directory ".git")))

(defun daggerlib-tangle-expected (name)
  "Return the tangle path for expected output NAME."
  (expand-file-name (concat "tests/expected/" name)
                    (locate-dominating-file default-directory ".git")))

;;; reproducibility-helpers.el ends here
;; Reproducibility helpers:1 ends here
