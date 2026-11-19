FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git imagemagick ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json ./
COPY src ./src
COPY scripts ./scripts
COPY skills ./skills

RUN mkdir -p /data/maitian /data/projects /data/chrome-profile
ENV NODE_ENV=production \
    CDP_URL=http://chrome-unified:9222 \
    CHROME_PROFILE=/data/chrome-profile \
    MAITIAN_ROOT=/data/maitian

CMD ["node", "src/hub.mjs", "web"]
