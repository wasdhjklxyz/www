#!/usr/bin/env bash

set -euo pipefail

ROOT="$(dirname "$(realpath "$0")")"
REPO="$(basename "$ROOT")"

cd "$ROOT"
[[ -n "$(git status --porcelain)" ]] && { echo "$REPO: dirty tree"; exit 1; }

git checkout main
git pull --ff-only

nix develop --command racket build.rkt

git add -A

if git diff --cached --quiet; then
  echo "$REPO: no changes"
  exit 0
fi

git commit -m "chore: automated daily bump ($(date -I))"
git push
