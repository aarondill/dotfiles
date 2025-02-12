#!/usr/bin/env bash
this_dir="$(dirname "$(readlink -f "$0")")"
root_dir="$(dirname "$this_dir")"
# Configure the ThinkPad's internal display
PROFILE=thinkpad-monitor
OUTPUT=eDP-1
MODE=1600x900
LOCKFILE=/tmp/.autorandr-lock # NOTE: This needs to be the same as ../block.d/00-thinkpad.sh

edid_py=$(
  cat <<EOF
import re; from sys import argv, stdout, exit; from binascii import hexlify; import subprocess;
def get_edid_for_output(connector: str) -> bytes:
    xrandr = subprocess.run(
        ["xrandr", "--props"],
        check=True,
        stdout=subprocess.PIPE,
    )
    lines = [b.decode("utf-8") for b in xrandr.stdout.split(b"\n")]
    for i, line in enumerate(lines):
        connector_match = re.match("^{} connected".format(connector), line)
        if not connector_match: continue
        for j in range(i + 1, len(lines)):
            edid_match = re.match(r"\s*EDID:", lines[j])
            if not edid_match: continue
            edid = ""
            for k in range(j + 1, len(lines)):
                if re.match(r"^\s*[0-9a-f]{32}$", lines[k]):
                    edid += lines[k].strip()
                elif edid:
                    return bytes.fromhex(edid)
edid = get_edid_for_output(argv[1]) or exit("Could not find an EDID for output")
stdout.buffer.write(hexlify(edid))
EOF
)
edp_edid=$(python -c "$edid_py" "$OUTPUT") || exit 0 # there's no eDP-1 on this machine
thinkpad_internal=$(cat "$root_dir/$PROFILE/setup" | awk -v out="$OUTPUT" '$1 == out { print $2 }')
[ "$edp_edid" = "$thinkpad_internal" ] || exit 0

current_mode=$(xrandr | awk -v out="$OUTPUT" '$1 == out { if ($3 == "primary") {print($4)} else {print($3)} }' | cut -d '+' -f 1)
[ "$current_mode" != "$MODE" ] || exit 0 # already in the right mode (don't do extra work on $PROFILE)

exec 4<>"$LOCKFILE"
flock -s 4
xrandr --output "$OUTPUT" --mode "$MODE"
sleep 1 # don't allow to be called for another 1 second
flock -u 4
