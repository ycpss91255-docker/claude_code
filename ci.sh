#!/bin/bash

if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "Error: Docker Compose is not installed."
    exit 1
fi

export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

$DOCKER_COMPOSE -f "$(dirname "$0")/compose.yaml" run --rm ci
