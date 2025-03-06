#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root."
    exit 1
fi

validate_project_name() {
    [[ "$1" =~ ^[a-zA-Z0-9._-]+$ ]] || {
        echo "Invalid project name."
        exit 1
    }
}

generate_password() {
    tr -dc 'A-Za-z0-9!@#$%^&*()_+' </dev/urandom | head -c 12
}

ALL_PROJECTS_DIR="/etc/projects"
mkdir -p "$ALL_PROJECTS_DIR"

LOGFILE="/var/log/create_project.log"
exec > >(tee -a "$LOGFILE") 2>&1

read -p "Enter project name: " PROJECT_NAME
validate_project_name "$PROJECT_NAME"

HOME="$ALL_PROJECTS_DIR/$PROJECT_NAME"

if id -u "$PROJECT_NAME" >/dev/null 2>&1; then
    echo "Error: User $PROJECT_NAME already exists."
    exit 1
fi

if [ -d "$HOME" ]; then
    echo "Error: Directory $HOME already exists."
    exit 1
fi

read -p "Do you need a Docker instance? [y/N] " NEEDS_DOCKER

read -p "Enter start command: " START_COMMAND
read -p "Enter stop command: " STOP_COMMAND

PASSWORD=$(generate_password)

useradd -m -d "$HOME" -s /bin/bash "$PROJECT_NAME"
echo "$PROJECT_NAME:$PASSWORD" | chpasswd
chown -R "$PROJECT_NAME":"$PROJECT_NAME" "$HOME"

if [ "$NEEDS_DOCKER" == "y" ]; then
    if [ -f /usr/bin/dockerd-rootless-setuptool.sh ]; then
        su - "$PROJECT_NAME" -c "/usr/bin/dockerd-rootless-setuptool.sh install"
    fi
    su - "$PROJECT_NAME" -c "systemctl enable --user --now docker.socket"
    su - "$PROJECT_NAME" -c "systemctl enable --user --now docker.service"
fi

SERVICE_DIR="$HOME/.config/systemd/user"
mkdir -p "$SERVICE_DIR"
SERVICE_FILE="$SERVICE_DIR/$PROJECT_NAME.service"
cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=$PROJECT_NAME service

[Service]
ExecStart=$START_COMMAND
ExecStop=$STOP_COMMAND
User=$PROJECT_NAME
WorkingDirectory=$HOME

[Install]
WantedBy=default.target
EOF

loginctl enable-linger "$PROJECT_NAME"
su - "$PROJECT_NAME" -c "systemctl --user daemon-reload"
su - "$PROJECT_NAME" -c "systemctl --user enable $PROJECT_NAME.service"

echo "Project $PROJECT_NAME created."
echo "Directory: $HOME"
echo "User: $PROJECT_NAME"
echo "Password: $PASSWORD"
echo "Service: $PROJECT_NAME.service"
