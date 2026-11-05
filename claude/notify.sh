#!/bin/sh
# Claude Code Notification hook: play a sound when Claude waits for me.
# One script for each OS, so the shared settings.json works on each machine.
case $(uname -s) in
  MINGW* | MSYS* | CYGWIN*)
    powershell.exe -NoProfile -Command \
      "(New-Object Media.SoundPlayer 'C:\Windows\Media\Windows Notify System Generic.wav').PlaySync()" ;;
  Darwin)
    afplay /System/Library/Sounds/Glass.aiff ;;
  *)
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null ||
      printf '\a' >/dev/tty ;;
esac
