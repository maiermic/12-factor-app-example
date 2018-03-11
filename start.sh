#!/usr/bin/env bash
export HOST_IP=$(ip route get 1 | awk '{print $NF;exit}')
export BACKEND_PORT=3000
export FILE_STORAGE_PORT=3001
export FRONTEND_PORT=3002
export BACKEND_BASE_IMAGE_URL="http://${HOST_IP}:${FILE_STORAGE_PORT}"
export BACKEND_URL="http://${HOST_IP}:${BACKEND_PORT}"
docker stack deploy -c docker-compose.yml 12-factor-app-example