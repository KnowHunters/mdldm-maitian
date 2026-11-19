FROM node:22-bookworm-slim

ENV PLAYWRITER_TELEMETRY=0

RUN npm install -g playwriter@0.12.0

EXPOSE 19988

CMD ["playwriter", "serve", "--host", "0.0.0.0"]
