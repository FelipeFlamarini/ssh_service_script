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

    id "$1" &>/dev/null || {
        echo "User does not exist."
        exit 1
    }
}
ALL_PROJECTS_DIR="/etc/projects"
mkdir -p "$ALL_PROJECTS_DIR"

mkdir -p "$ALL_PROJECTS_DIR/logs"
LOGFILE="$ALL_PROJECTS_DIR/logs/delete_project.log"
touch $LOGFILE
exec >> >(tee -a $LOGFILE)
exec 2>&1
echo "" >>$LOGFILE

read -p "Enter project name to delete: " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty."
    exit 1
fi

echo "Warning: This will delete all files and the user associated with the project $PROJECT_NAME."
read -p "Are you sure you want to proceed? (y/N): " CONFIRMATION

if [[ ! "$CONFIRMATION" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

validate_project_name "$PROJECT_NAME"
HOME="$ALL_PROJECTS_DIR/$PROJECT_NAME"

SERVICE_FILE="$HOME/.config/systemd/user/$PROJECT_NAME.service"
PROJECT_DIR="/etc/projects/$PROJECT_NAME"

echo "Disabling lingering"
loginctl disable-linger $PROJECT_NAME
sleep 2

echo "Deleting user $PROJECT_NAME"
if id -u "$PROJECT_NAME" &>/dev/null; then
    userdel -r "$PROJECT_NAME"
fi

echo "Deleting project directory $PROJECT_DIR"
if [ -d "$PROJECT_DIR" ]; then
    rm -rf "$PROJECT_DIR"
fi

echo "Project $PROJECT_NAME removed."
