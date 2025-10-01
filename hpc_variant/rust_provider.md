# Write a Symphony Custom Target Provider using Rust

At Symphony's core is a state-seeking system, where devices' current states are probed and compared with the user-specified desired state. Symphony runs a continuous reconciliation loop that ensures the devices' current states are brought towards, and eventually consistent with, the desired state.

Symphony communicates with a specific device type or a system via a **Target Provider**, which implements the Symphony state-seeking interface, such as a `get()` method to return the current state to Symphony, and an `apply()` method to apply the new desired state. Symphony allows you to write such providers using Go, shell scripts (such as Bash and PowerShell), as well as Rust. In this challenge, we'll be using the Rust programming language.

> **NOTE:** If you decide to use the Script provider instead, please see Symphony's documentation [here](https://github.com/eclipse-symphony/symphony/blob/main/docs/symphony-book/providers/target-providers/script_provider.md) for more details. In this case, you'll need to mount your scripts into the Symphony container as a volume and configure your Target object with match paths.

## Prerequisites

* Any Linux or WSL2 on Windows
* Rust development environment, including rustc and cargo

## (Optional) Experiment with the mock provider

Before you start implementing your own Rust provider, it's beneficial to experiment with a prebuilt Symphony mock provider to get familiarized with the typical workflows of using a custom provider. We recommend going through this section first.

1. Launch Symphony via Docker Compose without the `-d` switch. This allows use to observe logs on the console:
```bash
# If you've launched Symphony via Docker Compose, use docker compose down to shut components down first
docker compose up
```
2. Run the `test_mock_provider.sh` script under the `samples/mock_provider` folder of this repo. Once the script runs, you should see some logs from the mock provider:
    ```bash
    symphony-api  | MOCK RUST PROVIDER: ------ get()
    ...
    symphony-api  | MOCK RUST PROVIDER: ------ apply()
    ```
    This means the mock provider is correctly loaded and used. 
3. (Optional) In a browser, navigate to http://localhost:3000/targets to see the created `mock-target` object.
4. The script pauses with a prompt: `Target registered. Press Enter to remove...`. Press `[Enter]` key to remove the Target object from Symphony.

In this case, we are using a single Symphony Target object to describe the desired state. You can view the Target definition in the `samples/mock_provider/target.json` file. Essentially, this file says "My desired state is a `mock-component` component to be running on my target device named `mock-target`, which uses a `providers.target.rust` provider to handle state reconcilation when it sees a `sample_type` component type." 

## Understanding Rust provider configuration

As shown in the `samples/mock_provider/target.json` sample, a Rust provider is configured by three properties: `name`, `libFile`, and `libHash`.
* **name**: A name of your choice
* **libFile**: Path to the complied Rust provider lib file. The Docker Compose file automatically mounts the `providers` folder as the `/extensions` folder. When you use your own providers, simply drop them to the `providers` folder on your local machine.
* **libHash**: To avoid loading arbitary binaries, Symphony requires a hash check before loading the provider.

> **NOTE**: You can use `hash256sum` to generate the hash: `hash256sum <your provider lib (.so) file>`

## Creating a new Rust provider
This section walks you through the steps of creating a new Rust Symphony Target provider named `my_provider`. If needed, you can view the code under `samples/my_provider_0` as a reference, as it was created following the exact steps.

### 1. Set up the Rust crate
1. Under `hpc_variant/samples` folder, create a new Rust project using `cargo`:

    ```bash
    cargo new my_provider --lib
    ```
