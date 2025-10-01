# Set Up a Standalone Symphony Agent 

When deploying a Symphony agent as a container or via [Ankaios](./README.md)
, you may encounter issues accessing certain hardware or network devices due to container sandbox constraints. In these cases, you can modify the Ankaios manifest [state.yaml](./ankaios/state.yaml) to make Symphony agent privileged and use host network:

```yaml
apiVersion: v0.1
workloads:
  symphony:
    ...
    runtimeConfig: |
      image: ghcr.io/eclipse-symphony/symphony-api:0.48-proxy.41
      commandOptions: ["--privileged", "--net=host", "-e","CONFIG=/symphony-agent.json"]
```

You may also want to mount your devices (such as USB devices) to the container.

On the other hand, for diagnosis purposes, you can run the Symphony agent as a standalone process, which allows direct access to your machine’s peripherals, such as USB devices or devices connected via serial cables.

## Acquire Symphony binary

The easiest way to get the Symphony binary is to install Symphony's CLI tool, maestro:

```bash
wget -q https://raw.githubusercontent.com/eclipse-symphony/symphony/proxy-processor/cli/install/install.sh -O - | /bin/bash
```
Once `maestro` is installed, you can find the Symphony binary, `symphony-api`, under your `~/.symphony` folder.

Copy `symphony-api` to the `hpc_variant` folder of this repo:

```bash
cp ~/.hpc_variant/symphony-api <path/to/challenge-repo-clone>/symphony
```

## Update `symphony-agent-standalone.json` file as needed

When the agent is launched, it reads a provided configuration file, which is under `hpc_variant/symphony-agent.json` in this repo. The configuration file should work out-of-the-box. However, there are several things you might want to change in case your environment is different:
1. In the `bindings` section, you'll need to update the MQTT broker address to match with your settings if you were not using the MQTT broker deployed by the challenge Docker Compose file:
    ```json
    "brokerAddress": "tcp://localhost:1883",
    ```
2. If you experiment with multiple agents, you need to make sure each agent is launched with a different MQTT client id:
    ```json
    "clientID": "my-agent",
    ```
3. An agent is fixed to a list of specific Target names it represents. By default, there's a single `pc-target` defined. If you want ot use a different Target name, or use a list of Target names, you need to update the `targetNames` attributes with comma-separated Target names that match with the actual Target names you deploy.
    ```json
    "targetNames": "pc-target",
    ```
4. By default, the configuration file contains the mock Rust provider and the sample Rust provider in this repo. Essentially, if you have a `example_type` component, it will be handled by the mock provider; and if you have a `my_type` component, it will be handled by the sample Rust provider. You can edit the config file to include your own providers.

## Launch the agent

Now you can launch the agent as a process: 

```bash
USE_SERVICE_ACCOUNT_TOKENS=false SYMPHONY_API_URL=http://localhost:8082/v1alpha2/ ./symphony-api -c ./symphony-agent-standalone.json -l Error

# If you want to see more logs, you can switch the log level flag from "Error" to "Information" or "Debug", which is the most verbose.
```

## Test the remote agent

You can use the `samples/remote_target/test_remote_agent.sh` script to create and then destroy a Target (named `pc-target`) and observe what the prvoider does via logs. See Target definition in `samples/remote_target/target.json`.
