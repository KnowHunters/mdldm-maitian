FROM ubuntu:24.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl xz-utils xvfb x11vnc novnc websockify fluxbox procps lsof \
 && ARCH="$(dpkg --print-architecture)" \
 && NODE_VERSION=v22.23.5 \
 && curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${ARCH}.tar.xz" -o /tmp/node.tar.xz \
 && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
 && rm -f /tmp/node.tar.xz \
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
