#!/bin/bash

set -eou pipefail

sudo dnf install -y podman podman-docker
sudo dnf install -y dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-compose-plugin # docker compose V2
docker compose -v
sudo systemctl --user start podman.socket
sudo systemctl --user enable --now podman.socket

# disable docker buildkit for rootless podman
echo "export DOCKER_BUILDKIT=0" >> ~/.bashrc
echo "export DOCKER_HOST=unix:///run/user/$UID/docker.sock" >> ~/.bashrc