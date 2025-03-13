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

while true; do
    read -p "Do you need a Docker instance? [y/N] " NEEDS_DOCKER
    case "$NEEDS_DOCKER" in
    [yY] | [yY][sS] | "")
        NEEDS_DOCKER="y"
        break
        ;;
    [nN] | [nN][oO])
        NEEDS_DOCKER="N"
        break
        ;;
    *)
        echo "Invalid input. Please enter 'y' or 'N'."
        ;;
    esac
done

read -p "Enter start command: " START_COMMAND
read -p "Enter stop command: " STOP_COMMAND

PASSWORD=$(generate_password)
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/$PROJECT_NAME.service"
PROJECT_DIR="$HOME/project"

useradd -m -d "$HOME" -s /bin/bash "$PROJECT_NAME"
echo "$PROJECT_NAME:$PASSWORD" | chpasswd
mkdir -p "$SERVICE_DIR"
mkdir -p "$PROJECT_DIR"

if [ "$NEEDS_DOCKER" == "y" ]; then
    if [ -d /usr/bin/docker-rootless.sh ]; then
        sudo machinectl shell $PROJECT_NAME@ /bin/bash -c "/usr/bin/docker-rootless.sh install"
        sudo machinectl shell $PROJECT_NAME@ /bin/bash -c "systemctl --user enable docker.socket"
        sudo machinectl shell $PROJECT_NAME@ /bin/bash -c "systemctl --user enable --now docker.service"
    else
        echo "Error: docker-rootles.sh couldn't be found, check if docker-ce-rootless-extras is installed."
    fi
fi

cat <<EOF >>"$SERVICE_FILE"
[Unit]
Description=$PROJECT_NAME service
EOF

if [ "$NEEDS_DOCKER" == "y" ]; then
    echo "After=docker.service" >>"$SERVICE_FILE"
    echo "Wants=docker.service" >>"$SERVICE_FILE"
fi

cat <<EOF >>"$SERVICE_FILE"
[Service]
ExecStart=$START_COMMAND
ExecStop=$STOP_COMMAND
User=$PROJECT_NAME
WorkingDirectory=$PROJECT_DIR

[Install]
WantedBy=default.target
EOF

sudo machinectl shell $PROJECT_NAME@ /bin/bash -c "systemctl --user enable --now $PROJECT_NAME.service"

loginctl enable-linger "$PROJECT_NAME"
chown -R "$PROJECT_NAME" "$HOME"

echo "Project $PROJECT_NAME created."
echo "Directory: $HOME"
echo "User: $PROJECT_NAME"
echo "Password: $PASSWORD"
echo "Service: $PROJECT_NAME.service"
