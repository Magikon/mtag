# mtag

Github action to automatically tag by a commit message or default bump. The tag can also be computed from all messages from the commits history.

[![Build Status](https://github.com/Magikon/mtag/workflows/Bump%20version/badge.svg)](https://github.com/Magikon/mtag/workflows/Bump%20version/badge.svg)
[![Stable Version](https://img.shields.io/github/v/tag/Magikon/mtag)](https://img.shields.io/github/v/tag/Magikon/mtag)
[![Latest Release](https://img.shields.io/github/v/release/Magikon/mtag?color=%233D9970)](https://img.shields.io/github/v/release/Magikon/mtag?color=%233D9970)

### Usage

```Shell
name: Bump version
on:
  push:
    branches:
      - main
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@main
      with:
        fetch-depth: '0'

    - name: Colculate and push tag
      id: tag
      uses: Magikon/mtag@main
      env:
        INITIAL_VERSION: 0.0.0
        WITH_V: true
        RELEASE_BRANCHES: none
        MAJOR: "BREAKING*CHANGE|*#major*"
        MINOR: "*feat*|*#minor*"
        PATCH: "*fix*|*chore*|*docs*|*update*|*#patch*"
        FORCE: true
        OVERWRITE: true
        NOMERGES: true
...
or
...
    - name: Colculate and push tag
      id: tag
      uses: Magikon/mtag@beta
      env:
         INITIAL_VERSION: 0.0.0
         TAG_CONTEXT: branch
         PREFIX: "beta"
         MAJOR: "BREAKING*CHANGE|*#major*"
         MINOR: "*feat*|*#minor*"
         PATCH: "*fix*|*chore*|*docs*|*update*"
         OVERWRITE: true
         NOMERGES: true
         DEFAULT_BUMP: minor
```

_NOTE: set the fetch-depth for `actions/checkout@v2` to be sure you retrieve all commits to look for the semver commit message._

#### Options

**Environment Variables**

- **DEFAULT_BUMP** _(optional)_ - Which type of bump to use when none explicitly provided (default: `not set`). You can use MAJOR, MINOR or PATCH. Don't use with FORCE.
- **WITH_V** _(optional)_ - Tag version with `v` character. Default `false`
- **RELEASE_BRANCHES** _(optional)_ - Comma separated list of branches that will generate the release tags. Default `master,main`
- **CUSTOM_TAG** _(optional)_ - Set a custom tag, useful when generating tag based on f.ex FROM image in a docker image. **Setting this tag will invalidate any other settings set!**
- **DRY_RUN** _(optional)_ - Determine the next version without tag the branch. The workflow can use the outputs `new_tag` and `tag` in subsequent steps. Possible values are `true` and `false` (default `false`).
- **INITIAL_VERSION** _(optional)_ - Set initial version before bump. Default `0.0.0`.
- **TAG_CONTEXT** _(optional)_ - Set the context of the previous tag. Possible values are `repo` (default) or `branch`.
- **SUFFIX** _(optional)_ - Suffix for your prerelease versions, `prerelease` by default. Note this will only be used if a prerelease branch.
- **FORCE** _(optional)_ - Forces to read all commits messages and compute the tag. Possible values are `true` and (default) `false`.
- **MAJOR** _(optional)_ - Major changes from commits ex. `"BREAKING*CHANGE|*#major*"`
- **MINOR** _(optional)_ - Minor changes from commits ex. `"*feat*|*#minor*"`
- **PATCH** _(optional)_ - Patch changes from commits ex. `"*fix*|*chore*|*docs*|*update*|#patch"`
- **PREFIX** _(optional)_ - Prefix tag if used TAG_CONTEXT=branch. Ex. `dev-v0.2.4`
- **OVERWRITE** _(optional)_ - Overwrite tag with this commit. Default `false`
- **NOMERGES** _(optional)_ - Not included in the calculation merges. Using flag --no-merges. Default `true`

#### Outputs

- **new_tag** - The value of the newly created tag.
- **tag** - The value of the latest tag after running this action.
- **part** - The part of version which was bumped.
- **oldhash** - Print last tag commit SHA
- **newhash** - Print current tag commit SHA

With oldhash and newhash you can find out if the content of the folder has changed during the last tag and new tag or not.
```Shell
- name: Get changed files in apps/migrations/ folder
  id: changed
  run: |
    test=$(git diff ${{ steps.tag.outputs.oldhash }} ${{ steps.tag.outputs.newhash }} --stat -- apps/migrations/ | wc -l)
    (( $test )) && echo "::set-output name=any_changed::true || echo "::set-output name=any_changed::false
    echo If there are changes in the folder, then the test variable is greater than zero. Current test=$test

- name: Run a step if any files have changed in the apps/migrations/ folder
  if: ${{ contains(steps.changed.outputs.any_changed, 'true') }}
  run: |
        ...
```
> **_Note:_** This action creates a [lightweight tag](https://developer.github.com/v3/git/refs/#create-a-reference).

### Workflow

- Add this action to your repo
- Commit some changes
- Either push to master or open a PR
- On push (or merge), the action will:
  - Get latest tag
  - Bump tag with minor version unless any commit message contains `#major` or `#patch`
  - Pushes tag to github
  - If triggered on your repo's default branch (`master` or `main` if unchanged), the bump version will be a release tag.
  - If triggered on any other branch, a prerelease will be generated, depending on the bump, starting with `*-<PRERELEASE_SUFFIX>.1`, `*-<PRERELEASE_SUFFIX>.2`, ...

### Credits

[fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)
[anothrNick/github-tag-action](https://github.com/anothrNick/github-tag-action)



  > Access JSON structure with HTTP path parameters as keys/indices to the JSON.
