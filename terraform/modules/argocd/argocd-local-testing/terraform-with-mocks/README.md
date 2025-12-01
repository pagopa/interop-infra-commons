# ArgoCD Module - Local Testing with Mocks

Questa directory contiene una configurazione Terraform per testare il modulo ArgoCD (`../../`) in ambiente locale utilizzando un cluster kind, senza dipendenze da risorse AWS reali.

## Indice

- [Panoramica](#panoramica)
- [Prerequisiti](#prerequisiti)
- [Setup Iniziale](#setup-iniziale)
- [File e Struttura](#file-e-struttura)
- [Scelte Architetturali](#scelte-architetturali)
- [Istruzioni di Test](#istruzioni-di-test)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## Panoramica

Questo test dimostra come utilizzare il modulo ArgoCD in modalità "AWS-optional", bypassando le dipendenze da EKS e AWS Secrets Manager attraverso l'uso di variabili di override. Il deployment avviene su un cluster kind locale con plugin ArgoCD personalizzati caricati come sidecar containers.

### Cosa viene testato

- ✅ Deployment del modulo ArgoCD senza credenziali AWS
- ✅ Generazione locale delle credenziali admin con bcrypt
- ✅ Build e caricamento di immagini Docker personalizzate (plugin) in kind
- ✅ Configurazione di plugin ArgoCD come sidecar containers
- ✅ Override delle risorse per compatibilità con kind (limiti di memoria ridotti) e per testare la possibiltà di sovrascrivere valori di default di ArgoCD
- ✅ Namespace management e service discovery

## Prerequisiti

Assicurati di avere installato i seguenti tool:

```bash
# Docker (richiesto da kind)
docker --version  # >= 20.10

# kubectl
kubectl version --client  # >= 1.26

# kind (Kubernetes in Docker)
kind version  # >= 0.20

# Terraform
terraform version  # >= 1.8.0

# Helm (opzionale, per debug)
helm version  # >= 3.12
```

## Setup Iniziale

```bash
cd /path/to/interop-infra-commons
./scripts/setup-kind-only.sh
```

Questo script:
- Verifica i prerequisiti (docker, kubectl, kind)
- Crea un cluster kind chiamato `argocd-test`
- Configura port mappings per 80, 443 e 8080
- Imposta il context kubectl su `kind-argocd-test`

**Output atteso:**
```
✅ Docker is installed
✅ kubectl is installed
✅ kind is installed
Creating kind cluster 'argocd-test'...
Creating cluster "argocd-test" ...
✅ Cluster created successfully
```

### 2. Verificare il Cluster

```bash
kubectl cluster-info --context kind-argocd-test
kubectl get nodes
```

**Output atteso:**
```
NAME                        STATUS   ROLES           AGE   VERSION
argocd-test-control-plane   Ready    control-plane   30s   v1.27.x
```

### 3. Preparare i Plugin Docker

Assicurati che i Dockerfile dei plugin esistano (pwd == /path/to/argocd-local-testing):

```bash
ls -la ../../../../argocd/plugins/microservices/Dockerfile
ls -la ../../../../argocd/plugins/cronjobs/Dockerfile
```

## File e Struttura

```
terraform-with-mocks/
├── README.md                    # Questo file
├── main.tf                      # Configurazione principale
├── variables.tf                 # Variabili di input
├── outputs.tf                   # Output del modulo
├── local-overrides.yaml         # Valori usati per l'override dei default del modulo
├── .terraform/                  # Directory Terraform (auto-generata)
├── terraform.tfstate            # State file (auto-generato)
└── terraform.tfstate.backup     # Backup dello state (auto-generato)
```

### main.tf

**Scopo:** Configurazione root che orchestra il deployment del modulo ArgoCD.

**Sezioni principali:**

1. **Terraform Block**
   ```hcl
   terraform {
     required_version = ">= 1.8.0"
     required_providers {
       kubernetes = "~> 2.18.1"
       helm       = "~> 2.9.0"
       aws        = "~> 5.33.0"  # Dichiarato ma non usato
       random     = "~> 3.5.0"
       null       = "~> 3.2.0"
     }
   }
   ```

2. **Provider Configuration**
   ```hcl
   provider "kubernetes" {
     config_path    = "~/.kube/config"
     config_context = "kind-argocd-test"
   }
   
   provider "helm" {
     kubernetes {
       config_path    = "~/.kube/config"
       config_context = "kind-argocd-test"
     }
   }
   ```
   - **Nota:** I provider AWS non sono configurati perché non utilizzati grazie agli override

3. **Password Generation**
   ```hcl
   resource "random_password" "argocd_admin" {
     length  = 30
     special = true
   }
   ```
   - Genera password random per l'admin di ArgoCD
   - Viene hashata con bcrypt nel blocco "module"

4. **Plugin Image Build**
   ```hcl
   resource "null_resource" "build_and_load_plugin_images" {
     triggers = {
       microservices_dockerfile = filemd5("../../argocd/plugins/microservices/Dockerfile")
       cronjobs_dockerfile      = filemd5("../../argocd/plugins/cronjobs/Dockerfile")
     }
     
     provisioner "local-exec" {
       command = <<-EOT
         docker build -t argocd-plugin-microservices:local ../../argocd/plugins/microservices
         docker build -t argocd-plugin-cronjobs:local ../../argocd/plugins/cronjobs
         kind load docker-image argocd-plugin-microservices:local --name argocd-test
         kind load docker-image argocd-plugin-cronjobs:local --name argocd-test
       EOT
     }
   }
   ```
   - **Trigger:** Rebuilds quando i Dockerfile cambiano (via MD5 hash)
   - **Build:** Crea immagini Docker locali con tag `:local`
   - **Load:** Carica le immagini nel cluster kind (non usa registry)

5. **Module Call**
   ```hcl
   module "argocd" {
     source = "../../"
     
     # AWS bypass via override
     argocd_admin_bcrypt_password = bcrypt(random_password.argocd_admin.result)
     argocd_admin_password_mtime  = timestamp()
     
     # Plugin configuration
     microservices_plugin_image_name   = "argocd-plugin-microservices"
     microservices_plugin_image_tag    = "local"
     microservices_plugin_image_prefix = ""  # Empty = no registry prefix
     
     # Resource overrides for kind
     controller_resources = {
       requests = { cpu = "100m", memory = "256Mi" }
       limits   = { cpu = "500m", memory = "512Mi" }
     }
     # ... altri override ...
   }
   ```

### variables.tf

**Scopo:** Definisce le variabili configurabili per il test.

**Variabili chiave:**

- `aws_region`: Regione AWS (non usata, ma richiesta dal modulo)
- `env`: Environment name (default: "local")
- `argocd_namespace`: Namespace per ArgoCD (default: "argocd")
- `argocd_chart_version`: Versione Helm chart (default: "9.1.0")
- Credenziali repository (opzionali, per test con repo privati)

### outputs.tf

**Scopo:** Espone informazioni utili post-deployment.

**Output disponibili:**

```hcl
output "argocd_namespace" {
  description = "Namespace dove ArgoCD è deployato"
  value       = module.argocd.argocd_namespace
}

output "argocd_server_url" {
  description = "URL interno del server ArgoCD"
  value       = module.argocd.argocd_server_url
}

output "argocd_admin_username" {
  description = "Username admin ArgoCD"
  value       = module.argocd.argocd_admin_username
}

output "argocd_admin_password" {
  description = "Password admin ArgoCD (generata localmente)"
  value       = random_password.argocd_admin.result
  sensitive   = true
}
```

**Visualizzare gli output:**
```bash
terraform output
terraform output -raw argocd_admin_password  # Mostra password in chiaro
```

### local-overrides.yaml

**Stato:** Non utilizzato nel deployment corrente.

**Motivo:** Terraform `merge()` esegue solo shallow merge (1 livello), non deep merge ricorsivo. Quando si prova a fare merge di questo file con i defaults, le sezioni `extraContainers`, `volumes` e altre configurazioni complesse vengono sovrascritte completamente invece di essere unite.

**Soluzione adottata:** Override tramite variabili Terraform e dynamic `set` blocks nel modulo.

**Mantenuto per:** Riferimento e documentazione delle risorse ridotte per kind.

## Scelte Architetturali

### 1. Modulo AWS-Optional

**Problema:** Il modulo ArgoCD originale dipende da EKS e Secrets Manager.

**Soluzione:** Aggiunte variabili optional al modulo:
- `argocd_admin_bcrypt_password` (string, default null)
- `argocd_admin_password_mtime` (string, default null)

**Logica:**
```hcl
# In 02-secrets.tf del modulo
resource "aws_secretsmanager_secret_version" "argocd_admin_password" {
  count = var.deploy_argocd && var.argocd_admin_bcrypt_password == null ? 1 : 0
  # ... solo se override == null
}

# In 03-argocd-instance.tf del modulo
set {
  name  = "configs.secret.argocdServerAdminPassword"
  value = var.argocd_admin_bcrypt_password != null ? 
          var.argocd_admin_bcrypt_password : 
          aws_secretsmanager_secret_version.argocd_admin_password[0].secret_string
}
```

### 2. Image Path Construction

**Scopo:** Supportare immagini plugin sia da registry pubblici/privati che locali.

**Implementazione:** Il modulo costruisce il path completo dell'immagine in modo flessibile gestendo registry prefix opzionali.

Quando `microservices_plugin_image_prefix` è valorizzato (es. `"ghcr.io/pagopa"`), il path risultante sarà `ghcr.io/pagopa/argocd-plugin-microservices:v1.0.0`.

Quando `microservices_plugin_image_prefix` è vuoto (caso locale con kind), il path risultante sarà `argocd-plugin-microservices:local` senza slash iniziale.

**Logica implementativa (01-locals.tf):**
```hcl
locals {
  microservices_plugin_image = var.microservices_plugin_image_prefix != "" ? 
    "${var.microservices_plugin_image_prefix}/${var.microservices_plugin_image_name}:${var.microservices_plugin_image_tag}" : 
    "${var.microservices_plugin_image_name}:${var.microservices_plugin_image_tag}"
}
```

**Vantaggio:** Questa logica condizionale permette di usare lo stesso modulo sia per deployments in ambienti cloud (con registry ECR/ACR/GCR) che per testing locale (con immagini caricate direttamente in kind).

### 3. Resource Override via Dynamic Set Blocks

**Problema:** YAML merge non funziona per strutture complesse.

**Tentativo fallito:**
```hcl
# ❌ Shallow merge perde extraContainers
values = yamlencode(merge(
  local.default_values,
  yamldecode(file("local-overrides.yaml"))
))
```

**Soluzione:** Dynamic `set` blocks in helm_release (03-argocd-instance.tf):
```hcl
# Override controller resources
dynamic "set" {
  for_each = var.controller_resources != null ? [1] : []
  content {
    name  = "controller.resources.requests.cpu"
    value = var.controller_resources.requests.cpu
  }
}
# ... 24 set blocks totali (4 componenti × 6 campi)
```

**Vantaggio:** Override granulare senza perdere altre configurazioni.

### 4. Plugin Sidecar Injection

**Pattern:** ArgoCD Config Management Plugin (CMP) come sidecar containers.

**Implementazione:** Nel file defaults/argocd-cm-values.yaml:
```yaml
repoServer:
  extraContainers:
    - name: argocd-plugin-microservices
      image: ${microservices_plugin_image}  # Variabile template
      command: [/var/run/argocd/argocd-cmp-server]
      volumeMounts: [...]
      env: [...]
```

**Risultato:** repo-server pod con 3 containers:
1. `repo-server` (main)
2. `argocd-plugin-microservices` (sidecar)
3. `argocd-plugin-cronjobs` (sidecar)

## Istruzioni di Test

### Fase 1: Inizializzazione Terraform

```bash
cd terraform/modules/argocd/argocd-local-testing/terraform-with-mocks

# Inizializza Terraform
terraform init
```

**Output atteso:**
```
Initializing modules...
Initializing provider plugins...
- Reusing previous version of hashicorp/kubernetes from the dependency lock file
- Reusing previous version of hashicorp/helm from the dependency lock file
...
Terraform has been successfully initialized!
```

### Fase 2: Plan

```bash
terraform plan
```

**Verifica:**
- ✅ Plan should add **5 resources** (namespace, secret, helm_release, random_password, null_resource), 0 to change, 0 to destroy.
- ✅ Nessun errore di autenticazione AWS
- ✅ Module call mostra override variables

**Esempio output:**
```
Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + argocd_admin_password = (sensitive value)
  + argocd_admin_username = "admin"
  + argocd_namespace      = "argocd"
  + argocd_server_url     = "https://argocd-server.argocd.svc.cluster.local"
```

### Fase 3: Apply

```bash
terraform apply
```

Quando richiesto, digita `yes`.

**Durata:** ~2-3 minuti (include Docker build, kind load, Helm install)

**Fasi visibili:**
1. Building plugin images (null_resource)
2. Generating admin password (random_password)
3. Creating namespace (kubernetes_namespace)
4. Creating secret (kubernetes_secret)
5. Installing ArgoCD chart (helm_release)

### Fase 4: Verifica Deployment

#### 4.1 Verificare i Pod

```bash
kubectl get pods -n argocd
```

**Output atteso (7 pods Running):**
```
NAME                                               READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                    1/1     Running   0          2m
argocd-applicationset-controller-xxxxxxxxx-xxxxx   1/1     Running   0          2m
argocd-dex-server-xxxxxxxxx-xxxxx                  1/1     Running   0          2m
argocd-notifications-controller-xxxxxxxxx-xxxxx    1/1     Running   0          2m
argocd-redis-xxxxxxxxx-xxxxx                       1/1     Running   0          2m
argocd-repo-server-xxxxxxxxx-xxxxx                 3/3     Running   0          2m  ← 3 containers!
argocd-server-xxxxxxxxx-xxxxx                      1/1     Running   0          2m
```

**Nota importante:** `argocd-repo-server` deve avere **3/3** containers (main + 2 plugin sidecars).

#### 4.2 Verificare i Container del Repo Server

```bash
kubectl get pod -n argocd -l app.kubernetes.io/component=repo-server -o jsonpath='{.items[0].spec.containers[*].name}' | tr ' ' '\n'
```

**Output atteso:**
```
repo-server
argocd-plugin-microservices
argocd-plugin-cronjobs
```

#### 4.3 Verificare le Immagini dei Plugin

```bash
kubectl get pod -n argocd -l app.kubernetes.io/component=repo-server -o jsonpath='{.items[0].spec.containers[*].image}' | tr ' ' '\n'
```

**Output atteso:**
```
quay.io/argoproj/argocd:v3.x.x
argocd-plugin-microservices:local
argocd-plugin-cronjobs:local
```

#### 4.4 Verificare le Risorse Allocate

```bash
kubectl describe pod -n argocd -l app.kubernetes.io/component=repo-server | grep -A 2 "Limits:"
```

**Output atteso:**
```
    Limits:
      cpu:     500m
      memory:  512Mi
```

### Fase 5: Accesso alla UI

#### 5.1 Port Forward

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### 5.2 Recuperare la Password

```bash
terraform output -raw argocd_admin_password
```

#### 5.3 Login

Apri il browser su: https://localhost:8080

- **Username:** `admin`
- **Password:** (output del comando precedente)

**Nota:** Accetta il certificato self-signed (⚠️ Warning nel browser).

### Fase 6: Test Funzionale (Opzionale)

#### 6.1 Creare un'Applicazione di Test

```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

#### 6.2 Verificare il Sync

Nella UI, dovresti vedere l'applicazione `test-app` che si sincronizza automaticamente.

```bash
kubectl get application -n argocd test-app
```

## Troubleshooting

### Pod in CrashLoopBackOff

**Sintomo:** `argocd-repo-server` o altri pod crashano.

**Causa probabile:** Memoria insufficiente.

**Soluzione:**
```bash
# Verifica risorse del nodo
kubectl top nodes

# Verifica pod OOMKilled
kubectl get events -n argocd --sort-by='.lastTimestamp' | grep OOM
```

**Fix:** Riduci ulteriormente i limiti di memoria nel `main.tf`.

### Plugin Container Mancante

**Sintomo:** `argocd-repo-server` ha solo 1/1 containers invece di 3/3.

**Causa probabile:** Immagini non caricate in kind o values YAML sovrascritto.

**Debug:**
```bash
# Verifica immagini in kind
docker exec -it argocd-test-control-plane crictl images | grep plugin

# Verifica values Helm
helm get values argocd -n argocd
```

**Fix:** Riesegui `terraform apply` per rebuilddare e ricaricare le immagini.

### Errore "invalid reference format"

**Sintomo:** Helm release fallisce con `invalid reference format: /argocd-plugin-...`.

**Causa:** `microservices_plugin_image_prefix` è una stringa vuota, creando `"" + "/" + name`.

**Fix:** Verifica che il modulo usi la logica condizionale in `01-locals.tf`:
```hcl
microservices_plugin_image = var.microservices_plugin_image_prefix != "" ? 
  "${var.microservices_plugin_image_prefix}/${var.microservices_plugin_image_name}:${var.microservices_plugin_image_tag}" : 
  "${var.microservices_plugin_image_name}:${var.microservices_plugin_image_tag}"
```

### Context deadline exceeded

**Sintomo:** Timeout durante terraform apply.

**Causa:** Cluster kind lento o risorse insufficienti.

**Soluzione:**
```bash
# Aumenta timeout nel modulo (03-argocd-instance.tf)
timeout = 900  # 15 minuti invece di 300

# Oppure aumenta risorse Docker
# Docker Desktop → Preferences → Resources → Memory: 8GB
```

### ArgoCD UI non accessibile

**Sintomo:** Port-forward funziona ma browser mostra errore.

**Debug:**
```bash
# Verifica service
kubectl get svc -n argocd argocd-server

# Verifica endpoint
kubectl get endpoints -n argocd argocd-server

# Verifica logs
kubectl logs -n argocd -l app.kubernetes.io/component=server
```

**Fix comune:** Aspetta 1-2 minuti che i pod siano completamente Ready.

## Cleanup

### Rimuovere ArgoCD

```bash
terraform destroy
```

Quando richiesto, digita `yes`.

**Cosa viene rimosso:**
- Helm release ArgoCD
- Kubernetes secret
- Kubernetes namespace
- Random password (dallo state)
- Null resource triggers

**Cosa NON viene rimosso:**
- Immagini Docker locali (rimangono in kind)
- Cluster kind (deve essere eliminato manualmente)

### Rimuovere il Cluster kind

```bash
kind delete cluster --name argocd-test
```

### Rimuovere Immagini Docker (Opzionale)

```bash
docker rmi argocd-plugin-microservices:local
docker rmi argocd-plugin-cronjobs:local
```

### Cleanup Completo

```bash
# Destroy Terraform
cd terraform/modules/argocd/argocd-local-testing/terraform-with-mocks
terraform destroy -auto-approve

# Delete kind cluster
kind delete cluster --name argocd-test

# Remove Docker images
docker rmi argocd-plugin-microservices:local argocd-plugin-cronjobs:local

# Reset kubectl context
kubectl config use-context <default-context>
```