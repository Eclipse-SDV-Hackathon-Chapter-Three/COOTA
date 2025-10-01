extern crate symphony;

use symphony::models::{
    ProviderConfig, ValidationRule, DeploymentSpec, ComponentStep, ComponentSpec,
    DeploymentStep, ComponentResultSpec, State, ComponentAction,
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
        println!("MY RUST PROVIDER: ------ get_validation_rule()");
        Ok(ValidationRule::default())
    }
    fn get(&self, _deployment: DeploymentSpec, _references: Vec<ComponentStep>) -> Result<Vec<ComponentSpec>, String> {
        println!("MY RUST PROVIDER: ------ get()");
        Ok(vec![])
    }
    fn apply(
        &self,
        _deployment: DeploymentSpec,
        step: DeploymentStep,
        _is_dry_run: bool,
    ) -> Result<HashMap<String, ComponentResultSpec>, String> {
        println!("MY RUST PROVIDER: ------ apply()");
        let mut result: HashMap<String, ComponentResultSpec> = HashMap::new();
        for component in step.components.iter() {
            if component.action == ComponentAction::Update {
                println!("Applying component: {:?}", component.component);
                let component_result = ComponentResultSpec {
                    status: State::OK,
                    message: "Component applied successfully".to_string(),
                };
                result.insert(component.component.name.clone(), component_result);
                // failure
                // let component_result = ComponentResultSpec {
                //    status: State::InternalError,
                //    message: format!("Failed to apply workload: {:?}", e),
                //};
            } else if component.action == ComponentAction::Delete {
                // delete the component
            }
        }
        Ok(result)
    }
}

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