#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$(realpath "$0")")"

[[ -n "$(git status --porcelain)" ]] && { echo "$0: dirty tree"; exit 1; }

git checkout main
git pull --ff-only

nix develop --command racket build.rkt

git add -A

if git diff --cached --quiet; then
  echo "$0: no changes"
  exit 0
fi

git commit -m "chore: automated daily bump ($(date -I))"
git push
