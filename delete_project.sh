#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root."
    exit 1
fi

LOGFILE="/var/log/delete_project.log"
exec > >(tee -a "$LOGFILE") 2>&1

validate_project_name() {
    [[ "$1" =~ ^[a-zA-Z0-9._-]+$ ]] || {
        echo "Invalid project name."
        exit 1
    }
}

read -p "Enter project name to delete: " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty."
    exit 1
fi

validate_project_name "$PROJECT_NAME"

SERVICE_FILE="/etc/systemd/system/$PROJECT_NAME.service"
PROJECT_DIR="/projects/$PROJECT_NAME"
SUDOERS_FILE="/etc/sudoers.d/$PROJECT_NAME"

if systemctl is-enabled "$PROJECT_NAME.service" &>/dev/null; then
    systemctl disable --now "$PROJECT_NAME.service"
fi

if [ -f "$SERVICE_FILE" ]; then
    rm "$SERVICE_FILE"
fi

systemctl daemon-reload

if id -u "$PROJECT_NAME" &>/dev/null; then
    userdel -r "$PROJECT_NAME"
fi

if [ -d "$PROJECT_DIR" ]; then
    rm -rf "$PROJECT_DIR"
fi

if [ -f "$SUDOERS_FILE" ]; then
    rm "$SUDOERS_FILE"
fi

echo "Project $PROJECT_NAME removed."
