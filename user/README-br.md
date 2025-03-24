# Uso como um usuário do projeto

## Entrando no usuário do projeto

O administrador fornecerá o nome de usuário, senha e hostname do usuário do projeto. Você pode fazer login tendo o `ssh` instalado e usando o seguinte comando:

```sh
ssh {username}@{hostname}
```

Um prompt solicitará a senha. Digite a senha fornecida e você estará conectado.

## Gerenciando seu projeto

O diretório inicial do usuário do projeto está localizado em `/etc/projects/{project_name}`, que será o diretório de trabalho quando você fizer login. Haverá uma pasta vazia chamada `project` em seu diretório inicial, onde você armazenará o código fonte do seu projeto. Se o repositório do seu projeto estiver hospedado no GitHub, você pode cloná-lo para esta pasta com este comando:

```sh
git clone {repository_url} project
```

Também é possível transferir os arquivos do seu projeto por `scp` para o diretório `project`.

```sh
scp -r {source_directory} {username}@{hostname}:/etc/projects/{project_name}/project
```

## Gerenciando a unidade de serviço do seu usuário

A unidade de serviço do usuário é criada pelo script create_project.sh e é nomeada com base no nome do seu projeto, como `{project_name}.service`. Ela está localizada no diretório systemd do usuário:

```sh
~/.config/systemd/user/{project_name}.service
```

É possível editar o arquivo de serviço para alterar o comando de inicialização/parada e outras configurações. Você pode editar o arquivo de serviço usando o seguinte comando:

```sh
nano ~/.config/systemd/user/{project_name}.service
```

As ações que você pode realizar no serviço são:

| Comando | Descrição |
| --- | --- |
| `systemctl --user start {project_name}.service` | Iniciar o serviço |
| `systemctl --user stop {project_name}.service` | Parar o serviço |
| `systemctl --user restart {project_name}.service` | Reiniciar o serviço |
| `systemctl --user status {project_name}.service` | Mostrar o status do serviço |
| `systemctl --user enable {project_name}.service` | Habilitar o serviço para iniciar na inicialização (habilitado por padrão) |
| `systemctl --user disable {project_name}.service` | Desabilitar o serviço para iniciar na inicialização |
| `systemctl --user daemon-reload` | Recarregar o gerenciador de usuário systemd, necessário se você editar a unidade de serviço do seu projeto |
| `loginctl enable-linger` | Habilitar o "lingering" para manter o serviço em execução quando você sair ou não fizer login (habilitado por padrão) |
| `loginctl disable-linger` | Desabilitar o "lingering" para parar o serviço quando você sair |

## Suporte a Docker

Se o suporte ao Docker foi habilitado ao criar o projeto, você pode usar o Docker como um usuário não-root. Você também pode gerenciar o suporte ao Docker com os seguintes comandos:

| Comando | Descrição |
| --- | --- |
| `source /usr/bin/dockerd-rootless-setuptool.sh install` | Instalar uma instância rootless do Docker para seu usuário |
| `source /usr/bin/dockerd-rootless-setuptool.sh uninstall` | Desinstalar a instância rootless do Docker |
| `systemctl --user start docker.service` | Iniciar o serviço rootless do Docker |
| `systemctl --user stop docker.service` | Parar o serviço rootless do Docker |
| `systemctl --user restart docker.service` | Reiniciar o serviço rootless do Docker |
| `systemctl --user status docker.service` | Mostrar o status do serviço rootless do Docker |
| `systemctl --user enable docker.service` | Habilitar o serviço rootless do Docker para iniciar na inicialização |
| `systemctl --user disable docker.service` | Desabilitar o serviço rootless do Docker para iniciar na inicialização |
