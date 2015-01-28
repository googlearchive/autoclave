# Autoclave
> Automated release tool for Polymer repositories

## Usage
Autoclave can be given a series of Github repos in `$ORG/$REPO` form, or use
[eyespy](https://github.com/PolymerLabs/eyespy) to automatically query for repos
that need to be released.

### Example:

- Build one repo
```sh
./autoclave.sh Polymer/polymer
```
- Build all repos
```sh
./autoclave.sh
```
  - This mode requires an eyespy config

## Options

All options to autoclave use environment variables

### Variables:

- TMP
  - Temprorary folder for repositories to be held in
  - Default: output of `mktemp -d -t 'autoclave'`
- KEEP
  - Keep the contents of the temporary folder between runs
  - Default: NO, repos will be cleared after each successful release
- VERSION
  - Force all repositories to use given version
  - Default: NONE, repos will rev independently
- EYESPY_CONFIG
  - Path to a config for eyespy
  - Default: `./config.json`
- EYESPY_TOKEN
  - Path to a githb token file for eyespy
  - Default: `./token`
- DRYRUN
  - If set to true, do not push commits, just tag them
  - Default: FALSE, push release commits and tags

One Repository: 
```sh
TMP=tmp KEEP=1 VERSION="1.0.0" DRYRUN=1 ./autoclave.sh Polymer/polymer
```

All repositories:
```sh
TMP=tmp KEEP=1 VERSION="1.0.0" DRYRUN=1 EYESPY_CONFIG="~/autoclave_config.json" EYESPY_TOKEN="~/.secret-github-token" ./autoclave.sh
```

## Custom Releases

If a repository needs custom handling for releases a shell script named
`.autoclave-build.sh` can be added to the top level of the repository, and it
will be executed before the repository is tagged and pushed.

This script must have a clean tree with a staged commit at the end of running.

### Example:

```sh
#!/usr/bin/env bash
RELEASE=(foobuild.min.js)
npm install
gulp build-for-release
git add -f --ignore-errors ${RELEASE[@]}
```

[Polymer's autoclave build script](https://raw.githubusercontent.com/Polymer/polymer/master/.autoclave-build.sh)

## Release Policy

Autoclave uses [mversion](https://www.npmjs.com/package/mversion) to update
`package.json` and `bower.json` files to the same version number.

By default, all releases will bump the semver `PATCH` version.

If any commit messages since the last release include `[MINOR BREAKING]` or
`[FEATURE]`, a semver `MINOR` release will be made.

If any commit messages since the last release include `[BREAKING]`, a semver `MAJOR`
release will be made.

If the `VERSION` environment variable is set, that version will be used
regardless of git history.
