#!/bin/bash

set -o pipefail

cd ${GITHUB_WORKSPACE}/${source}

#add as safe /github/workspace directory
git config --global --add safe.directory /github/workspace

# read config
default_semvar_bump=${DEFAULT_BUMP:-""}
with_v=${WITH_V:-false}
release_branches=${RELEASE_BRANCHES:-master,main}
custom_tag=${CUSTOM_TAG}
prefix=${PREFIX:-""}
dryrun=${DRY_RUN:-false}
initial_version=${INITIAL_VERSION:-0.0.0}
tag_context=${TAG_CONTEXT:-repo}
suffix=${PRERELEASE_SUFFIX:-prerelease}
major=${MAJOR:-#major}
minor=${MINOR:-#minor}
patch=${PATCH:-#patch}
force=${FORCE:-false}
overwrite=${OVERWRITE:-false}
nomerges=${NOMERGES:-true}

# print configs
echo "*** CONFIGURATION ***"
echo -e "\tDEFAULT_BUMP: ${default_semvar_bump}"
echo -e "\tWITH_V: ${with_v}"
echo -e "\tRELEASE_BRANCHES: ${release_branches}"
echo -e "\tCUSTOM_TAG: ${custom_tag}"
echo -e "\tPREFIX: ${prefix}"
echo -e "\tDRY_RUN: ${dryrun}"
echo -e "\tINITIAL_VERSION: ${initial_version}"
echo -e "\tTAG_CONTEXT: ${tag_context}"
echo -e "\tPRERELEASE_SUFFIX: ${suffix}"
echo -e "\tMAJOR: ${major}"
echo -e "\tMINOR: ${minor}"
echo -e "\tPATCH: ${patch}"
echo -e "\tFORCE: ${force}"
echo -e "\tOVERWRITE: ${overwrite}"
echo -e "\tNOMERGES: ${nomerges}"

# read current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo $current_branch

pre_release="true"
IFS=',' read -ra branch <<< "$release_branches"

if [[ ! " ${branch[*]} " =~ " ${current_branch} " ]]; then
    pre_release="false"
fi
echo "pre_release = $pre_release"

# fetch tags
git fetch --tags

fmt="^($prefix-)?v?[0-9]+\.[0-9]+\.[0-9]+(-$suffix\.[0-9]+)?$"

# get latest tag that looks like a semver (with or without v)
case "$tag_context" in
    *repo*)
        lasttag="$(git describe --abbrev=0 --tags $(git rev-list --tags --max-count=1))"
        [ -z "$lasttag" ] || tag="$(semver -c $lasttag | tail -n 1)"
        [[ $pre_release ]] && [[ "$lasttag" =~ "$suffix" ]] && lastN="${lasttag##*.}"
        ;;
    *branch*)
        if [ -z "$prefix" ]
        then
           lasttag="$(git tag --list --sort=-v:refname | grep -E "$fmt" | head -n 1)"
        else
           lasttag="$(git tag --list --sort=-v:refname | grep -E "$fmt" | grep $prefix- | head -n 1)"
        fi
        [ -z "$lasttag" ] || tag="$(semver -c $lasttag | tail -n 1)"
        [[ $pre_release ]] && [[ "$lasttag" =~ "$suffix" ]] && lastN="${lasttag##*.}"
        ;;
    * ) echo "Unrecognised context"; exit 1;;
esac

echo "Last tag info ..."
echo -e "Found tag numeric... \t$tag"
echo -e "Found full tag ... \t$lasttag"
echo -e "If prerelease true last number \t$lastN"

# save previous tag
old=$tag

if [ -z "$tag" ]
then
    tag="$initial_version"
else
    # save tag hash
    oldtaghash=$(git rev-list -n 1 $lasttag)
fi
    
# new commit hash
commit=$(git rev-parse HEAD)

# output oldhash
echo ::set-output name=oldhash::$oldtaghash

# output newhash
echo ::set-output name=newhash::$commit

echo -e "Printing old tag hash \t$oldtaghash"
echo -e "Print new hash \t$commit"

shopt -s extglob;
if $force
then
  if $nomerges
  then
      IFS=$'\n' read -d '' -a array <<< $(git log --pretty=format:"%s" $current_branch --reverse --no-merges)
  else
      IFS=$'\n' read -d '' -a array <<< $(git log --pretty=format:"%s" $current_branch --reverse)
  fi
  tag="$initial_version"
  for i in "${array[@]}"
  do
    case "$i" in
      @($major) ) new=$(semver -i major $tag); part="major" ;;
      @($minor) ) new=$(semver -i minor $tag); part="minor" ;;
      @($patch) ) new=$(semver -i patch $tag); part="patch" ;;
      * ) [ -z "$default_semvar_bump" ] || new=$(semver -i "${default_semvar_bump}" $tag); part=$default_semvar_bump ;;
    esac
    [ ! -z "$new" ] && tag=$new
  done
  if [ "$old" == "$new" ]
  then
      echo ::set-output name=new_tag::$tag; echo ::set-output name=tag::$tag; 
	  [ $overwrite ] || exit 0
  fi
else
    if $nomerges
    then
        log=$(git log --pretty=format:"%s" $current_branch --no-merges | head -n 1)
    else
        log=$(git log --pretty=format:"%s" $current_branch | head -n 1)
    fi
  case "$log" in
    @($major) ) new=$(semver -i major $tag); part="major";;
    @($minor) ) new=$(semver -i minor $tag); part="minor";;
    @($patch) ) new=$(semver -i patch $tag); part="patch";;
    * )
        if [ -z "$default_semvar_bump" ] && [ -z "$custom_tag"]; then
            echo "Default bump was set to none. Skipping..."; echo ::set-output name=new_tag::$tag; echo ::set-output name=tag::$tag; 
			[ $overwrite ] || exit 0
        else
            new=$(semver -i "${default_semvar_bump}" $tag); part=$default_semvar_bump
        fi
        ;;
  esac
fi
shopt -u extglob;

[ -z "$new" ] && new=$tag
echo $part
echo -e "Bumping tag ${tag}. \tNew tag ${new}"
echo ::set-output name=tag::$new

# prefix with 'v'
if $with_v
then
    new="v$new"
fi

if [ ! -z $prefix ]
then
    new="$prefix-$new"
fi

if $pre_release
then
    # Already a prerelease available, bump it
    if [[ "$old" == *"$new"* ]] && [[ ! -z $lastN ]]; then
        lastN=$((lastN+1))
		new="$new-$suffix.$lastN"
    else
        new="$new-$suffix.0"
    fi
fi

if [ ! -z $custom_tag ]
then
    new="$custom_tag"
fi

# set outputs
echo ::set-output name=new_tag::$new
echo ::set-output name=part::$part

if $dryrun
then
    exit 0
fi

# create local git tag
echo "tagging local"
git tag -f $new
git describe --tags
# git tag $new
echo "push tag to remote"
git push -f origin $new

