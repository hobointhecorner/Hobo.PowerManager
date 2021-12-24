# Install PowerManager with Ansible

`ansible_playbook install_powermanager.yml`

If you prefer, you can use Ansible to install the PowerManager container as a systemd service that runs `Start-PowerManager -Wait`.

## Setting up Inventory
Configuration of the container is handled via inventory variables.  By default, inventory is pulled from a directory named inventory in this directory.

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

### Configuration Variables
| Name                           | Required | Type         | Default | Description | More info |
|--------------------------------|----------|--------------|---------|-------------|-----------|
| pm_hosts                       | true     | list(map())  |         | List of maps with keys `host` (required), `username`, `password`. | [PMHost](../Hobo.PowerManager/CONFIG.md#pmhost), [Credential](../Hobo.PowerManager/CONFIG.md#credential) |
| pm_datastores                  | false    | list(string) |         | Datastores that must be available before continuing | [Datastore](../Hobo.PowerManager/CONFIG.md#datastore) |
| pm_exclusions                  | false    | list(string) |         | VMs to ignore | [Exclusion](../Hobo.PowerManager/CONFIG.md#exclusion) |
| pm_username                    | false    | string       |         | Username to use by default to connect to VMWare hosts | [Credential](../Hobo.PowerManager/CONFIG.md#credential) |
| pm_password                    | false    | string       |         | Password to use by default to connect to VMWare hosts | [Credential](../Hobo.PowerManager/CONFIG.md#credential) |
| pm_additional_parameters       | false    | list(string) |         | Any additional command-line parameters to pass to the Start-PowerManager cmdlet | [Script Behavior](../Hobo.PowerManager/CONFIG.md#script-behavior) |
| pm_config_dir                  | false    | string       | /opt/powermanager | Destination directory for powermanager config files | |
| pm_container_registry          | false    | string       | ghcr.io | The container registry from which to pull the powermanager container | |
| pm_container_name              | false    | string       | hobointhecorner/hobo.powermanager | The name of the powermanager container to pull | |
| pm_container_tag               | false    | string       | stable  | The tag of the container to pull. Can be `latest`, `stable`, or any tagged version | |
| pm_container_force_pull        | false    | bool         | false   | Always pull the container image and restart the service | |
| pm_container_registry_username | false    | string       |         | The username with which to authenticate to the container registry | |
| pm_container_registry_password | false    | string       |         | The password with which to authenticate to the container registry | |
