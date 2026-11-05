#!/bin/sh
# Claude Code status line: model | effort | context % | 5h usage + reset | weekly usage + reset
# POSIX sh, so the shared settings.json works in Git Bash, macOS and Linux. Needs jq.

input=$(cat)
get() { printf '%s' "$input" | jq -j "$1 // empty"; }

esc=$(printf '\033')
dim="${esc}[2m"
rst="${esc}[0m"

# Color a percentage: green < 50, yellow < 80, red otherwise
pct() {
  p=${1%.*}
  c=32
  [ "$p" -ge 50 ] && c=33
  [ "$p" -ge 80 ] && c=31
  printf '%s[%sm%s%%%s' "$esc" "$c" "$p" "$rst"
}

# Format an epoch time: GNU date (Linux, Git Bash) has -d, BSD date (macOS) has -r
when() { date -d "@$1" "$2" 2>/dev/null || date -r "$1" "$2"; }

model=$(get '.model.display_name')
effort=$(get '.effort.level')
ctx=$(get '.context_window.used_percentage')
ctx_size=$(get '.context_window.context_window_size')
h5=$(get '.rate_limits.five_hour.used_percentage')
h5_reset=$(get '.rate_limits.five_hour.resets_at')
wk=$(get '.rate_limits.seven_day.used_percentage')
wk_reset=$(get '.rate_limits.seven_day.resets_at')

out="${esc}[1;36m${model:-?}${rst}"
[ -n "$effort" ] && out="$out ${dim}(${effort})${rst}"
out="$out | ctx $(pct "${ctx:-0}")"
if [ -n "$ctx_size" ]; then
  if [ "$ctx_size" -ge 1000000 ]; then size="$((ctx_size / 1000000))M"; else size="$((ctx_size / 1000))k"; fi
  out="$out ${dim}of ${size}${rst}"
fi
if [ -n "$h5" ]; then
  out="$out | 5h $(pct "$h5")"
  [ -n "$h5_reset" ] && out="$out ${dim}↻ $(when "$h5_reset" +%H:%M)${rst}"
fi
if [ -n "$wk" ]; then
  out="$out | week $(pct "$wk")"
  [ -n "$wk_reset" ] && out="$out ${dim}↻ $(when "$wk_reset" '+%a %d %b %H:%M')${rst}"
fi

printf '%s' "$out"
