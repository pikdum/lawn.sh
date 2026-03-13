#!/usr/bin/env bash
set -euo pipefail

launcher="$1"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export HOME="$tmpdir/home"
export XDG_CONFIG_HOME="$HOME/.config"

set +e
"$launcher" list > "$tmpdir/empty.out" 2> "$tmpdir/empty.err"
status=$?
set -e

test "$status" -eq 1
test -f "$XDG_CONFIG_HOME/lawn.sh/config"
grep -F "No search roots configured yet." "$tmpdir/empty.err" >/dev/null
grep -F "$XDG_CONFIG_HOME/lawn.sh/config" "$tmpdir/empty.err" >/dev/null

mkdir -p \
  "$XDG_CONFIG_HOME/lawn.sh" \
  "$tmpdir/roots/library/Awesome Game" \
  "$tmpdir/roots/arcade/Awesome Game" \
  "$tmpdir/roots/misc/Oddity"

cat > "$XDG_CONFIG_HOME/lawn.sh/config" <<EOF
# comment lines are ignored
$tmpdir/roots

EOF

cat > "$tmpdir/roots/library/Awesome Game/.lawnrc" <<'EOF'
printf '%s\n' "$PWD" > launched-from.txt
printf 'library' > launch.log
EOF

cat > "$tmpdir/roots/arcade/Awesome Game/.lawnrc" <<'EOF'
printf 'arcade' > launch.log
EOF

cat > "$tmpdir/roots/misc/Oddity/.lawnrc" <<'EOF'
printf 'oddity' > launch.log
EOF

"$launcher" list > "$tmpdir/list.txt"

grep -F "Awesome Game  [$tmpdir/roots/arcade/Awesome Game]" "$tmpdir/list.txt" >/dev/null
grep -F "Awesome Game  [$tmpdir/roots/library/Awesome Game]" "$tmpdir/list.txt" >/dev/null
grep -F "Oddity" "$tmpdir/list.txt" >/dev/null
grep -F "$tmpdir/roots/library/Awesome Game/.lawnrc" "$tmpdir/list.txt" >/dev/null

"$launcher" run "$tmpdir/roots/library/Awesome Game/.lawnrc"

grep -Fx "$tmpdir/roots/library/Awesome Game" "$tmpdir/roots/library/Awesome Game/launched-from.txt" >/dev/null
grep -Fx "library" "$tmpdir/roots/library/Awesome Game/launch.log" >/dev/null
