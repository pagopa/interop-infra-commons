# PDND Interoperability
# Infrastructure common resources

This repository includes common scripts and modules that are referenced by infrastructure repositories for PDND Interoperability.

About the project:

[PDND Interoperability landing page](https://interop.pagopa.it)

[Operating Manual](https://developer.pagopa.it/pdnd-interoperabilita/guides/PDND-Interoperability-Operating-Manual)

## Terraform modules
Common Terraform modules can be referenced by defining the _source_ field as follows:

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
