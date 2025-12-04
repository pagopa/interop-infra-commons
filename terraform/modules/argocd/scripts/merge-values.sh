#!/bin/bash
#
# merge-values.sh
# Script per mergiare due file YAML usando yq
# Riceve i parametri tramite variabili d'ambiente da terraform_data
#
# Variabili attese:
#   BASE_FILE      - contenuto base YAML (base64 encoded)
#   OVERRIDE_FILE  - path al file YAML di override
#

set -euo pipefail

# Leggi le variabili d'ambiente
base_file="${BASE_FILE}"
override_file="${OVERRIDE_FILE}"
output_format="yaml"

# Verifica che il file di override esista
if [[ ! -f "$override_file" ]]; then
  echo "Error: Override file not found: $override_file" >&2
  exit 1
fi

# Verifica che yq sia disponibile
if ! which yq > /dev/null 2>&1; then
  echo "Error: yq is not installed" >&2
  exit 1
fi

# Crea file temporaneo per il file base decodificato
TEMP_BASE=$(mktemp)
# Rimuovi il file temporaneo alla fine dello script
trap "rm -f '$TEMP_BASE'" EXIT

echo "$base_file" | base64 -d > "$TEMP_BASE"

# Esegui il deep merge con yq e restituisci come YAML
yq eval-all "select(filename == \"$TEMP_BASE\") * select(filename == \"$override_file\")" "$TEMP_BASE" "$override_file" -o "${output_format}"
