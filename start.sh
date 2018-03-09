#!/usr/bin/env bash
export FILE_STORAGE_PORT=3001
export BACKEND_PORT=3000
export VISUALIZER_PORT=8080
export BACKEND_BASE_IMAGE_URL="http://$(hostname -i):${FILE_STORAGE_PORT}"
docker stack deploy -c docker-compose.yml 12-factor-app-example