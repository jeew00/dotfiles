#!/bin/sh
# Source this at the start of a test script.
# The tests must not see the state of this machine. Env vars changed the results:
# GIT_DIR from a git hook (git init then changed the dotfiles repo), XDG_CONFIG_HOME
# (git and mise then read config outside the test HOME). Run again with an empty env.
# Keep only PATH, the temp folders, and the vars that Windows programs need.
if [ -z "${DOTFILES_TEST_CLEAN:-}" ]; then
  exec env -i DOTFILES_TEST_CLEAN=1 PATH="$PATH" \
    ${TMPDIR+"TMPDIR=$TMPDIR"} ${TEMP+"TEMP=$TEMP"} ${TMP+"TMP=$TMP"} \
    ${SYSTEMROOT+"SYSTEMROOT=$SYSTEMROOT"} ${WINDIR+"WINDIR=$WINDIR"} \
    sh "$0" "$@"
fi
