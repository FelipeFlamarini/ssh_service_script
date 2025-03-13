#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: this script must be run as root."
  exit 1
fi

# Installing Docker Engine (docker-ce) using the official Docker documentation
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

# Updating repositories
sudo apt-get update

# Add Docker's official GPG key:
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

# Installing Docker Engine and extras
sudo apt-get install -y uidmap docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo systemctl disable --now docker.service
sudo systemctl disable --now docker.socket

# Installing and running openssh-server for ssh support
sudo apt-get install -y openssh-server
sudo systemctl enable --now ssh

# Installing systemd-container for machinectl
sudo apt-get install -y systemd-container
