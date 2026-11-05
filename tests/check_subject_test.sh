#!/bin/sh
# Tests for scripts/check_subject.sh. Quiet when they pass.
# Most good subjects are real subjects from Mitchell Hashimoto's projects, the style we copy.
set -u

check="$(cd "$(dirname "$0")/.." && pwd)/scripts/check_subject.sh"
failed=0

good() { sh "$check" "$1" 2>/dev/null || { echo "FAIL  rejected: $1"; failed=1; }; }
bad()  { if sh "$check" "$1" 2>/dev/null; then echo "FAIL  accepted: $1"; failed=1; fi; }

good 'terminal: clear cursor pin garbage flag after resize'
good 'libghostty-vt: make GhosttyStyle a frozen 16-byte struct'
good 'libghostty-vt: INVALID=0 key enums'
good 'pkg/wuffs: give the tests their own module'
good 'provider/aws: bad AMI won'\''t block LC refresh [GH-1901]'
good 'ci: add a release workflow for libghostty-vt'
good 'Revert "git: sort branches by date"'
good "a: $(printf '%069d' 0)"

bad  ''
bad  'Make checks quiet when they pass'
bad  'Terminal: clear cursor pin'
bad  'terminal: Clear cursor pin'
bad  'terminal: A cursor fix'
bad  'terminal: clear cursor pin.'
bad  'terminal:clear cursor pin'
bad  'terminal:  clear cursor pin'
bad  'terminal: clear cursor pin '
bad  'terminal: '
bad  'build(deps): bump actions/checkout'
bad  "a: $(printf '%070d' 0)"

exit "$failed"
