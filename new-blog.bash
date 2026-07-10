#!/usr/bin/env bash

set -e

[[ $# -eq 0 ]] && { echo "Usage: $0 title..."; exit 1; }

WORKING_DIR="$(dirname "$(realpath "$0")")"
TITLE_KEBAB="$(sed 's/ /-/g;' <<< ${*,,})"
DATE_CONCAT="$(date '+%Y-%m-%d:%b, %-d %Y')"
MD_BASENAME="_index.md"

mkdir "$WORKING_DIR/blog/$TITLE_KEBAB"
cd $_

cat >> "$MD_BASENAME" << EOF
# $*
<time datetime="${DATE_CONCAT%%:*}">${DATE_CONCAT#*:}</time>

EOF

echo "$(realpath "$MD_BASENAME")"
