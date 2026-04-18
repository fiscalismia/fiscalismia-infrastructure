#!/usr/bin/env bash

set -euo pipefail

dnf install -y --quiet podman podman-docker
dnf install -y --quiet dnf-plugins-core
dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
dnf install -y --quiet docker-compose-plugin # docker compose V2
systemctl enable --now podman.socket

if ! systemctl is-active --quiet podman.socket; then
    echo "ERROR: podman.socket failed to start" >&2
    exit 1
fi

# disable docker BuildKit (not supported by Podman)
echo "export DOCKER_BUILDKIT=0" >> ~/.bashrc
export DOCKER_BUILDKIT=0
#docker compose plugin looks for DOCKER_HOST to find the container runtime socket
echo 'export DOCKER_HOST=unix:///run/podman/podman.sock' >> ~/.bashrc
# echo "export DOCKER_HOST=unix:///run/user/$UID/docker.sock" >> ~/.bashrc
export DOCKER_HOST=unix:///run/podman/podman.sock

echo "##### PODMAN INSTALLATION #####"
podman --version
docker --version
docker compose --version
podman run alpine cat /etc/os-release