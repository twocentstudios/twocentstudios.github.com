#!/bin/zsh
set -e

DATE=$(date +%Y-%m-%d)
DATETIME=$(date +%Y-%m-%d\ %H:%M:%S)

if [[ -z "$*" ]]; then
  echo "Please enter a post title"
  exit
fi
 
INPUT_POST_TITLE="${*}"
POST_TITLE="${*// /-}"
POST_TITLE="${POST_TITLE:l}"

echo -e "---\nlayout: post\ntitle: $INPUT_POST_TITLE\ndate: $DATETIME\n---\n" > _drafts/$DATE-$POST_TITLE.markdown
