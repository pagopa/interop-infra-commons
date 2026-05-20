# Pre-commit configuration for Terraform code formatting and validation used locally.
minimum_pre_commit_version: "4"
fail_fast: false
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.105.0
    hooks:
      - id: terraform_fmt
        name: Terraform fmt
        #files: \.(tf|tfvars)$
        files: ^__TERRAFORM_ROOT__/.*\.(tf|tfvars)$
        args:
          - --args=-check
          - --args=-diff
          - --args=-recursive
          - --args=-write=false

      - id: terraform_validate
        name: Terraform validate
        #files: \.tf$
        files: ^__TERRAFORM_ROOT__/.*\.(tf)$
        args:
          - --args=-no-color
          - --tf-init-args=-backend=false
          - --tf-init-args=-input=false
          - --tf-init-args=-no-color
          - --hook-config=--parallelism-limit=1
          __TERRAFORM_LOCKFILE_ARG__

      - id: terraform_tflint
        name: Terraform TFLint
        #files: \.tf$
        files: ^__TERRAFORM_ROOT__/.*\.(tf)$
        args:
          - --args=--format=compact
          - --args=--no-color
          - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl