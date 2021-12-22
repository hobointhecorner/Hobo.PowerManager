# Install PowerManager with Ansible

`ansible_playbook install_powermanager.yml`

If you prefer, you can use Ansible to install the PowerManager container as a service.

## Setting up Inventory
Configuration of the container is handled via inventory variables.  By default, inventory is pulled from a directory named inventory in this directory.

### Configuration Variables
| Name                           | Required | Type         | Default | Description |
|--------------------------------|----------|--------------|---------|-------------|
| pm_hosts                       | true     | list(map())  |         | List of maps with keys `host` (required), `username`, `password`. |
| pm_datastores                  | false    | list(string) |         | Datastores that must be available before continuing |
| pm_exclusions                  | false    | list(string) |         | VMs to ignore |
| pm_username                    | false    | string       |         | Username to use to connect to VMWare hosts by default |
| pm_password                    | false    | string       |         | Password to use to connect to VMWare hosts by default |
| pm_config_dir                  | false    | string       | /opt/powermanager | Destination directory for powermanager config files |
| pm_container_registry          | false    | string       | ghcr.io | The container registry from which you're pulling powermanager |
| pm_container_name              | false    | string       | hobointhecorner/hobo.powermanager | The powermanager container to pull |
| pm_container_tag               | false    | string       | stable  | The tag of the container to pull. Can be `latest`, `stable`, or any tagged version |
| pm_container_registry_username | false    | string       |         | The username with which to authenticate to the container registry |
| pm_container_registry_password | false    | string       |         | The password with which to authenticate to the container registry |
| pm_additional_parameters       | false    | list(string) |         | Any additional command-line parameters to pass to the Start-PowerManager cmdlet |

### Example inventory/main.yml
```
---
all:
  hosts:
    powermanager:
      pm_hosts:
        - host: 10.0.5.110
        - host: 10.0.5.120
        - host: 10.0.5.130
          username: << host_username >>
          password: << host_password >>
      pm_datastores:
        - VM01
        - STORAGE01
      pm_exclusions:
        - legacy01
      pm_username: << default_username >>
      pm_password: << default_password >>
```
