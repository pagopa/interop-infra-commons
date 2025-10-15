# interop-infra-commons
This repository includes common scripts and modules that are referenced by external repositories. 

## Terraform modules
To use a Terraform module from the current repository, an external repository must have access to it.

Once access is established, the external repository can reference a specific Terraform module from the current repo by defining the _source_ field as follows:

```
module "example" {
  source = "git::https://github.com/pagopa/interop-infra-commons//[PATH_TO_MODULE]?ref=[BRANCH_NAME/TAG]"
  ...
}
```

⚠️ it's highly recommended to pin the module to a tag (currently commit hashes are not supported by Terraform).

## Licensing

This project is licensed under the terms of the **Mozilla Public License Version 2.0 (MPL-2.0)**.
The full text of the license can be found in the [LICENSE](LICENSE) file.
Please see the [AUTHORS](AUTHORS) file for the copyright notice.
