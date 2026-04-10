#!/usr/bin/env bash
# [[file:TECHNICAL.org::*Init examples][Init examples:1]]
# Initialize example dagger modules.
# Usage:
#   ./init-examples.sh                       # init all examples
#   ./init-examples.sh --no-cache            # ignore cached results
#   ./init-examples.sh examples/foo/readme.org  # init a specific example
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

NO_CACHE=
if [ "${1:-}" = "--no-cache" ]; then
    NO_CACHE=1
    shift
fi

# Ensure pinned org-mode is cloned and up-to-date
ORG_PIN="1025e3b49a98f175b124dbccd774918360fe7e11"
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
    # Generate org-loaddefs.el and org-version.el (needed for org to load properly)
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

init_file() {
    local orgfile="$1"
    echo "Init $orgfile..."
    local raw_output rc=0 no_cache_eval=""
    if [ -n "$NO_CACHE" ]; then
        no_cache_eval="(dagger-run-ignore-cache)"
    fi
    raw_output=$(emacs --batch --no-init-file \
        -l "$SCRIPT_DIR/tangle.el" \
        -l "$SCRIPT_DIR/run.el" \
        --eval "(progn $no_cache_eval (dagger-init-file \"$orgfile\"))" 2>&1) || rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "ERROR: init failed (exit $rc):" >&2
        echo "$raw_output" >&2
        return "$rc"
    fi
}

if [ $# -eq 0 ]; then
    for f in "$SCRIPT_DIR"/examples/*/readme.org; do
        [ -f "$f" ] && init_file "$f"
    done
else
    for f in "$@"; do
        test -f "$(realpath "$f")"
        init_file "$(realpath "$f")"
    done
fi
# Init examples:1 ends here
