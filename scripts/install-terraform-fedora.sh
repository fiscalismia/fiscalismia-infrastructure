#!/bin/bash

# Define ANSI color codes
CYAN='\e[36m'
NC='\e[0m' # No Color (reset)

# The -s (silent) option prevents the password from being displayed on the screen.
# The -r (raw) option prevents backslashes from acting as escape characters.
read -r -s -p "Enter your sudo password for installation: " SUDO_PWD
echo && echo

echo -e "${CYAN}################### TERRAFORM INSTALLATION ####################${NC}"
echo "$SUDO_PWD" | sudo -S dnf install -y dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf -y install terraform