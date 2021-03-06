# List of Hobo.PowerManager Parameters

## Configuration
### PMHost
One or more VMWare ESXi servers to connect and power on VM's

| Info     | Value |
-----------|-------|
| **Required** | Yes |
| **Command**  | `-PMHost <String[]>` |
| **Env**      | `PM_HOSTS=<comma-delimited String>` |
| **File**     | `Get-PMPref Host ; Add/Remove-PMPref Host '{{PMHost}}'` |


### Datastore
Datastores that should be connected before proceeding with power-on operations

| Info     | Value |
-----------|-------|
| **Required** | No |
| **Command**  | `-Datastore <String[]>` |
| **Env**      | `PM_DATASTORES=<comma-delimited String>` |
| **File**     | `Get-PMPref Datastore ; Add/Remove-PMPref Datastore '{{Datastore}}'` |


### Exclusion
Virtual Machines that should be ignored

| Info     | Value |
-----------|-------|
| **Required** | No |
| **Command**  | `-Exclusion <String[]>` |
| **Env**      | `PM_EXCLUSIONS=<comma-delimited String>` |
| **File**     | `Get-PMPref VmExclusion ; Add/Remove-PMPref VmExclusion '{{Exclusion}}'` |


### Credential
Credentials to be used when connecting to ESXi hosts.  Each host must be able to authenticate with at least one of these credential providers.

| Info         | Value |
---------------|-------|
| **Required** |  Yes  |

#### Default
Default credentials can be set as fallback if no host-specific credentials exist

| Info     | Value |
-----------|-------|
| **Env**  | `PM_USERNAME=<String> PM_PASSWORD=<String>` |
| **File** | `Set-PMCredential` |

#### Host-specific
Host-specific credentials can be set by replacing `{{PMHost}}` in the following values with the hostname or IP address being used to connect to that host

| Info     | Value |
-----------|-------|
| **Env**  | `PM_USERNAME_{{PMHost}}=<string> PM_PASSWORD_{{PMHost}}=<string>` |
| **File** | `Set-PMCredential {{PMHost}}` |

#### Command line parameter
If the `-Credential` parameter is used that credential will be used to connect to all hosts, regardless of other configured providers
| Info        | Value |
--------------|-------|
| **Command** | `-Credential <PSCredential>` |



## Script Behavior
### Wait
Continuously run, reconnecting to a host if connection is lost and powering on any non-excluded machines.

| Info     | Value |
-----------|-------|
| **Required** | No |
| **Command**  | `-Wait` |

### ConfigRefresh
When used with `Wait` enables configuration variable auto-refresh

| Info     | Value |
-----------|-------|
| **Required** | No |
| **Command**  | `-ConfigRefresh` |

### ConfigRefreshInterval
The minimum amount of time to wait between configuration refreshes when `ConfigRefresh` is enabled

| Info     | Value |
-----------|-------|
| **Required** | No |
| **Command**  | `-ConfigRefreshInterval '01:00:00'` |

### PollingInterval
The amount of time between host connecivity checks

| Info     | Value |
-----------|-------|
| **Required** | No |
| **Command**  | `-PollingInterval '00:00:30'` |

### OutputInterval
The amount of time between job status checks

| Info     | Value |
-----------|-------|
| **Required** | No |
| **Command**  | `-OutputInterval '00:00:10'` |
