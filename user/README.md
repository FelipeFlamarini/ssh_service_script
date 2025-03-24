# Usage as a project user

## Logging into the project user

The admin will provide you with the project user's username, password and hostname. You can log in by having `ssh` installed and using the following command:

```sh
ssh {username}@{hostname}
```

A prompt will ask for the password. Enter the password provided and you will be logged in.

## Managing your project

The project user's home directory is located in `/etc/projects/{project_name}`, which will be the working directory when you log in. There will be an empty folder named `project` in your home directory, where you will store your project's source code. If your project's repository is hosted on GitHub, you can clone it into this folder with this command:

```sh
git clone {repository_url} project
```

You can also transfer your project files through `scp` to the `project` directory.

```sh
scp -r {source_directory} {username}@{hostname}:/etc/projects/{project_name}/project
```

## Managing your user's service unit

The user service unit is created by the `create_project.sh` script and is named based on your project name, as in  `{project_name}.service`. It is located in the user's home systemd directory:

```sh
~/.config/systemd/user/{project_name}.service
```

It's possible to edit the service file to change the start/stop command and other settings. You can edit the service file using the following command:

```sh
nano ~/.config/systemd/user/{project_name}.service
```

The actions you can perform on the service are:

| Command | Description |
| --- | --- |
| `systemctl --user start {project_name}.service` | Start the service |
| `systemctl --user stop {project_name}.service` | Stop the service |
| `systemctl --user restart {project_name}.service` | Restart the service |
| `systemctl --user status {project_name}.service` | Show the service status |
| `systemctl --user enable {project_name}.service` | Enable the service to start on boot (enabled by default) |
| `systemctl --user disable {project_name}.service` | Disable the service to start on boot |
| `systemctl --user daemon-reload` | Reload the systemd user manager, needed if you edit your project's service unit |
| `loginctl enable-linger` | Enable lingering to keep the service running when you log out or don't log in (enabled by default) |
| `loginctl disable-linger` | Disable lingering to stop the service when you log out |

## Docker support

If Docker support was enabled when creating the project, you can use Docker as a non-root user. You can also manage Docker support with the following commands:

| Command | Description |
| --- | --- |
| `source /usr/bin/dockerd-rootless-setuptool.sh install` | Install a rootless Docker instance for your user |
| `source /usr/bin/dockerd-rootless-setuptool.sh uninstall` | Uninstall the rootless Docker instance |
| `systemctl --user start docker.service` | Starts the rootless Docker service |
| `systemctl --user stop docker.service` | Stops the rootless Docker service |
| `systemctl --user restart docker.service` | Restarts the rootless Docker service |
| `systemctl --user status docker.service` | Shows the rootless Docker service status |
| `systemctl --user enable docker.service` | Enables the rootless Docker service to start on boot |
| `systemctl --user disable docker.service` | Disables the rootless Docker service to start on boot |
