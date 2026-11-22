FROM ubuntu:24.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl wget xvfb x11vnc novnc websockify fluxbox procps lsof fonts-noto-cjk fonts-noto-color-emoji fonts-wqy-microhei \
 && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb \
 && apt-get install -y --no-install-recommends /tmp/chrome.deb \
 && rm -f /tmp/chrome.deb \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --create-home --shell /bin/bash chrome \
 && mkdir -p /chrome-profile /extensions

RUN mkdir -p /etc/opt/chrome/policies/managed \
 && printf '%s\n' '{"ExtensionInstallForcelist":["eaaipbilkhibicihiollecmbpneikpnj;https://clients2.google.com/service/update2/crx","hlkenndednhfkekhgcdicdfddnkalmdm;https://clients2.google.com/service/update2/crx","jfeammnjpkecdekppnclgkkffahnhfhe;https://clients2.google.com/service/update2/crx"]}' \
    > /etc/opt/chrome/policies/managed/extensions.json

COPY entrypoint.sh /usr/local/bin/maitian-chrome-entrypoint
COPY launch-wrapper.sh /usr/local/bin/maitian-chrome-launch
COPY extensions/cookie-editor /extensions/cookie-editor
RUN chmod +x /usr/local/bin/maitian-chrome-entrypoint /usr/local/bin/maitian-chrome-launch

ENV DISPLAY=:99 \
    CHROME_BIN=/usr/bin/google-chrome

EXPOSE 3000 6080 9222 19988
ENTRYPOINT ["/usr/local/bin/maitian-chrome-entrypoint"]
