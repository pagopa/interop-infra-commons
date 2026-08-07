# External Secrets Lister

Node.js scripts to list all `externalSecrets` defined in the `values.yaml` file from microservices and jobs and a specific environment.

## Install

```bash
npm install js-yaml
```

## Usage

```bash
node list-external-secrets.js <env> <project-root-path>
```

### Parameters

- `<env>`: Environment to analyze (es. `dev-experimental-argocd-interop-apps-post-sync-hook`)
- `<project-root-path>`: Root path of the current proejct (es. `/Users/username/Documents/repo/interop/interop-core-deployment`)

### Example

```bash
node list-external-secrets.js dev-experimental-argocd-interop-apps-post-sync-hook /Users/username/Documents/repo/interop/interop-core-deployment
```

## Output

This script:
1. **Scan** all the directories in `microservices/` e `jobs/` folders
2. **Search** for `values.yaml` files in the directories corresponding to the selected environment
3. **Extract** all the `externalSecrets.data[]` sections with the configuration defined in the `value.yaml`:
   - `secretKey`
   - `remoteRef.key`
   - `remoteRef.property`
   - `remoteRef.version`
   - `remoteRef.conversionStrategy`
   - `remoteRef.decodingStrategy`
4. **Show** results in a table
5. **Export** a CSV and a JSON with all the findings
6. **Update** `values.yaml` files with the latest version found on AWS Secrets Manager for listed secrets 

## Struttura cercata

This script searches for YAML files with this structure:

```yaml
externalSecrets:
  data:
    - secretKey: username
      remoteRef:
        key: /path/to/secret
        property: username
        version: v1
        conversionStrategy: Default
        decodingStrategy: None
    - secretKey: password
      remoteRef:
        key: /path/to/secret
        property: password
        version: v1
```
