Threat Stack Agent Helm Chart
=============================

### Overview

This project defines the helm chart to deploy the Threat Stack container agent in the recommended configuration for kubernetes.

>>>
**Note:** The chart `version` is independent of the version of the agent packaged/installed by the chart. The version of the application to be installed by the helm chart is defined by helm's `appVersion` field.

Because agent updates and improvements from version to version can require backwards-incompatible chart changes, we do not provide a way for the agent version to be overridden by a customer `values.yaml` file override.
>>>

This chart installs the agent in the recommended configuration for kubernetes clusters. Configuration values should be overridden by passing helm one or more yaml files of overrides. See [Additional Installation Notes](#additional-installation-notes) section for specific recommendations.

The following kubernetes objects are created:

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
* A Secret to store [sensitive agent configuration](#additional-installation-notes)
* A ConfigMap will be created to store the Threat Stack agent's setup and runtime configuration options.

### Installation

>>>
These instructions assume that you already have helm (and the server-side component tiller, if using helm 2) installed in your environment, and that any RBAC configuration for proper operation of helm has been completed.
>>>

#### Local Installation
The instructions below assume the helm chart has been released to a repository. Alternatively, you can clone this git repository and run `helm package .` in the repository's root to get a `.tgz` file built locally. 

In this, one should not add the helm repository as directed below (step 1), and omit the `--repo https://pkg.threatstack.com/helm` from any command. Also, instead of the chart name being `threatstack-agent`, you should use `<PATH_TO_CHART>/threatstack-agent-<VERSION>.tgz` in helm commands.

>>>
**WARNING:** Creating a local helm chart does not sign it. Any verfication of the provenance of the chart will fail.
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

helm upgrade <HELM_RELEASE_NAME> threatstack/threatstack-agent

#### Uninstalling the chart

helm delete <HELM_RELEASE_NAME>

#### Additional Installation Notes

There is one chart values setting, `agentDeployKey`, that is not defined in the default chart `values.yaml`. The reason is two-fold:

* This value is different for every Threat Stack customer.
* This value is sensitive information.

Specifically because of the second reason, it is recommended that this value is **not stored in any source-controlled file**. This value should not be shared, and committing the value to source control can increase the risk of an unauthorized user discovering it.

Additionally, the helm chart stores this variable in a kubernetes secret when the chart is installed, to avoid the value from being discoverable after installation. Any change of the value should cause a redeployment of the agent with the new value.

Since helm allows for multiple override files to be supplied to a single `helm install` command, the `agentDeployKey` setting should be overridden in a _separate values file_. This should be done for initial installation and any time the Threat Stack deploy key needs to change.

> Most of the overridable values for the threatstack agent helm chart are **not** sensitive, and therefore can (and should) be checked into a source control system.

Assuming you override the default values to match our environment in a `values.yaml` file, and separately override the deploy key setting in a file named `deploykey-override.yaml`, an example `helm install` command would look like:

> helm install --name my-threatstack-agents --values values.yaml --values deploykey-override.yaml threatstack/threatstack-agent

#### Important Configuration Settings

The following values settings for the helm chart are important to note, or expected to be modified for each target environment:

* `image.repository`      :: The docker repository for the container image to install. It defaults to Threat Stack's offical docker hub repository for the agent. **NOTE:** Changing this could lead to pulling an unofficial or incorrect image, and is strongly discouraged.
* `image.version`         :: The docker tag for the container image to install. It defaults to Threat Stack's latest offical docker image version for the agent at the time the chart was released. **NOTE:** Changing this could lead to pulling an unofficial or incorrect image, and is strongly discouraged.
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

### Contributing enhancements/fixes

Please fork this repository and submit any changes with a pull request.

### Licensing

See the [LICENSE](LICENSE)
