#!/bin/bash
set -e

PROFILE=/chrome-profile
DISPLAY_NUM=${DISPLAY_NUM:-99}
VNC_PORT=${VNC_PORT:-6900}
NOVNC_PORT=${NOVNC_PORT:-6080}
CDP_PORT=${CDP_PORT:-9222}

mkdir -p "$PROFILE" /tmp/.X11-unix
chown -R chrome:chrome "$PROFILE" /extensions 2>/dev/null || true
chmod -R a+rX /extensions 2>/dev/null || true
rm -f "$PROFILE/SingletonLock" "$PROFILE/SingletonCookie" "$PROFILE/SingletonSocket"
rm -f "/tmp/.X${DISPLAY_NUM}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM}"

if ! pgrep -f "Xvfb :${DISPLAY_NUM}" >/dev/null; then
  Xvfb ":${DISPLAY_NUM}" -screen 0 1600x1000x24 -nolisten tcp >/var/log/xvfb.log 2>&1 &
fi
export DISPLAY=":${DISPLAY_NUM}"
sleep 1

if [ ! -f "$PROFILE/First Run" ]; then touch "$PROFILE/First Run"; fi

CHROME_ARGS=(
  --user-data-dir="$PROFILE"
  --restore-last-session
  --no-first-run
  --no-default-browser-check
  --remote-debugging-address=0.0.0.0
  --remote-debugging-port="${CDP_PORT}"
  --window-size=1500,1000
  --disable-dev-shm-usage
  --no-sandbox
  --disable-setuid-sandbox
  --lang=zh-CN
)
if [ -n "${PLAYWRITER_EXTENSION_PATH:-}" ] && [ -d "${PLAYWRITER_EXTENSION_PATH}" ]; then
  CHROME_ARGS+=(--disable-extensions-except="${PLAYWRITER_EXTENSION_PATH}" --load-extension="${PLAYWRITER_EXTENSION_PATH}")
fi

start_chrome() {
  DISPLAY="${DISPLAY}" /usr/bin/google-chrome "${CHROME_ARGS[@]}" about:blank >>/var/log/chrome.log 2>&1 &
  CHROME_PID=$!
}

start_chrome

x11vnc -display "${DISPLAY}" -nopw -forever -shared -rfbport "${VNC_PORT}" >/var/log/x11vnc.log 2>&1 &
websockify --web=/usr/share/novnc "${NOVNC_PORT}" "localhost:${VNC_PORT}" >/var/log/websockify.log 2>&1 &

while true; do
  if ! kill -0 "$CHROME_PID" 2>/dev/null; then
    echo "$(date -Is) chrome exited, restarting" >>/var/log/chrome.log
    rm -f "$PROFILE/SingletonLock" "$PROFILE/SingletonCookie" "$PROFILE/SingletonSocket"
    sleep 2
    start_chrome
  fi
  sleep 5
done
