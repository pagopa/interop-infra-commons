#!/bin/bash
#
# test-merge-values.sh
# Test suite per lo script merge-values.sh
#

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Lo script merge-values.sh è nel modulo principale (6 livelli su)
# test/terraform/modules/argocd/scripts -> terraform/modules/argocd/scripts
MERGE_SCRIPT="$(cd "${SCRIPT_DIR}/../../../../../terraform/modules/argocd/scripts" && pwd)/merge-values.sh"

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contatori
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Funzioni di utilità
print_test() {
  printf "${YELLOW}TEST $((TESTS_RUN + 1)):${NC} %s\n" "$1"
}

print_pass() {
  printf "${GREEN}✓ PASS${NC}\n"
  ((TESTS_PASSED++))
}

print_fail() {
  printf "${RED}✗ FAIL${NC} %s\n" "$1"
  ((TESTS_FAILED++))
}

run_test() {
  ((TESTS_RUN++))
}

# Setup: crea file temporanei per i test
setup() {
  TEST_DIR=$(mktemp -d)
  BASE_FILE="${TEST_DIR}/base.yaml"
  OVERRIDE_FILE="${TEST_DIR}/override.yaml"
  export TEST_DIR BASE_FILE OVERRIDE_FILE
}

# Cleanup: rimuovi file temporanei
cleanup() {
  rm -rf "${TEST_DIR:-}"
}

# Test 1: Merge base
test_basic_merge() {
  run_test
  print_test "Merge base - valori non sovrapposti"
  
  cat > "$BASE_FILE" <<'YAML'
app:
  name: myapp
  version: 1.0.0
YAML

  cat > "$OVERRIDE_FILE" <<'YAML'
app:
  environment: production
YAML

  BASE_CONTENT=$(base64 < "$BASE_FILE")
  OUTPUT=$(BASE_FILE="$BASE_CONTENT" OVERRIDE_FILE="$OVERRIDE_FILE" "$MERGE_SCRIPT" 2>&1) || true
  
  if echo "$OUTPUT" | grep -q "name: myapp" && \
     echo "$OUTPUT" | grep -q "version: 1.0.0" && \
     echo "$OUTPUT" | grep -q "environment: production"; then
    print_pass
  else
    print_fail "Output non contiene tutti i valori attesi"
  fi
}

# Test 2: Override di valori esistenti
test_override_values() {
  run_test
  print_test "Override di valori esistenti"
  
  cat > "$BASE_FILE" <<'YAML'
server:
  replicas: 1
  cpu: 100m
  memory: 128Mi
YAML

  cat > "$OVERRIDE_FILE" <<'YAML'
server:
  replicas: 3
  cpu: 500m
YAML

  BASE_CONTENT=$(base64 < "$BASE_FILE")
  OUTPUT=$(BASE_FILE="$BASE_CONTENT" OVERRIDE_FILE="$OVERRIDE_FILE" "$MERGE_SCRIPT" 2>&1) || true
  
  if echo "$OUTPUT" | grep -q "replicas: 3" && \
     echo "$OUTPUT" | grep -q "cpu: 500m" && \
     echo "$OUTPUT" | grep -q "memory: 128Mi"; then
    print_pass
  else
    print_fail "Override non applicato correttamente"
  fi
}

# Test 3: Deep merge con strutture annidate
test_deep_merge() {
  run_test
  print_test "Deep merge con strutture annidate"
  
  cat > "$BASE_FILE" <<'YAML'
config:
  database:
    host: localhost
    port: 5432
    credentials:
      user: admin
      password: secret
  cache:
    enabled: true
YAML

  cat > "$OVERRIDE_FILE" <<'YAML'
config:
  database:
    host: prod-db.example.com
    credentials:
      user: prod_user
YAML

  BASE_CONTENT=$(base64 < "$BASE_FILE")
  OUTPUT=$(BASE_FILE="$BASE_CONTENT" OVERRIDE_FILE="$OVERRIDE_FILE" "$MERGE_SCRIPT" 2>&1) || true
  
  if echo "$OUTPUT" | grep -q "host: prod-db.example.com" && \
     echo "$OUTPUT" | grep -q "port: 5432" && \
     echo "$OUTPUT" | grep -q "user: prod_user" && \
     echo "$OUTPUT" | grep -q "password: secret" && \
     echo "$OUTPUT" | grep -q "enabled: true"; then
    print_pass
  else
    print_fail "Deep merge non preserva tutti i valori"
  fi
}

# Test 4: File override minimo
test_empty_override() {
  run_test
  print_test "File override con una chiave (no conflict)"
  
  cat > "$BASE_FILE" <<'YAML'
app:
  name: test
  version: 1.0.0
YAML

  cat > "$OVERRIDE_FILE" <<'YAML'
other:
  setting: value
YAML

  BASE_CONTENT=$(base64 < "$BASE_FILE")
  OUTPUT=$(BASE_FILE="$BASE_CONTENT" OVERRIDE_FILE="$OVERRIDE_FILE" "$MERGE_SCRIPT" 2>&1) || true
  
  if echo "$OUTPUT" | grep -q "name: test" && \
     echo "$OUTPUT" | grep -q "version: 1.0.0" && \
     echo "$OUTPUT" | grep -q "setting: value"; then
    print_pass
  else
    print_fail "Merge non corretto con override minimo"
  fi
}

# Test 5: Errore - file override non esistente
test_missing_override_file() {
  run_test
  print_test "Errore - file override non esistente"
  
  cat > "$BASE_FILE" <<'YAML'
app:
  name: test
YAML

  BASE_CONTENT=$(base64 < "$BASE_FILE")
  
  if BASE_FILE="$BASE_CONTENT" OVERRIDE_FILE="/non/existent/file.yaml" "$MERGE_SCRIPT" 2>/dev/null; then
    print_fail "Script dovrebbe fallire con file non esistente"
  else
    print_pass
  fi
}

# Test 6: Preservazione tipi YAML
test_type_preservation() {
  run_test
  print_test "Preservazione tipi YAML (numeri, stringhe, bool)"
  
  cat > "$BASE_FILE" <<'YAML'
config:
  port: 8080
  timeout: "30s"
  enabled: true
  ratio: 0.95
YAML

  cat > "$OVERRIDE_FILE" <<'YAML'
config:
  workers: 4
YAML

  BASE_CONTENT=$(base64 < "$BASE_FILE")
  OUTPUT=$(BASE_FILE="$BASE_CONTENT" OVERRIDE_FILE="$OVERRIDE_FILE" "$MERGE_SCRIPT" 2>&1) || true
  
  if echo "$OUTPUT" | grep -q "port: 8080" && \
     echo "$OUTPUT" | grep -q 'timeout: "30s"' && \
     echo "$OUTPUT" | grep -q "enabled: true" && \
     echo "$OUTPUT" | grep -q "workers: 4"; then
    print_pass
  else
    print_fail "Tipi YAML non preservati correttamente"
  fi
}

# Main
main() {
  echo "========================================"
  echo "Test Suite: merge-values.sh"
  echo "========================================"
  echo ""
  
  # Verifica prerequisiti
  if ! which yq > /dev/null 2>&1; then
    printf "${RED}ERROR: yq non installato${NC}\n"
    exit 1
  fi
  
  if [[ ! -f "$MERGE_SCRIPT" ]]; then
    printf "${RED}ERROR: Script merge-values.sh non trovato${NC}\n"
    exit 1
  fi
  
  # Esegui test
  setup
  trap cleanup EXIT
  
  test_basic_merge
  test_override_values
  test_deep_merge
  test_empty_override
  test_missing_override_file
  test_type_preservation
  
  # Risultati
  echo ""
  echo "========================================"
  echo "Risultati Test"
  echo "========================================"
  echo "Totale: $TESTS_RUN"
  printf "${GREEN}Passati: %d${NC}\n" "$TESTS_PASSED"
  
  if [[ $TESTS_FAILED -gt 0 ]]; then
    printf "${RED}Falliti: %d${NC}\n" "$TESTS_FAILED"
    return 1
  else
    printf "${GREEN}✓ Tutti i test passati!${NC}\n"
    return 0
  fi
}

main "$@"
