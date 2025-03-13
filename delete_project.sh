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

ALL_PROJECTS_DIR="/etc/projects"

read -p "Enter project name to delete: " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty."
    exit 1
fi

validate_project_name "$PROJECT_NAME"
HOME="$ALL_PROJECTS_DIR/$PROJECT_NAME"

SERVICE_FILE="$HOME/.config/systemd/user/$PROJECT_NAME.service"
PROJECT_DIR="/etc/projects/$PROJECT_NAME"

if systemctl is-active "$PROJECT_NAME.service" &>/dev/null; then
    su - "$PROJECT_NAME" -c "systemctl disable --now $PROJECT_NAME.service"
    rm "$SERVICE_FILE"
fi

if systemctl --user is-active docker.service &>/dev/null; then
    su - "$PROJECT_NAME" -c "systemctl --user disable --now docker.socket"
    su - "$PROJECT_NAME" -c "systemctl --user disable --now docker.service"
fi

loginctl disable-linger "$PROJECT_NAME"
systemctl daemon-reload

if id -u "$PROJECT_NAME" &>/dev/null; then
    userdel -r "$PROJECT_NAME"
fi

if [ -d "$PROJECT_DIR" ]; then
    rm -rf "$PROJECT_DIR"
fi

echo "Project $PROJECT_NAME removed."
