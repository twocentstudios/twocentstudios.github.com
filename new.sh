#!/bin/bash
set -e
 
DATE=`date +%Y-%m-%d`
DATETIME=`date +%Y-%m-%d\ %H:%M:%S`

if [[ -z "$*" ]]; then
  echo "Please enter a post title"
  exit
fi
 
echo -e "---\nlayout: post\ntitle:" "$*""\ndate: "$DATETIME"\n---\n" > _posts/$DATE-"$*".markdown
