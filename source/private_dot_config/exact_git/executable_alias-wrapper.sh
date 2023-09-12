#!/usr/bin/env bash
# a wrapper script for git aliases.
set -euC -o pipefail
log() { printf '%s\n' "$@"; }
err() { printf "${THIS:+$THIS: }%s\n" "$@" >&2; }
abort() {
  err "$1"
  exit "${2:-1}"
}

command= && if [ -n "${1:-}" ]; then command="$1" && shift 1; fi
case "$command" in
shallowify)
  git pull --depth "${1:-1}" "${@:2}" # default to depth 1
  git gc --prune=all
  ;;
sha1) git rev-parse --short "${1:-HEAD}" ;; # default to HEAD
hdiff) git diff "HEAD~${1:-}" ;;            # default to HEAD~
mvbranch)
  if [ "$#" -lt 2 ]; then abort "usage: mvbranch <from> <to>" 2; fi
  git branch -m "$1" "$2"
  git push origin ":$1"
  git push --set-upstream origin "$2"
  ;;
alias)
  if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then abort 'usage: alias <alias> <definition>' 2; fi
  git config --global "alias.$1" "$2"
  ;;
unalias)
  if [ -z "${1:-}" ]; then abort "usage: unalias <alias>" 2; fi
  git config --global --unset "alias.$1"
  ;;
cleanup)
  err "Warning: this is a destructive operation."
  sleep 1 # give chance to stop
  git reflog expire --expire=now
  git repack -d
  git gc --prune=now --aggressive
  ;;
yesterday) git hist --since yesterday '--branches=*' --author="$(git config user.name)" ;;
diff-origin)
  origin="${1:-$(git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)")}"
  if [ -z "$origin" ]; then abort "No upstream branch found." 1; fi
  only_up=$(git hist --color=always "HEAD..$origin")
  only_local=$(git hist --color=always "$origin..HEAD")
  if [ -n "$only_up" ]; then
    log "Only Upstream:"
    log "$only_up"
  fi
  if [ -n "$only_local" ]; then
    log "Only Local:"
    log "$only_local"
  fi
  ;;
'') abort "usage: alias-wrapper.sh <command> [args]..." 2 ;;
*) THIS=alias-wrapper.sh abort "Unknown command '$command'" 2 ;;
esac
