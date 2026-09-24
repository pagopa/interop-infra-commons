# ArgoCD Local Testing Setup

Questa cartella contiene la configurazione per testare il modulo ArgoCD su un cluster `kind` locale senza dipendenze AWS.

## Directory Structure

```
├── scripts/
│   ├── setup-kind-only.sh        # Crea cluster kind e build immagini plugin
│   └── teardown-kind-cluster.sh  # Elimina cluster kind
└── terraform-with-mocks/
    ├── main.tf                   # Configurazione root
    ├── variables.tf              # Variabili input
    ├── outputs.tf                # Output
    ├── local-overrides.yaml      # Override risorse per kind
    └── README.md                 # Guida dettagliata
```

## Quick Start

### 1. Setup Cluster e Plugin

Lo script `setup-kind-only.sh` può essere eseguito da qualsiasi directory:

```bash
# Da scripts/
./scripts/setup-kind-only.sh

# Oppure da parent directory
./scripts/setup-kind-only.sh

# Oppure da terraform-with-mocks/
../scripts/setup-kind-only.sh
```

Lo script:
- ✅ Verifica i prerequisiti (docker, kubectl, kind)
- ✅ Crea cluster kind `argocd-test`
- ✅ Configura context kubectl
- ✅ **Buildare le immagini Docker dei plugin**
- ✅ Carica le immagini nel cluster kind

### 2. Deploy ArgoCD

```bash
cd terraform-with-mocks/
terraform init
terraform plan
terraform apply -auto-approve
```

### 3. Accedi a ArgoCD

```bash
# Port-forward al servizio
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Credenziali:
# Username: admin
# Password: (vedi output terraform: argocd_initial_password)

# Accedi a: https://localhost:8080
```

### 4. Cleanup

```bash
# Elimina il cluster
../scripts/teardown-kind-cluster.sh

# Oppure
./teardown-kind-cluster.sh (se in parent directory)
```

## Troubleshooting

### Le immagini plugin non vengono buildiate

Verifica che:
1. Docker sia in esecuzione: `docker ps`
2. Il percorso verso i Dockerfile sia corretto dal punto di esecuzione
3. Lo script sia eseguibile: `chmod +x scripts/setup-kind-only.sh`

### Terraform non trova le immagini

Se `terraform apply` fallisce per missing images, esegui lo script di setup:

```bash
./scripts/setup-kind-only.sh
```

Se sei in `terraform-with-mocks/`:

```bash
../scripts/setup-kind-only.sh
```

### Visualizzare i pod

```bash
kubectl get pods -n argocd
kubectl get pods -n argocd -o wide
```

Verifica che `repo-server` abbia 3/3 container (main + 2 plugin sidecars).

## Note

- Le immagini vengono buildiate con tag `:local` e caricate solo nel cluster kind (non in registry)
- Ogni volta che modifichi i Dockerfile, lo script ribuilderà le immagini
- I valori Helm sono caricati da `local-overrides.yaml` che disabilita dipendenze AWS
