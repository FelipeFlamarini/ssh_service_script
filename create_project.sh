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

useradd -m -d "$HOME" -s /bin/bash "$PROJECT_NAME"
echo "$PROJECT_NAME:$PASSWORD" | chpasswd
chown -R "$PROJECT_NAME":"$PROJECT_NAME" "$HOME"

if [ "$NEEDS_DOCKER" == "y" ]; then
    if [ -f /usr/bin/dockerd-rootless-setuptool.sh ]; then
        su - "$PROJECT_NAME" -c "/usr/bin/dockerd-rootless-setuptool.sh install"
    fi
    su - "$PROJECT_NAME" -c "systemctl enable --user --now docker.socket"
    su - "$PROJECT_NAME" -c "systemctl enable --user --now docker.service"

    cat <<EOF >"$HOME/.bashrc"
    export DOCKER_HOST=unix:///run/user/\$(id -u)/docker.sock
EOF
fi

SERVICE_DIR="$HOME/.config/systemd/user"
mkdir -p "$SERVICE_DIR"
SERVICE_FILE="$SERVICE_DIR/$PROJECT_NAME.service"
cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=$PROJECT_NAME service
EOF

if [ "$NEEDS_DOCKER" == "y" ]; then
    echo "After=docker.service" >>"$SERVICE_FILE"
fi

cat <<EOF >"$SERVICE_FILE"
[Service]
ExecStart=$START_COMMAND
ExecStop=$STOP_COMMAND
User=$PROJECT_NAME
WorkingDirectory=$HOME

[Install]
WantedBy=default.target
EOF

cat <<EOF >"$HOME/.bashrc"
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$(id -u $PROJECT_NAME)/bus
export XDG_RUNTIME_DIR=/run/user/\$(id -u $PROJECT_NAME)
EOF

loginctl enable-linger "$PROJECT_NAME"

chown -R "$PROJECT_NAME" "$HOME"

echo "Project $PROJECT_NAME created."
echo "Directory: $HOME"
echo "User: $PROJECT_NAME"
echo "Password: $PASSWORD"
echo "Service: $PROJECT_NAME.service"
