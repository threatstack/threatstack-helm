Threat Stack Agent Helm Chart
=============================

### Overview

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

### Installation

>>>
These instructions assume that you already have helm (and the server-side component tiller, if using helm 2) installed in your environment, and that any RBAC configuration for proper operation of helm has been completed.
>>>

#### Local Installation

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

#### Updating the chart

After making changes, run:

```shell
> helm upgrade <HELM_RELEASE_NAME> threatstack/threatstack-agent
```

#### Uninstalling the chart

```shell
> helm delete <HELM_RELEASE_NAME>
```

#### Additional Installation Notes

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

> **WARNING:** Do not set the `agentSetupExternalSecretRef` block *and* the `agentDeployKey` settings at the same time. This will cause unnecessary kubernetes resource definitions to be created. If you had previously used the `agentDeployKey` value, the secret associated with it may be destroyed on deployment.

An alternative to having the chart define the `ts-setup-args` secret itself, you can instead have it point to your own self-managed secret. Doing so requires the following three values to be set:

* `agentSetupExternalSecretRef.name`      :: This is the name of your self-managed secret.
* `agentSetupExternalSecretRef.key`       :: This is the key in your self-managed secret that is associated with the data you want to supply from the secret, to the Threat Stack agent setup registration.

Using the `agentSetupExternalSecretRef` block will cause the chart to ignore the `agentDeployKey`, `rulesets`, and `additionalSetupConfig` values defined in `values.yaml` or any other values override file, until existing pods are terminated/rescheduled.

The value defined in the secret by `agentSetupExternalSecretRef.name`/`agentSetupExternalSecretRef.key` should be defined as in the example below to properly setup up the agent. Failure to do so can cause the agent to not properly register itself with the Threat Stack platform.

```shell
--deploy-key <your-deploy-key> --ruleset '<your-rulesets>' <additional-setup-configuration>"
```

#### Important Configuration Settings

The following values settings for the helm chart are important to note, or expected to be modified for each target environment:

* `image.repository`      :: The docker repository for the container image to install. It defaults to Threat Stack's offical docker hub repository for the agent. **NOTE:** Changing this could lead to pulling an unofficial, incorrect, or incompatible image, and is strongly discouraged.
* `image.version`         :: The docker tag for the container image to install. It defaults to Threat Stack's latest offical docker image version for the agent at the time the chart was released. **NOTE:** Changing this could lead to pulling an unofficial, incorrect, or incompatible image, and is strongly discouraged.
* `gkeContainerOs`        :: If `true`, the Daemonset definition will be modified to execute commands for the agent to work correctly on GKE with ContainerOS nodes. Defaults to `false`
* `gkeUbuntu`             :: If `true`, the Daemonset definition will be modified to execute commands for the agent to work correctly on GKE with Ubuntu nodes. Defaults to `false`
* `customDaemonsetCmd`    :: Uncomment the `command` and `args` sub-attributes, and define them as desired to run custom commands in the daemonset.
>>>
**Warning:** Setting `customDaemonsetCmd` improperly can result in the Threat Stack agent not running correctly
>>>
* `rbac.create`           :: If `true`, will create the needed service account to run. If false, the chart will leverage the service account defined in `rbac.serviceAccountName`
* `imagePullSecrets`      :: If pulling the agent from a private/internal docker registry that requires credentials, you will need to add the name of your docker credentials secret to this array. *This secret needs to be defined outside of installing this helm chart.* Defaults to an empty array which will only work with public registries.
    * For more guidance with using private container registries, please review the following kubernetes documentation for details around how to set this upcorrectly with your registry service:
        * https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#add-imagepullsecrets-to-a-service-account
        * https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line
        * https://kubernetes.io/docs/concepts/containers/images/#using-a-private-registry
* `rulesets`              :: The list of Threat Stack rulesets that the againt container should run with. The single-quotes in the double-quotes are intentional and not optional.
* `additionalSetupConfig` :: A list of command line arguments used when the agent container registers itself with the Threat Stack platform. See official documentation for details.
* `additionalConfig`      :: A list of command line arguments used when the agent container starts running. See official documentation for details.
* `podSecurityPolicyEnabled` :: If `true`, will create a pod security policy and configure the cluster role rules with that policy.
* `daemonset.priorityClassName` :: Optionally set the priority class name for the daemonset pods. Note that priority classes are not created via this helm chart.

#### Overriding Container Daemon Socket Paths

There are three paths that get mounted into the container agent. They point to the default paths if not overridden. You can now override where to get these mounts from the underlying host with the following configuration:

* `daemonset.volumes.dockersocket.hostPath` :: Path to docker daemon's socket
* `daemonset.volumes.containerdsocket.hostPath` :: Path to containerd daemon's socket
* `daemonset.volumes.oldcontainerdsocket.hostPath` :: Path to older containerd daemon's socket

#### Adding annotations to the Daemonset Pods

The following value can be configured as a map to add custom pod annotations (key/value pairs) to the agent daemonset.

* `daemonset.podAnnotations` :: Defaults to an empty hash


### Contributing enhancements/fixes

Please fork this repository and submit any changes with a pull request.

### Licensing

See the [LICENSE](LICENSE)
