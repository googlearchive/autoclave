#!/bin/bash

# Copyright (c) 2015 The Polymer Project Authors. All rights reserved.
# This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
# The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
# The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
# Code distributed by Google as part of the polymer project is also
# subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt

TMP=${TMP:-`mktemp -d -t 'autoclave'`}
KEEP=${KEEP:-}
VERSION=${VERSION:-}
EYESPY_CONFIG=${EYESPY_CONFIG:-"config.json"}
EYESPY_TOKEN=${EYESPY_TOKEN:-"token"}

[ -d ${TMP} ] || mkdir ${TMP}

mversion="$PWD/node_modules/.bin/mversion"
eyespy="$PWD/node_modules/.bin/eyespy"

if [ ! -x ${mversion} -o ! -x ${eyespy} ]; then
  echo "Install the node modules!"
  exit 1
fi

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
  ${mversion} "${curtag}" >/dev/null 2>&1
  # figure out which semver bit to bump
  local major
  local minor
  local op
  # $VERSION is explicit, so skip checking the history
  if [ -z ${VERSION} ]; then
    major=`git log ${curtag}..master -n 1 --oneline --grep "\[BREAKING\]"`
    minor=`git log ${curtag}..master -n 1 --oneline --grep "\[(MINOR BREAKING|FEATURE)\]"`
  fi
  if [ -n "${major}" ]; then
    op="major"
  elif [ -n "${minor}" ]; then
    op="minor"
  elif [ -n "${VERSION}" ]; then
    op="${VERSION}"
  else
    op="patch"
  fi
  local nexttag=`${mversion} ${op} | sed '1 s/^.*v/v/; 2,$d'`
  if [ -x .autoclave-build.sh ]; then
    if ! git diff --quiet; then
      [ -e bower.json ] && git add bower.json
      [ -e package.json ] && git add package.json
      git ci -m "prepare for release ${nexttag}"
      # git push
    fi
    ./.autoclave-build.sh
  else
    git add -u
  fi
  git ci -m "release ${nexttag}"
  git tag ${nexttag}
  # push
  popd
  popd
  cleanup
}

cleanup() {
  [ ${KEEP} ] && return
  [ -d ${TMP} ] && rm -rf ${TMP}/*
}

push() {
  git push --tags
}

# make Ctrl-C quit
trap "{ cleanup; exit 1; }" SIGINT SIGTERM

REPOS=($@)

if [ ${#REPOS[@]} = 0 ]; then
  REPOS=(`${eyespy} -t ${EYESPY_TOKEN} -c ${EYESPY_CONFIG}`)
fi

for repo in ${REPOS[@]}; do
  process ${repo}
done
