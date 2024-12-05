# interop-infra-commons
This repository includes common scripts and modules that are referenced by external repositories. 

## External repositories
To use a Terraform module from the current repository, an external repository must have access to it.

Once access is established, the external repository can reference a specific Terraform module from the current repo by defining the _source_ field as follows:

```
module "example" {
  source = "git::https://github.com/pagopa/interop-infra-commons//[PATH_TO_MODULE]?ref=[BRANCH_NAME/TAG]"
  ...
}
```