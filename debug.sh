#!/usr/bin/env bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export DAGGER_PATH="$(which dagger)"
export PATH="$SCRIPT_DIR/tests:$PATH"

timeout 5 emacs --batch --no-init-file \
  -l "$SCRIPT_DIR/tangle.el" \
  -l "$SCRIPT_DIR/run.el" \
  --eval "(progn
    (find-file \"$SCRIPT_DIR/doc/pip_tools.org\")
    (org-babel-map-src-blocks nil
      (let ((name (org-element-property :name (org-element-at-point))))
        (when (and (string= lang \"bash\") name)
          (message \"Executing %s...\" name)
          (org-babel-execute-src-block))))
    (message \"BUFFER: %s\" (buffer-string))
    (kill-buffer))"
echo "EXIT: $?"
