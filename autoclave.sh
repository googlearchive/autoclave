#!/bin/bash

# Copyright (c) 2015 The Polymer Project Authors. All rights reserved.
# This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
# The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
# The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
# Code distributed by Google as part of the polymer project is also
# subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt

set -e

TMP=${TMP:-`mktemp -d -t 'autoclave'`}

[ -d ${TMP} ] || mkdir ${TMP}

process() {
  local repo=${1}
  local dir=${repo##*[/\\]}
  pushd ${TMP}
  [ -d ${dir} ] || git clone "git://github.com/${repo}"
  pushd ${dir}
  git checkout master
  git pull
  git fetch --tags
  local curtag=$(git describe --tags `git rev-list --tags --max-count=1`)
  # ensure current tag is set
  mversion "${curtag}" >/dev/null 2>&1
  # figure out which semver bit to bump
  local major
  local minor
  major=`git log ${curtag}..master -n 1 --oneline --grep "\[BREAKING\]"`
  minor=`git log ${curtag}..master -n 1 --oneline --grep "\[(MINOR BREAKING|FEATURE)\]"`
  local op="patch"
  if [ -n "${major}" ]; then
    op="major"
  elif [ -n "${minor}" ]; then
    op="minor"
  fi
  local nexttag=`mversion ${op} | sed '1 s/^.*v/v/; 2,$d'`
  bower install --config.directory=..
  if [ -x build.sh ]; then
    ./build.sh
  else
    git add -u
  fi
  git ci -m "release ${nexttag}"
  git tag ${nexttag}
  popd
  # cleanup
}

cleanup() {
  [ -d ${TMP} ] && rm -rf ${TMP}/*
}

# trap "{ cleanup; exit 1; }" SIGINT SIGTERM

for repo in ${@}; do
  process ${repo}
done
