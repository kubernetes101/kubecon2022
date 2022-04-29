#!/bin/bash

# this runs each time the container starts

echo "post-start start"
echo "$(date +'%Y-%m-%d %H:%M:%S')    post-start start" >> "$HOME/status"

# update the base docker images
docker pull ghcr.io/kubernetes101/webv-red:latest
docker pull ghcr.io/kubernetes101/heartbeat:latest
docker pull ghcr.io/kubernetes101/imdb-app:latest
docker pull ghcr.io/kubernetes101/fluent-bit:1.5
docker pull ghcr.io/kubernetes101/grafana:8.1.1
docker pull ghcr.io/kubernetes101/prometheus:v2.29.1

echo "post-start complete"
echo "$(date +'%Y-%m-%d %H:%M:%S')    post-start complete" >> "$HOME/status"
