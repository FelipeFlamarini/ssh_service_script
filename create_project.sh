#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root."
    exit 1
fi

LOGFILE="/var/log/create_project.log"
exec > >(tee -a "$LOGFILE") 2>&1

validate_project_name() {
    [[ "$1" =~ ^[a-zA-Z0-9._-]+$ ]] || {
        echo "Invalid project name."
        exit 1
    }
}

generate_password() {
    tr -dc 'A-Za-z0-9!@#$%^&*()_+' </dev/urandom | head -c 12
}

read -p "Enter project name: " PROJECT_NAME
validate_project_name "$PROJECT_NAME"

PROJECT_DIR="/projects/$PROJECT_NAME"

if id -u "$PROJECT_NAME" >/dev/null 2>&1; then
    echo "Error: User $PROJECT_NAME already exists."
    exit 1
fi

if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Directory $PROJECT_DIR already exists."
    exit 1
fi

read -p "Enter start command: " START_COMMAND
read -p "Enter stop command: " STOP_COMMAND

PASSWORD=$(generate_password)

useradd -m -d "$PROJECT_DIR" -s /bin/bash "$PROJECT_NAME"
echo "$PROJECT_NAME:$PASSWORD" | chpasswd
chown -R "$PROJECT_NAME":"$PROJECT_NAME" "$PROJECT_DIR"

SERVICE_FILE="/etc/systemd/system/$PROJECT_NAME.service"
cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=$PROJECT_NAME service

[Service]
ExecStart=$START_COMMAND
ExecStop=$STOP_COMMAND
User=$PROJECT_NAME
WorkingDirectory=$PROJECT_DIR

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo "$PROJECT_NAME ALL=(ALL) NOPASSWD: /bin/systemctl start $PROJECT_NAME.service, /bin/systemctl stop $PROJECT_NAME.service, /bin/systemctl disable $PROJECT_NAME.service, /bin/systemctl enable $PROJECT_NAME.service" >/etc/sudoers.d/"$PROJECT_NAME"

echo "Project $PROJECT_NAME created."
echo "Directory: $PROJECT_DIR"
echo "User: $PROJECT_NAME"
echo "Password: $PASSWORD"
echo "Service: $PROJECT_NAME.service"
