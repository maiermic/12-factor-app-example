#!/usr/bin/env bash
STACK=12-factor-app-example
SERVICE_NAME=database

# directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONTAINER_NAME="${STACK}_${SERVICE_NAME}"
CONTAINER_ID=$(docker service ps -f "name=${CONTAINER_NAME}.1" ${CONTAINER_NAME} -q)
CONTAINER="${CONTAINER_NAME}.1.${CONTAINER_ID}"

SCRIPT="$DIR/js/init-db.js"
cat ${SCRIPT} | docker exec -i ${CONTAINER} mongo admin --quiet