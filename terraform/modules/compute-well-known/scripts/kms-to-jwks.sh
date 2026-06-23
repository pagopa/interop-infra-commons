#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 " >&2
  echo " Variable public_keys must be set as a JSON array" >&2
  exit 1
}

# Ensure required commands are available
for cmd in openssl jq xxd; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: required command '$cmd' not found" >&2
    exit 1
  fi
done

public_keys=$(cat | jq -r ' .public_keys | fromjson' )

[[ -n "${public_keys:-}" ]] || usage
[[ $# -eq 0 ]] || usage

# Helper function to convert hex to base64url
hex_to_base64url() {
  echo "$1" | xxd -r -p | base64 | tr '+/' '-_' | tr -d '='
}

# Determine the number of keys in the input JSON array
num_keys=$(echo "$public_keys" | jq '. | length')
echo "Found $num_keys keys to process." >&2

# Array to hold individual JWK JSON strings
jwk_list=()

for ((i=0; i<num_keys; i++)); do
  echo "--- Processing key $((i+1)) of $num_keys ---" >&2
  
  # Extract the individual key object from the array
  item=$(echo "$public_keys" | jq -c ".[$i]")

  pub_key_b64=$(echo "$item" | jq -r '.PublicKey')
  key_id=$(echo "$item" | jq -r '.KeyId')
  kms_alg=$(echo "$item" | jq -r '.SigningAlgorithms[0]')

  # Use the last segment of the key ARN (the UUID) as kid
  kid="${key_id##*/}"

  echo "key_id = ${key_id}" >&2
  echo "kms_alg = ${kms_alg}" >&2
  echo "kid = ${kid}" >&2

  # Map KMS signing algorithm to JWA alg
  case "$kms_alg" in
    RSASSA_PKCS1_V1_5_SHA_256) alg="RS256" ;;
    RSASSA_PKCS1_V1_5_SHA_384) alg="RS384" ;;
    RSASSA_PKCS1_V1_5_SHA_512) alg="RS512" ;;
    RSASSA_PSS_SHA_256)        alg="PS256" ;;
    RSASSA_PSS_SHA_384)        alg="PS384" ;;
    RSASSA_PSS_SHA_512)        alg="PS512" ;;
    ECDSA_SHA_256)             alg="ES256" ;;
    ECDSA_SHA_384)             alg="ES384" ;;
    ECDSA_SHA_512)             alg="ES512" ;;
    *) echo "Error: unsupported signing algorithm '$kms_alg'" >&2; exit 1 ;;
  esac

  # --- Decode DER and extract modulus + exponent via openssl ---
  der_file=$(mktemp)
  echo "$pub_key_b64" | base64 --decode > "$der_file"

  # Redirect openssl stderr to /dev/null to keep logs clean
  rsa_text=$(openssl rsa -pubin -inform DER -in "$der_file" -text -noout 2>/dev/null)
  rm -f "$der_file"

  # --- Parse modulus (hex) ---
  modulus_hex=$(echo "$rsa_text" \
    | sed -n '/^Modulus:/,/^Exponent:/p' \
    | grep -v 'Modulus:\|Exponent:' \
    | tr -d ' :\n')

  # Strip leading 00 padding byte if present
  if [[ "${modulus_hex:0:2}" == "00" ]]; then
    modulus_hex="${modulus_hex:2}"
  fi

  # --- Parse exponent ---
  exponent_dec=$(echo "$rsa_text" | grep 'Exponent:' | grep -oE '[0-9]+' | head -1)

  # Convert decimal exponent to minimal hex
  exponent_hex=$(printf '%x' "$exponent_dec")
  if (( ${#exponent_hex} % 2 != 0 )); then
    exponent_hex="0${exponent_hex}"
  fi

  # Convert hex values to base64url
  n=$(hex_to_base64url "$modulus_hex")
  e=$(hex_to_base64url "$exponent_hex")

  # Build individual JWK object string
  jwk=$(jq -n \
    --arg kid "$kid" \
    --arg alg "$alg" \
    --arg n "$n" \
    --arg e "$e" \
    '{
      kty: "RSA",
      kid: $kid,
      use: "sig",
      alg: $alg,
      n: $n,
      e: $e
    }')

  jwk_list+=("$jwk")
done

echo "--- Generating Final JWKS Array ---" >&2

# Output the aggregated JWKS to stdout
if [ ${#jwk_list[@]} -eq 0 ]; then
  output=$( echo '{"keys": []}' )
else
  output=$(jq -n '{keys: [ $ARGS.positional[] | fromjson ]}' --args "${jwk_list[@]}" )
fi

echo '{ "output": '$(jq -n --arg str "$output" '$str')'}'
