#!/bin/bash
set -e
cd "$(dirname "$0")/.."
if [ ! -f .env ]; then cp .env.example .env; fi
if [ ! -f config.json ]; then cp config.docker.example.json config.json; fi
mkdir -p projects
echo "Edit config.json and .env before first login."
docker compose pull || true
docker compose build
docker compose up -d chrome-unified
echo "Chrome noVNC: http://192.168.123.11:6080"
