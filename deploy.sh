#!/bin/bash
set -e

DATE=`date +%Y-%m-%d:%H:%M:%S`
 
bundle exec jekyll build && \
  cd _site && \
  git add . && \
  git commit -am $DATE && \
  git push origin master && \
  cd .. && \
  echo "Successfully built and pushed to GitHub at " $DATE
