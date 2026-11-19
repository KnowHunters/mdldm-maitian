FROM ubuntu:24.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl wget gnupg xvfb x11vnc novnc websockify fluxbox procps lsof \
 && wget -qO /usr/share/keyrings/nodesource.gpg https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
 && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb \
 && apt-get install -y --no-install-recommends /tmp/chrome.deb \
 && rm -f /tmp/chrome.deb \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --create-home --shell /bin/bash chrome \
 && mkdir -p /chrome-profile /extensions

COPY entrypoint.sh /usr/local/bin/maitian-chrome-entrypoint
RUN chmod +x /usr/local/bin/maitian-chrome-entrypoint

ENV DISPLAY=:99 \
    CHROME_BIN=/usr/bin/google-chrome

EXPOSE 3000 6080 9222 19988
ENTRYPOINT ["/usr/local/bin/maitian-chrome-entrypoint"]
