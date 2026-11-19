#!/bin/sh
set -e
DISPLAY_NUM=${DISPLAY_NUM:-99}
rm -f "/tmp/.X${DISPLAY_NUM}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM}"
exec /usr/local/bin/maitian-chrome-entrypoint "$@"
