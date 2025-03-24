# SSH Service Script

This repository contains scripts to create and delete project environments with systemd services and optional Docker support.

## Usage as an admin

### Prerequisites

These prerequisites suppose you are running a Ubuntu 24.04 installation. The scripts may work on other distributions, but the commands may differ.

- have a user with sudo privileges;
- have `systemd-container` installed;
- have openssh-server installed and running (optional, needed for remote access);

For the Docker optional support:

- have Docker Engine and docker-ce-rootless-extras installed (must be installed following the instructions from the [official Docker documentation](https://docs.docker.com/engine/install/ubuntu/) using their `apt` repository);
- have `newuidmap` and `newgidmap` installed (provided by the `uidmap` package);

You can run the [install_prerequisites.sh](install_prerequisites.sh) script to install the prerequisites:

```sh
sudo ./install_prerequisites.sh
```

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
- Deleting the project user and ALL ITS DATA.

Run the `delete_project.sh` script and follow the prompts:

```sh
sudo ./delete_project.sh
```

### Storage

The projects' home directories are located in `/etc/projects`.

### Logs

Logs for the scripts are stored in:

- `/etc/projects/logs/create_project.log`
- `/etc/projects/logs/delete_project.log`
