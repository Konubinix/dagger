;; [[file:TECHNICAL.org::*Export config (Emacs Lisp)][Export config (Emacs Lisp):1]]
;;; export-html.el --- ox-html configuration for publishing -*- lexical-binding: t; -*-

(require 'ox-html)
(require 'htmlize)

;; Class-tagged spans so our <style> block below drives colors.
(setq org-html-htmlize-output-type 'css)

;; Rewrite file:foo.org links to foo.html so cross-page navigation
;; works on the published site.
(setq org-html-link-org-files-as-html t)

;; Don't treat "_" and "^" as subscript/superscript in prose — we
;; have plenty of identifiers like =.with_exec= and =DOCKER_HOST=
;; that would otherwise render as =.with<sub>exec</sub>=.  Explicit
;; =_{foo}= / =^{foo}= still work if anyone ever needs them.
(setq org-export-with-sub-superscripts '{})

;; water.css replaces the default prose theme; drop the built-in one.
(setq org-html-head-include-default-style nil)
(setq org-html-head-include-scripts nil)

(defun daggerlib--water-css ()
  "Return the contents of the water.css bundle in =.tangle-deps/=.
The file is fetched by =export-html-host.sh= before Emacs runs; the
exact filename encodes the pinned version and variant, so we glob
for =water-*.min.css= rather than hard-coding that here."
  (let* ((root (file-name-directory (or load-file-name buffer-file-name)))
         (hits (file-expand-wildcards
                (expand-file-name ".tangle-deps/water-*.min.css" root))))
    (unless hits
      (error "water.css missing in .tangle-deps/ (did export-html-host.sh fetch it?)"))
    (with-temp-buffer
      (insert-file-contents (car hits))
      (buffer-string))))

(defconst daggerlib--syntax-css "
.org-keyword,.org-builtin,.org-preprocessor{color:#d2a8ff}
.org-string{color:#a5d6ff}
.org-comment,.org-comment-delimiter,.org-doc{color:#8b949e;font-style:italic}
.org-function-name{color:#79c0ff}
.org-type,.org-constant{color:#ffa657}
.org-variable-name{color:#ff7b72}")

(setq org-html-head
      (concat "<style>"
              (daggerlib--water-css)
              daggerlib--syntax-css
              "</style>"))

;; "← Home" breadcrumb pointing back to the root readme.  Rendered
;; as a preamble so every page (except the home page itself) shows
;; a way back.  The href is computed relative to the page being
;; exported so deployment sub-paths (e.g. /daggerlib/) don't matter.
(defun daggerlib--home-preamble (info)
  (let* ((src (expand-file-name (plist-get info :input-file)))
         (root (locate-dominating-file src "dagger.json"))
         (root-readme (expand-file-name "readme.org" root))
         (src-dir (file-name-directory src))
         (rel (file-relative-name
               (expand-file-name "index.html" root) src-dir)))
    (if (file-equal-p src root-readme)
        ""
      (format "<nav><a href=\"%s\">← Home</a></nav>" rel))))

(setq org-html-preamble #'daggerlib--home-preamble)

(defun daggerlib/export-file (orgfile)
  "Export ORGFILE to HTML next to it (ox-html writes alongside the source)."
  (find-file orgfile)
  (org-html-export-to-html)
  (kill-buffer))

(provide 'export-html)
;;; export-html.el ends here
;; Export config (Emacs Lisp):1 ends here
