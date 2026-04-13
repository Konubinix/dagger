#!/usr/bin/env bash
# Bootstrap the project tooling from a fresh clone.
# Idempotent — safe to run at any point.
#
# Steps:
#   1. Clone pinned org-mode (if needed)
#   2. Tangle TECHNICAL.org and tests/testing.org
#      → produces tangle.el, run.el, tangle.sh, test-host.sh, etc.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- 1. Pinned org-mode ---------------------------------------------------

ORG_PIN=$(cat "$SCRIPT_DIR/.org-pin")
ORG_DIR="$SCRIPT_DIR/.tangle-deps/org"

if [ -d "$ORG_DIR" ] && [ "$(git -C "$ORG_DIR" rev-parse HEAD 2>/dev/null)" != "$ORG_PIN" ]; then
    echo "Org-mode pin changed, re-cloning..."
    rm -rf "$ORG_DIR"
fi

if [ ! -d "$ORG_DIR" ]; then
    echo "Cloning pinned org-mode ($ORG_PIN)..."
    mkdir -p "$SCRIPT_DIR/.tangle-deps"
    git clone --quiet https://git.savannah.gnu.org/git/emacs/org-mode.git "$ORG_DIR"
    git -C "$ORG_DIR" checkout --quiet "$ORG_PIN"
    emacs --batch --no-init-file \
        --eval "(progn
                  (push \"$ORG_DIR/lisp\" load-path)
                  (require 'autoload)
                  (setq generated-autoload-file \"$ORG_DIR/lisp/org-loaddefs.el\")
                  (update-directory-autoloads \"$ORG_DIR/lisp\"))" 2>/dev/null
    ORG_GIT_VERSION=$(git -C "$ORG_DIR" describe --tags --match "release_*" 2>/dev/null || echo "N/A")
    ORG_RELEASE=$(echo "$ORG_GIT_VERSION" | sed 's/^release_//;s/-.*//')
    (cd "$ORG_DIR/lisp" && emacs --batch --no-init-file \
        --eval "(progn
                  (push \"$ORG_DIR/lisp\" load-path)
                  (load \"$ORG_DIR/mk/org-fixup.el\")
                  (org-make-org-version \"$ORG_RELEASE\"
                                        \"$ORG_GIT_VERSION\"))") 2>/dev/null || true
fi

# --- 2. Tangle tooling ----------------------------------------------------

tangle_file() {
    local orgfile="$1"
    echo "Tangling $orgfile..."
    local raw_output tangled_list rc=0
    raw_output=$(emacs --batch --no-init-file \
        --eval "(progn
                  (push \"$ORG_DIR/lisp\" load-path)
                  (require 'org)
                  (require 'ob-shell)
                  (require 'ob-python)
                  (add-to-list 'org-src-lang-modes '(\"nix\" . conf))
                  (setq org-confirm-babel-evaluate nil)
                  (find-file \"$orgfile\")
                  (let ((files (org-babel-tangle)))
                    (dolist (f files) (princ (format \"%s\n\" f))))
                  (kill-buffer))" 2>&1) || rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "ERROR: emacs tangle failed (exit $rc):" >&2
        echo "$raw_output" >&2
        return "$rc"
    fi
    tangled_list=$(echo "$raw_output" | grep -E '^/' || true)
    for f in $tangled_list; do
        [ -f "$f" ] || continue
        sed -i 's/[[:space:]]*$//' "$f"
        case "$f" in
            *.py) ruff format --quiet "$f" 2>/dev/null || true ;;
        esac
    done
}

for f in "$SCRIPT_DIR"/TECHNICAL.org "$SCRIPT_DIR"/tests/testing.org; do
    [ -f "$f" ] && tangle_file "$f"
done
