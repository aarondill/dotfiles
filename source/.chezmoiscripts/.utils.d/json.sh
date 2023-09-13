#!/usr/bin/env bash
# ==> github.sh <==
assert_source_once "${BASH_SOURCE[0]}" || return 0
if true; then
  . ./output.sh  # err log
  . ./flow.sh    # abort
  . ../.utils.sh # assert_source_once
fi

## --------------------------------------------------------------------------------------------------
## ---------------------------------------------- JSON ----------------------------------------------
## --------------------------------------------------------------------------------------------------

# private function for get_json_prop
function _get_json_prop_node() {
  local script node
  script=$(
    cat <<-EOF
async function read(stream) {
  const chunks = [];
  for await (const chunk of stream) chunks.push(chunk);
  return Buffer.concat(chunks).toString("utf8");
}
(async function main() {
  const props = process.argv.slice(1); // 1 bc -e
  if (!props) return 2;
  let v = JSON.parse(await read(process.stdin));
  for (let i = 0; i < props.length; i++) {
    if (!v || typeof v != "object") return 3;
    const p = props[i];
    v = v[p];
    if (v === undefined) return 1;
  }
  if (typeof v == "object") v = JSON.stringify(v);
  console.log(v);
})().then((c) => (process.exitCode = c ?? 0));
EOF
  )
  if has_cmd nodejs; then
    node=nodejs
  elif has_cmd node; then
    node=node
  fi
  "$node" -e "$script" "$@"
}
# private function for get_json_prop
function _get_json_prop_python3() {
  local script
  script=$(
    cat <<-EOF
import sys
import json
j = json.load(sys.stdin)
for k in sys.argv[1:]:
    if j is None:
        sys.exit(3)
    if isinstance(j, dict):
        k not in j and sys.exit(1)
    elif isinstance(j, list):
        int(k) >= len(j) and sys.exit(1)
    else:
        sys.exit(3)
    j = j[int(k)]

if isinstance(j, dict) or isinstance(j, list):
    j = json.dumps(j)
print(j)

EOF
  )
  python3 -c "$script" "$@"
}
# private function for get_json_prop
function _get_json_prop_jq() {
  local p="try ."
  local s
  for s in "$@"; do
    p="${p}[\"$s\"]" # jq only takes one argument, but you can index each result
  done
  jq -rc "$p"
}
# private function for get_json_prop
function _get_json_prop_fx() {
  args=()
  for s in "$@"; do
    args+=(".[\"$s\"]") # fx takes multiple arguments, each builds on the last
  done
  fx "${args[@]}" 'x??""' # if undef, return empty string not "null"
}

# usage get_json_prop <prop>
# if prop doesn't exist, exit with error
# Objects should be json encoded, otherwise, just output the value.
# Strings should NOT have quotes.
function get_json_prop() {
  case $(first_cmd "jq" "fx" "python3" "node" "nodejs") in
  jq) _get_json_prop_jq "$@" ;;              # JQ implementation
  fx) _get_json_prop_fx "$@" ;;              # FX implementation
  python3) _get_json_prop_python3 "$@" ;;    # PYTHON3 implementation
  node | nodejs) _get_json_prop_node "$@" ;; # NODE implementation
  *) abort "BUG!" 3 ;;
  esac
}
