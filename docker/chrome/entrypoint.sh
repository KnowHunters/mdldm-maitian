#!/bin/bash
set -e

PROFILE=/chrome-profile
DISPLAY_NUM=${DISPLAY_NUM:-99}
VNC_PORT=${VNC_PORT:-6900}
NOVNC_PORT=${NOVNC_PORT:-6080}
CDP_PORT=${CDP_PORT:-9222}
RELAY_PORT=${RELAY_PORT:-19988}

mkdir -p "$PROFILE" /tmp/.X11-unix
chown -R chrome:chrome "$PROFILE" /extensions 2>/dev/null || true

if ! pgrep -f "Xvfb :${DISPLAY_NUM}" >/dev/null; then
  Xvfb ":${DISPLAY_NUM}" -screen 0 1600x1000x24 -nolisten tcp >/var/log/xvfb.log 2>&1 &
fi
export DISPLAY=":${DISPLAY_NUM}"
sleep 1

if [ ! -f "$PROFILE/First Run" ]; then touch "$PROFILE/First Run"; fi

CHROME_ARGS=(
  --user-data-dir="$PROFILE"
  --no-first-run
  --no-default-browser-check
  --remote-debugging-address=0.0.0.0
  --remote-debugging-port="${CDP_PORT}"
  --window-size=1500,1000
  --disable-dev-shm-usage
  --lang=zh-CN
)
if [ -n "${PLAYWRITER_EXTENSION_PATH:-}" ] && [ -d "${PLAYWRITER_EXTENSION_PATH}" ]; then
  CHROME_ARGS+=(--disable-extensions-except="${PLAYWRITER_EXTENSION_PATH}" --load-extension="${PLAYWRITER_EXTENSION_PATH}")
fi

su chrome -s /bin/bash -c "DISPLAY='${DISPLAY}' '/usr/bin/google-chrome' $(printf '%q ' "${CHROME_ARGS[@]}") about:blank" >/var/log/chrome.log 2>&1 &

x11vnc -display "${DISPLAY}" -nopw -forever -shared -rfbport "${VNC_PORT}" >/var/log/x11vnc.log 2>&1 &
websockify --web=/usr/share/novnc "${NOVNC_PORT}" "localhost:${VNC_PORT}" >/var/log/websockify.log 2>&1 &

if command -v npx >/dev/null 2>&1; then
  PLAYWRITER_TOKEN="${PLAYWRITER_TOKEN:-maitian-local}" npx -y playwriter@latest serve --host 0.0.0.0 --port "${RELAY_PORT}" --token "${PLAYWRITER_TOKEN:-maitian-local}" >/var/log/playwriter.log 2>&1 &
fi

wait
