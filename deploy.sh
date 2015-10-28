#!/bin/bash

DATE=`date +%Y-%m-%d:%H:%M:%S`
 
jekyll build && \
  cd _site && \
  git add . && \
  git commit -am $DATE && \
  git push origin master && \
  cd .. && \
  echo "Successfully built and pushed to GitHub at " $DATE