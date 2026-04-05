#!/usr/bin/env bash
set -eu
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree is dirty after regeneration. Forgot to commit?"
    git diff --stat
    exit 1
fi
# Also check for untracked files that should be committed
if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "Untracked files found after regeneration:"
    git ls-files --others --exclude-standard
    exit 1
fi
