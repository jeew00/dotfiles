#!/bin/sh
# Tests for the Claude Code scripts in claude/. Each OS runs them, so CI tests the OS paths.
set -u

# shellcheck source=tests/clean_env.sh
. "$(dirname "$0")/clean_env.sh"

repo=$(cd "$(dirname "$0")/.." && pwd)
failed=0
tmp=$(mktemp -d)
out="$tmp/out"
ok()   { echo "ok    $1"; }
fail() { echo "FAIL  $1"; sed 's/^/      /' "$out"; failed=1; }
esc=$(printf '\033')

# 1. The status line shows each value. The reset times are local time: use UTC.
#    1767225600 is Thu 01 Jan 2026 00:00 UTC. macOS has BSD date: -r, not -d.
if command -v jq >/dev/null; then
  status() { printf '%s' "$1" | TZ=UTC0 sh "$repo/claude/statusline.sh" >"$out" 2>&1; }
  status '{"model":{"display_name":"Opus"},"effort":{"level":"high"},
    "context_window":{"used_percentage":42.7,"context_window_size":200000},
    "rate_limits":{"five_hour":{"used_percentage":55,"resets_at":1767225600},
                   "seven_day":{"used_percentage":85.2,"resets_at":1767225600}}}'
  text=$(sed "s/$esc\[[0-9;]*m//g" "$out")
  want='Opus (high) | ctx 42% of 200k | 5h 55% ↻ 00:00 | week 85% ↻ Thu 01 Jan 00:00'
  if [ "$text" = "$want" ]; then ok "status line text"; else echo "want: $want" >>"$out"; fail "status line text"; fi
  if grep -q "$esc\[32m42%" "$out" && grep -q "$esc\[33m55%" "$out" && grep -q "$esc\[31m85%" "$out"; then
    ok "status line colors: green, yellow, red"
  else
    fail "status line colors: green, yellow, red"
  fi
  status '{"context_window":{"context_window_size":1000000}}'
  if [ "$(sed "s/$esc\[[0-9;]*m//g" "$out")" = '? | ctx 0% of 1M' ]; then ok "status line with few values"; else fail "status line with few values"; fi
else
  echo "skip  status line (jq is not installed)"
fi

# 2. The notification hook exits 0 and writes nothing when the OS has no sound player.
#    A fake uname selects the OS. PATH has no player, so no sound plays in the test.
mkdir "$tmp/bin"
# The fake uname reads FAKE_UNAME when it runs, not now.
# shellcheck disable=SC2016
printf '#!/bin/sh\necho "$FAKE_UNAME"\n' > "$tmp/bin/uname"
chmod +x "$tmp/bin/uname"
sh_path=$(command -v sh)
for os in MINGW64_NT-10.0 Darwin Linux; do
  # On Linux, it rings the terminal bell. With a terminal, the test cannot stop that: skip it.
  if [ "$os" = Linux ] && (: >/dev/tty) 2>/dev/null; then
    echo "skip  notify on $os (a terminal is open: the bell would ring)"
    continue
  fi
  if FAKE_UNAME=$os PATH="$tmp/bin" "$sh_path" "$repo/claude/notify.sh" </dev/null >"$out" 2>&1 && [ ! -s "$out" ]; then
    ok "notify on $os without a player"
  else
    fail "notify on $os without a player"
  fi
done

rm -rf "$tmp"
exit $failed
