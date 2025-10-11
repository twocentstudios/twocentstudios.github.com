#!/bin/zsh
set -e

DATE=$(date +%Y-%m-%d)
DATETIME=$(date +%Y-%m-%d\ %H:%M:%S)

if [[ -z "$*" ]]; then
  echo "Please enter a post title"
  exit 1
fi
 
INPUT_POST_TITLE="${*}"
POST_TITLE="${*// /-}"
POST_TITLE="${POST_TITLE:l}"

FILE_PATH="_drafts/$DATE-$POST_TITLE.markdown"
TITLE_ESCAPED="${INPUT_POST_TITLE//\"/\\\"}"

cat <<EOF > "$FILE_PATH"
---
layout: post
title: "$TITLE_ESCAPED"
date: $DATETIME
image:
tags:
---

EOF

echo "$FILE_PATH"
open "$FILE_PATH"