2. Edit the `Cargo.toml` file under the newly created `hpc_variant/samples/my_provider` folder and add a reference to the [Symphony Rust crate](https://crates.io/crates/symphony). Also change the crate type to C dynamic library:

    ```toml
    [dependencies]
    symphony="0.1.4"

    [lib]
    crate-type=["cdylib"]

    ```

3. Replace the content of your `lib.rs` with this code:

    ```rust
    extern crate symphony;

    use symphony::models::{
        ProviderConfig, ValidationRule, DeploymentSpec, ComponentStep, ComponentSpec,
        DeploymentStep, ComponentResultSpec,
        ComponentValidationRule
    };
    use symphony::ITargetProvider;
    use symphony::ProviderWrapper;
    use std::collections::HashMap;
    
    pub struct MyProvider;

    #[unsafe(no_mangle)]
    pub extern "C" fn create_provider() -> *mut ProviderWrapper  {
        let provider: Box<dyn ITargetProvider> = Box::new(MyProvider {});
        let wrapper = Box::new(ProviderWrapper { inner: provider });
        Box::into_raw(wrapper)
    }

    impl ITargetProvider for MyProvider {
        fn get_validation_rule(&self) -> Result<ValidationRule, String> {
            Ok(ValidationRule::default())
        }
        fn get(&self, _deployment: DeploymentSpec, _references: Vec<ComponentStep>) -> Result<Vec<ComponentSpec>, String> {
            Ok(vec![])
        }
        fn apply(
            &self,
            _deployment: DeploymentSpec,
            _step: DeploymentStep,
            _is_dry_run: bool,
        ) -> Result<HashMap<String, ComponentResultSpec>, String> {
            Ok(HashMap::new())
        }
    }
    ```
4. Build your project to make sure everything is in place:
    ```bash
    cargo build
    ```
    👍 Great! Now you are ready to implement your provider!

    >**NOTE:** Ingore the ComponentValidationRule import warning for now.

### 2. Implement the `get()` method

Symphony periodically calls the `get()` method to retrieve the current system state. Since Symphony does not require a provider to maintain any state, it specifies the relevant deployment (via the `deployment: DeploymentSpec` parameter) and components (via the references: `Vec<ComponentStep> parameter`) it is interested in. Typically, you should iterate over the components in the references parameter and construct a `Vec<ComponentSpec>` array as the return value.

#### 2.1 Decide on what constitutes a `Component`

A Symphony `Solution` or `Target` consists of one or more `Components`. When a system integrates with Symphony, it can choose to represent its entire (relevant) system state as a single Symphony `Component` or expose a more granular construct. The choice of granularity depends on your specific use case. However, opting for finer granularity provides opportunities to leverage more Symphony features. For example, by treating your workload as separate `Components`, you can use Symphony's component dependency feature to ensure workloads are provisioned in the correct order.

In this walkthrough, we'll use a single `Component`. A Symphony `Component` consists of a name, a type, and a key-value property bag.

* Component **name**: A unique identifier within a Solution or a Target.
* Component **type**: An arbitrary string. However, for a specific system, it's best to use a consistent type string, such as `abc-workload`. Symphony uses this type string to identify the corresponding `TargetProvider` that claims to handle that component type.
* Component **properties**: A collection of key-value pairs that can store any relevant information. However, you must ensure that these properties can be reliably reconstructed when requested by Symphony. Symphony uses these properties—along with validation rules (covered in the next section)—to determine whether an update is required. If the property values are unstable, you may trigger constant reconciliations.

#### 2.2 Implement the `get()` method
In the current version, Symphony’s `ITargetProvider` is a synchronous interface. To access asynchronous APIs, you’ll need to create a asynchronous wrapper. For example:

```rust
fn get(
    &self,
    _deployment: DeploymentSpec,
    _references: Vec<ComponentStep>,
) -> Result<Vec<ComponentSpec>, String> {
    self.runtime.block_on(self.async_get(_deployment, _references))
}
```

Then, you can implement your asynchronous `get()` method. For more detailed example, please see the `aync_get()` method in `api/pkg/apis/v1alpha1/providers/target/rust/rust_providers/ankaios/src/lib.rs`.

#### 2.3. Testing the `get()` method

Before we move forward, let's make sure the `get()` method is working as expected. If your system is directly testable from your local environment, we recommend you writing a test case in your `lib.src` file to test the `get()` method:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use symphony::models::{DeploymentSpec};

    #[test]
    fn test_get() {
        let provider = MyProvider {          
        };

        let deployment = DeploymentSpec::empty();
        let references = vec![];

        let result = provider.get(deployment, references);
        assert!(result.is_ok(), "Expected Ok result, but got {:?}", result);
    }
}
```

#### 2.4 Implementing the `apply()` method

The `apply()` method applies the new desired state to the system. Symphony sends the current deployment (`DeploymentSpec`) that contains all information about the current `Solution` and `Targets`. It also sends the current deployment step (`DeploymentStep`) that contains the current operations the provider needs to do, i.e. updating components or deleting components. Most provider only need to access the deployment step parameter, while some providers may need to consult the whole deployment object for additional context.
When handling the deployment step, your provider should loop through the step components and perform corresponding actions, such as:

```rust
for component in step.components.iter() {
    if component.action == ComponentAction::Delete {
        // delete the component
    } else if component.action == ComponentAction::Update {
        // create or update the component
    }
}
```

For each operated component, you should return a `ComponentResultSpec` indicating the operation result:

```rust
let component_result = ComponentResultSpec {
    status: State::OK,
    message: "Component applied successfully".to_string(),
};
result.insert(component.component.name.clone(), component_result);
// failure
let component_result = ComponentResultSpec {
    status: State::InternalError,
    message: format!("Failed to apply workload: {:?}", e),
};
```
## Deploy your provider to Symphony
To deploy your provider, copy the compiled `.so` file into Symphony’s `extensions` folder. If you are using the Docker Compose file provided in this repository, the `hpc_variant/providers` folder is automatically mounted as Symphony’s `extensions` folder. Simply place the .so file there. Note that you may need to restart your Docker Compose deployment for the new file to be recognized inside the container.

To use your provider in a Target definition, you'll need the hash code:
```bash
hash256sum <your provider .so file>
```

Then, enter that hash into your provider configuration, for example:

```json
 "config": {
    "name": "my-lib",
    "libFile": "/extensions/libmy_provider.so",
    "libHash": "eee8fd7..."
}
```
You can use `samples/my_provider/target.json` as a reference.

## Test your provider
Similar with testing the mock provider, you can use the `samples/my_provider/test_my_provider.sh` script to create and then destroy a Target and observe what the prvoider does via logs.
