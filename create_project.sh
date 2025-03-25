!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root."
    exit 1
fi

red='\e[91m' #Red
grn='\e[92m' #Green
blu='\e[94m' #Blue
DEF='\e[0m'  #Default color and effects

validate_project_name() {
    [[ "$1" =~ ^[a-zA-Z0-9._-]+$ ]] || {
        echo "Invalid project name."
        exit 1
    }
}

generate_password() {
    tr -dc 'A-Za-z0-9!@#$' </dev/urandom | head -c 12
}

ALL_PROJECTS_DIR="/etc/projects"
mkdir -p "$ALL_PROJECTS_DIR"

mkdir -p "$ALL_PROJECTS_DIR/logs"
LOGFILE="$ALL_PROJECTS_DIR/logs/create_project.log"
touch $LOGFILE
exec >> >(tee -a $LOGFILE)
exec 2>&1

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

useradd -m -d "$HOME" -s /bin/bash "$PROJECT_NAME"
echo "$PROJECT_NAME:$PASSWORD" | chpasswd
mkdir -p "$SERVICE_DIR"
mkdir -p "$PROJECT_DIR"
cp user/* $HOME
chown -R "$PROJECT_NAME" "$SERVICE_DIR"

echo "Creating project $PROJECT_NAME" | tee -a $LOGFILE
if [ "$NEEDS_DOCKER" == "y" ]; then
    printf "${blu}Installing Docker for $PROJECT_NAME...${DEF}\n" | tee -a $LOGFILE
    if [ -f /usr/bin/dockerd-rootless-setuptool.sh ]; then
        # for some reason, installing once doesn't work correctly
        sudo machinectl shell $PROJECT_NAME@ /bin/bash -c "dockerd-rootless-setuptool.sh install" >>$LOGFILE
        sudo machinectl shell $PROJECT_NAME@ /bin/bash -c "dockerd-rootless-setuptool.sh uninstall" >>$LOGFILE
        sudo machinectl shell $PROJECT_NAME@ /bin/bash -c "dockerd-rootless-setuptool.sh install" >>$LOGFILE
        echo "export PATH=/usr/bin:\$PATH" >>"$BASHRC_FILE"
        echo "export DOCKER_HOST=unix:///run/user/$(id -u $PROJECT_NAME)/docker.sock" >>"$BASHRC_FILE"
        printf "${grn}Docker installed.${DEF}\n" | tee -a $LOGFILE
    else
        echo "Error: dockerd-rootless-setuptool.sh couldn't be found, check if docker-ce-rootless-extras is installed." | tee -a $LOGFILE
    fi
fi

printf "${blu}Creating service file for $PROJECT_NAME...${DEF}\n" | tee -a $LOGFILE
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
WorkingDirectory=$PROJECT_DIR

[Install]
WantedBy=default.target
EOF

printf "${blu}Enabling $PROJECT_NAME service...${DEF}\n" | tee -a $LOGFILE
systemctl daemon-reload
sudo machinectl shell $PROJECT_NAME@ /bin/bash -c "systemctl --user enable --now $PROJECT_NAME.service" | tee -a $LOGFILE
loginctl enable-linger "$PROJECT_NAME"
chown -R "$PROJECT_NAME" "$HOME"

printf "${grn}Project $PROJECT_NAME created.${DEF}\n" | tee -a $LOGFILE
echo "Home directory: $HOME" | tee -a $LOGFILE
echo "User: $PROJECT_NAME" | tee -a $LOGFILE
echo "Password: $PASSWORD" | tee -a $LOGFILE
echo "Service file: $SERVICE_FILE" | tee -a $LOGFILE

