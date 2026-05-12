#!/usr/bin/env bash
# shellcheck disable=SC2120 # Optional arguments shouldn't be an error
# a wrapper script for git aliases.
set -euC -o pipefail
log() { printf '%s\n' "$@"; }
err() { printf "%s\n" "$@" >&2; }
abort() {
  err "$1"
  exit "${2:-1}"
}
# Gets the remote name given a local branch (defaults to HEAD)
# returns non-zero if not found
get_remote() {
  local symbolic remote branch="${1:-HEAD}"
  symbolic="$(git rev-parse --symbolic-full-name "$branch")"
  remote=$(git for-each-ref --format='%(upstream:remotename)' -- "$symbolic")
  printf '%s\n' "$remote"
  [ -n "$remote" ] || return 1
}

# Gets the tracking remote branch for the given branch (defaults to HEAD)
# returns non-zero if not found
get_remote_branch() {
  local branch="${1:-HEAD}"
  git rev-parse --abbrev-ref --symbolic-full-name "$branch@{u}" 2>/dev/null
}
# usage: has_changes <branch1> <branch1>
has_changes() { [ -n "$(git cherry "$1" "$2")" ]; }

command= && if [ -n "${1:-}" ]; then command="$1" && shift 1; fi
case "$command" in
shallowify)
  git pull --depth "${1:-1}" "${@:2}" # default to depth 1
  git gc --prune=all
  ;;
sha1) git rev-parse --short "${1:-HEAD}" ;; # default to HEAD
hdiff) git diff "HEAD~${1:-}" ;;            # default to HEAD~
mvbranch)
  [ "$#" -eq 2 ] || abort "usage: $command <from> <to>" 2
  origin=$(get_remote "$1") # note: both branches must use the same origin
  git branch -m "$1" "$2"
  git push "$origin" ":$1"
  git push --set-upstream "$origin" "$2"
  ;;
alias)
  [ "$#" -eq 2 ] || abort "usage: $command <alias> <definition>" 2
  git config --global "alias.$1" "$2"
  ;;
unalias)
  [ -n "${1:-}" ] || abort "usage: $command <alias>" 2
  git config --global --unset "alias.$1"
  ;;
yesterday) git hist --since "${1:-yesterday}" '--branches=*' --author="$(git config user.name)" ;;
time-between)
  use_seconds=false
  if [ "$1" = -s ]; then
    use_seconds=true
    shift 1
  fi
  s1=$(git log "$1" -n 1 --format=%at) s2=$(git log "${2:-HEAD}" -n 1 --format=%at)
  diff=$((s2 - s1))
  if [ "$diff" -lt 0 ]; then
    diff=$((-diff))
  fi
  if [ "$use_seconds" = true ]; then
    printf "%d\n" "$diff"
  elif command -v python3 &>/dev/null; then # (ab)use python to format the diff in seconds
    python3 -c 'import datetime; import sys; print(str(datetime.timedelta(seconds=int(sys.argv[1]))))' "$diff"
  else
    printf 'Install python3 to format the diff\n' >&2
    printf '%s seconds\n' "$diff"
  fi
  ;;
get-remote)
  get_remote_branch "${1:-HEAD}" || abort "No upstream branch found." 1
  ;;
diff-origin) # note: relies on the `git hist` alias.
  origin=${1:-$(get_remote_branch "HEAD")} || abort "No upstream branch found." 1
  # note: use [ -n git hist ] because is faster than git cherry. Git cherry has to fetch the diff from remote.
  if [ -n "$(git hist "HEAD..$origin")" ]; then
    log "Only Upstream:"
    git hist "HEAD..$origin"
  fi
  if [ -n "$(git hist "$origin..HEAD")" ]; then
    log "Only Local:"
    git hist "$origin..HEAD"
  fi
  ;;
sync-tags) # syncs tags with remote by removing local tags. Note: assumes remote as source of truth of tags.
  origin=$(get_remote) || abort "No upstream found" 1
  git fetch --prune "$origin" "+refs/tags/*:refs/tags/*"
  ;;
bisect-undo)
  git bisect log | head -n -2 >/tmp/fixed_bisect.log
  git bisect replay /tmp/fixed_bisect.log
  rm -f -- /tmp/fixed_bisect.log
  ;;
'') abort "usage: ${BASH_SOURCE[0]##*/} <command> [args]..." 2 ;;
*) abort "Unknown command: $command" 2 ;;
esac
