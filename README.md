# SSH Service Script

This repository contains scripts to create and delete project environments with systemd services and optional Docker support.

## Usage as an admin

### Prerequisites

These prerequisites suppose you are running a Ubuntu 24.04 installation. The scripts may work on other distributions, but the commands may differ.

- have a user with sudo privileges;
- have sshd installed and running (optional, needed for remote access);

For the Docker optional support:

- have Docker Engine and docker-ce-rootless-extras installed (must be installed following the instructions from the [official Docker documentation](https://docs.docker.com/engine/install/ubuntu/) using their `apt` repository);
- have `newuidmap` and `newgidmap` installed (provided by the `uidmap` package);

### Running the script "[create_project.sh](create_project.sh)"

This script must be ran as root. It creates a new project environment with the following features:

- Creates a new user and home directory for the project;
- Optionally sets up a Docker instance for the project;
- Creates a systemd user service for the project;
- Enables and starts the systemd user service;
- Lingers the user to ensure the service is always running, even when the user is not logged in.

Run the `create_project.sh` script and follow the prompts:

```sh
sudo ./create_project.sh
```

When done, the script will output the project user's information, including username and password.

### Running the script "[delete_project.sh](delete_project.sh)"

This script must be ran as root. It deletes an existing project environment by:

- Disabling and removing the systemd user service;
- Removing the Docker instance if it exists;
- Deleting the project user and all its data.

Run the `delete_project.sh` script and follow the prompts:

```sh
sudo ./delete_project.sh
```

### Storage

The projects' home directories are located in `/etc/projects`.

### Logs

Logs for the scripts are stored in:

- `/var/log/create_project.log`
- `/var/log/delete_project.log`

## Usage as a project user

### Logging into the project user

The admin will provide you with the project user's username, password and hostname. You can log in by having `ssh` installed and using the following command:

```sh
ssh {username}@{hostname}
```

A prompt will ask for the password. Enter the password provided and you will be logged in.

### Managing your project

The project user's home directory is located in `/etc/projects/{project}`, which will be the working directory when you log in. We recommend you create a new directory for your project files and work from there.

### Managing your user's service unit

The user service unit is created by the `create_project.sh` script and is named based on your project name, as in  `{project}.service`. It is located in the user's home systemd directory:

```sh
~/.config/systemd/user/{project}.service
```

The actions you can perform on the service are:

| Command | Description |
| --- | --- |
| `systemctl --user start {project}.service` | Start the service |
| `systemctl --user stop {project}.service` | Stop the service |
| `systemctl --user restart {project}.service` | Restart the service |
| `systemctl --user status {project}.service` | Show the service status |
| `systemctl --user enable {project}.service` | Enable the service to start on boot (enabled by default) |
| `systemctl --user disable {project}.service` | Disable the service to start on boot |
| `systemctl --user daemon-reload` | Reload the systemd user manager, needed if you edit your project's service unit |
| `loginctl enable-linger` | Enable lingering to keep the service running when you log out or don't log in (enabled by default) |
| `loginctl disable-linger` | Disable lingering to stop the service when you log out |

### Docker support

If Docker support was enabled when creating the project, you can use Docker as a non-root user. You can also manage Docker support with the following commands:

| Command | Description |
| --- | --- |
| `source /usr/bin/dockerd-rootless-setuptool.sh install` | Enable a rootless Docker instance for your user |
| `source /usr/bin/dockerd-rootless-setuptool.sh uninstall` | Disable the rootless Docker instance |
| `systemctl --user start docker.service` | Starts the rootless Docker service |
| `systemctl --user stop docker.service` | Stops the rootless Docker service |
| `systemctl --user restart docker.service` | Restarts the rootless Docker service |
| `systemctl --user status docker.service` | Shows the rootless Docker service status |
| `systemctl --user enable docker.service` | Enables the rootless Docker service to start on boot |
| `systemctl --user disable docker.service` | Disables the rootless Docker service to start on boot |
