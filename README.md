Threat Stack Agent Helm Chart
=============================

![Release Version](https://img.shields.io/github/v/release/threatstack/threatstack-helm)

## Overview

This project defines the helm chart to deploy the Threat Stack container agent in the recommended configuration for kubernetes.

>>>
**Note:** The chart `version` is independent of the version of the agent packaged/installed by the chart. The default version of the Threat Stack agent to be installed by the helm chart is defined by the helm chart's `appVersion` field.

Because agent updates and improvements from version to version can require backwards-incompatible chart changes, *we do not recommend customers override the agent version*.
>>>

This chart installs the agent in the recommended configuration for kubernetes clusters. Configuration values should be overridden by passing helm one or more yaml files of overrides. See [Additional Installation Notes](#additional-installation-notes) section for specific recommendations. For a full list of values defined for this chart, see the `values.yaml` in this repository.

The following kubernetes objects are created when the chart is installed:

* A service account named `threatstack-agent` (unless overridden in a `values.yaml`), created in the namespace specifed (the default is `default`)
* A clusterrole/clusterrolebinding that allows the service account to get/list/watch the following objects:
  * events
  * namespaces
  * pods
  * clusterroles
  * clusterrolebindings
  * roles
  * rolebindings
* A daemonset that installs the threatstack agent container on each node (1 container per node). It defaults to deploying on all nodes (this can be overridden via a `values.yaml`).
* A replicaset to deploy a specially configured threatstack-agent container that communicates with the kubernetes control plane.
* A Secret to store [sensitive agent configuration](#additional-installation-notes), unless you [define your own secret](#using-the-agentsetupexternalsecretref-value-block)
* A ConfigMap will be created to store the Threat Stack agent's setup and runtime configuration options.
* Optionally a Pod Security Policy for clusters with strict pod admission control requirements.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalSetupConfig | string | `""` | A list of command line arguments used when the agent container registers itself with the Threat Stack platform. See official documentation for details. |
| agentDeployKey | string | `""` |  |
| agentSetupExternalSecretRef | object | `{}` |  |
| apiReader.additionalRuntimeConfig | string | `"log.level info"` |  |
| apiReader.affinity | object | `{}` |  |
| apiReader.nodeSelector | object | `{}` |  |
| apiReader.tolerations | list | `[]` |  |
| apiReader.podAnnotations | string | {} |  |
| apiReader.priorityClassName | string | `""` | Optionally set the priority class name for the daemonset pods. Note that priority classes are not created via this helm chart. Ref: https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/ |
| capabilities | list | `["AUDIT_CONTROL", "SYS_ADMIN", "SYS_PTRACE", "SYS_NICE"]` | Docker capabilites required for the proper operation of the agent |
| customDaemonsetCmd | object | `{}` | Uncomment the `command` and `args` sub-attributes, and define them as desired to run custom commands in the daemonset. |
| daemonset.additionalRuntimeConfig | string | `"log.level info"` |  |
| daemonset.affinity | object | `{}` |  |
| daemonset.customAuditRules | string | `""` |  |
| daemonset.customLuaFilter | string | `""` |  |
| daemonset.customTsAuditdConfig | string | `""` |  |
| daemonset.enableContainerd | bool | `unset` | Configures the daemonset agents to listen to the containerd daemon socket. **By default in agent 2.4.0+, the agent detects if containerd is running at startup**  |
| daemonset.enableDocker | bool | `unset` | Configures the daemonset agents to listen to the docker daemon socket. **By default in agent 2.4.0+, the agent detects if docker is running at startup** |
| daemonset.enableLowPowerMode | bool | false | Configures the daemonset agents to perform better in tightly-resourced environments. The agent trades some telemetry reporting for reduced CPU and memory consumption. Ref: https://threatstack.zendesk.com/hc/en-us/articles/360016132692-Threat-Stack-Kubernetes-Deployment |
| daemonset.nodeSelector | object | `{}` |  |
| daemonset.podAnnotations."container.apparmor.security.beta.kubernetes.io/threatstack-agent" | string | `"unconfined"` |  |
| daemonset.priorityClassName | string | `""` | Optionally set the priority class name for the daemonset pods. Note that priority classes are not created via this helm chart. Ref: https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/ |
| daemonset.tolerations | list | `[]` |  |
| ebpfEnabled | bool | `false` | Enables using ebpf-based monitoring where applicable. With some workloads, an increase in resource usage by the agent has been seen. |
| eksAmazon2 | bool | `false` | If `true`, the Daemonset definition will be modified to execute commands for the agent to work correctly on EKS with Amazon Linux 2 nodes. Defaults to `false` |
| eksAmazon2Cmd.args[0] | string | `"-c"` |  |
| eksAmazon2Cmd.args[1] | string | `"chroot /threatstackfs /bin/bash -c 'service auditd stop; systemctl disable auditd'; eval tsagent setup $THREATSTACK_SETUP_ARGS; eval tsagent config --set $THREATSTACK_CONFIG_ARGS; sleep 5; /opt/threatstack/sbin/tsagentd -logstdout"` |  |
| eksAmazon2Cmd.command[0] | string | `"bash"` |  |
| fullnameOverride | string | `""` |  |
| gkeContainerOs | bool | `false` | If `true`, the Daemonset definition will be modified to execute commands for the agent to work correctly on GKE with ContainerOS node |
| gkeContainerOsCmd.args[0] | string | `"-c"` |  |
| gkeContainerOsCmd.args[1] | string | `"chroot /threatstackfs /bin/bash -c 'systemctl stop systemd-journald-audit.socket; systemctl mask systemd-journald-audit.socket; systemctl restart systemd-journald; auditctl --backlog_wait_time 0'; eval tsagent setup $THREATSTACK_SETUP_ARGS; eval tsagent config --set $THREATSTACK_CONFIG_ARGS; sleep 5; /opt/threatstack/sbin/tsagentd -logstdout"` |  |
| gkeContainerOsCmd.command[0] | string | `"bash"` |  |
| gkeUbuntu | bool | `false` | If `true`, the Daemonset definition will be modified to execute commands for the agent to work correctly on GKE with Ubuntu nodes. Defaults to `false` |
| gkeUbuntuCmd.args[0] | string | `"-c"` |  |
| gkeUbuntuCmd.args[1] | string | `"chroot /threatstackfs /bin/bash -c 'systemctl stop auditd; systemctl disable auditd'; eval tsagent setup $THREATSTACK_SETUP_ARGS; eval tsagent config --set $THREATSTACK_CONFIG_ARGS; sleep 5; /opt/threatstack/sbin/tsagentd -logstdout"` |  |
| gkeUbuntuCmd.command[0] | string | `"bash"` |  |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `"threatstack/ts-docker2"` | The docker repository for the container image to install. It defaults to Threat Stack's offical docker hub repository for the agent. **NOTE:** Changing this could lead to pulling an unofficial, incorrect, or incompatible image, and is strongly discouraged. |
| image.version | string | `""` | The docker tag for the container image to install. It defaults to Threat Stack's latest offical docker image version for the agent at the time the chart was released. **NOTE:** Changing this could lead to pulling an unofficial, incorrect, or incompatible image, and is strongly discouraged. >>> **Warning:** Setting `customDaemonsetCmd` improperly can result in the Threat Stack agent not running correctly >>> |
| imagePullSecrets | list | `[]` | If pulling the agent from a private/internal docker registry that requires credentials, you will need to add the name of your docker credentials secret to this array. *This secret needs to be defined outside of installing this helm chart.* Defaults to an empty array which will only work with public registries. * For more guidance with using private container registries, please review the following kubernetes documentation for details around how to set this upcorrectly with your registry service: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#add-imagepullsecrets-to-a-service-account https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line https://kubernetes.io/docs/concepts/containers/images/#using-a-private-registry |
| nameOverride | string | `""` |  |
| podSecurityPolicyEnabled | bool | `false` | Deploy Threat Stack with the Pod Security Policy for clusters with strict admission control requirements. |
| rbac.create | bool | `true` | If `true`, will create the needed service account to run. If false, the chart will leverage the service account defined in `rbac.serviceAccountName` |
| rbac.serviceAccountName | string | `"threatstack-agent"` |  |
| rulesets | string | `"Base Rule Set, Docker Rule Set, Kubernetes Rule Set"` | The list of Threat Stack rulesets that the againt container should run with. The single-quotes in the double-quotes are intentional and not optional. |

## Local Installation

The instructions below assume the helm chart has been released to a repository. Alternatively, you can clone this git repository and run `helm package .` in the repository's root to get a `.tgz` file built locally.

In this, one should not add the helm repository as directed below (step 1), and omit the `--repo https://pkg.threatstack.com/helm` from any command. Also, instead of the chart name being `threatstack-agent`, you should use `<PATH_TO_CHART>/threatstack-agent-<VERSION>.tgz` in helm commands.

>>>
**WARNING:** Creating a local helm chart does not sign the chart package. Any verfication of the provenance of the chart will fail.
>>>

#### Installing publicly released chart

The threatstack agent helm chart follows the standard installation process for charts:

1. Add the threatstack agent helm repository (URL: https://pkg.threatstack.com/helm) to your local helm configuration
   ```shell
   > helm repo add threatstack https://pkg.threatstack.com/helm
   ```
1. Using the default `values.yaml`, create a local yaml that overrides the configuration as desired or needed for the target cluster (See [Additional Installation Notes][#additional-installation-notes] below)
1. Install the threatstack agent with helm
    * `Helm 2:`
   ```shell
   > helm install --name <HELM_RELEASE_NAME> --values ./<values-override-filename>.yaml threatstack/threatstack-agent
   ```
    * `Helm 3:`
   ```shell
   > helm install <HELM_RELEASE_NAME> --values ./<values-override-filename>.yaml threatstack/threatstack-agent
   ```

## Updating the chart

After making changes, run:

```shell
> helm upgrade <HELM_RELEASE_NAME> threatstack/threatstack-agent
```

#### Uninstalling the chart

```shell
> helm delete <HELM_RELEASE_NAME>
```

## Additional Installation Notes

There is one chart values setting, `agentDeployKey`, that is not defined in the default chart `values.yaml`. The reason is two-fold:

* This value is different for every Threat Stack customer.
* This value is sensitive information.

Specifically because of the second reason, it is recommended that this value is **not stored in any source-controlled file**. This value should not be shared, and committing the value to source control can increase the risk of an unauthorized user discovering it.

Additionally, the helm chart stores this variable in a kubernetes secret when the chart is installed, to avoid the value from being discoverable after installation. Any change of the value should cause a redeployment of the agent with the new value.

Since helm allows for multiple override files to be supplied to a single `helm install` command, the `agentDeployKey` setting should be overridden in a _separate values file_. This should be done for initial installation and any time the Threat Stack deploy key needs to change.

Assuming you override the default values to match our environment in a `values.yaml` file, and separately override the deploy key setting in a file named `deploykey-override.yaml`, an example `helm install` command would look like:

```shell
> helm install --name my-threatstack-agents --values values.yaml --values deploykey-override.yaml threatstack/threatstack-agent
```

> **NOTE:** Most of the overridable values for the threatstack agent helm chart are **not** sensitive, and therefore can (and should) be checked into a source control system.

##### Using the `agentSetupExternalSecretRef` value block

>>>
**IMPORTANT:** Using `agentSetupExternalSecretRef` decouples secret management from the helm chart. Therefore, if the value of the secret changes, the agent DaemonSet and Deployment will _not_ be redeployed/restarted. The user will need to force a redeployment of the helm chart explicitly.

However, if the secret's name or secret's entry name changes in the `values.yaml` of the chart, helm will recognize this change with a new release, and trigger a redeployment of the DaemonsSet and Deployment. One way to take advantage of this is to update the secrets entry value name (what is defined at `agentSetupExternalSecretRef.value`) when changing the secret data, and doing a redeploy of the chart. The chart trigger a redeployment of the agent pods.
>>>

An alternative to having the chart define the `ts-setup-args` secret itself, you can instead have it point to your own self-managed secret. Doing so requires the following three values to be set:

* `agentSetupExternalSecretRef.name`      :: This is the name of your self-managed secret.
* `agentSetupExternalSecretRef.key`       :: This is the key in your self-managed secret that is associated with the data you want to supply from the secret, to the Threat Stack agent setup registration.

Do not set the `agentSetupExternalSecretRef` block *and* the `agentDeployKey` settings at the same time. This will cause unnecessary kubernetes resource definitions to be created. If you had previously used the `agentDeployKey` value, the secret associated with it may be destroyed on deployment.

Using the `agentSetupExternalSecretRef` block will cause the chart to ignore the `agentDeployKey`, `rulesets`, and `additionalSetupConfig` values defined in `values.yaml` or any other values override file, until existing pods are terminated/rescheduled.

The value defined in the secret by `agentSetupExternalSecretRef.name`/`agentSetupExternalSecretRef.key` should be defined as in the example below to properly setup up the agent. Failure to do so can cause the agent to not properly register itself with the Threat Stack platform.

```shell
--deploy-key <your-deploy-key> --ruleset '<your-rulesets>' <additional-setup-configuration>"
```

### Contributing enhancements/fixes

See the [CONTRIBUTING document](CONTRIBUTING.md) for details.

### Licensing

See the [LICENSE](LICENSE)

### Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Threat Stack Inc. | support@threatstack.com |  |