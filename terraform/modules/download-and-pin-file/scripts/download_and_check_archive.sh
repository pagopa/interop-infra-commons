#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

( echo " - External script started" 1>&2 )

# - Read all standard input
ALL_INPUT=$(cat)

# - Parse input parameters
URL=$( echo "${ALL_INPUT}" | jq -r '.url')
DESTINATION_PATH=$( echo "${ALL_INPUT}" | jq -r '.destination_path')
HEX_FILE_SHA256=$( echo "${ALL_INPUT}" | jq -r '.hex_sha256')
( echo " - Input parsing done" 1>&2 )
( echo "    url=${URL}" 1>&2 )
( echo "    destination_path=${DESTINATION_PATH}" 1>&2 )
( echo "    sha256_hex=${HEX_FILE_SHA256}" 1>&2 )

BASE64_FILE_SHA256=$(echo -n "$HEX_FILE_SHA256" | xxd -r -p | base64)
( echo "    sha256_base64=${BASE64_FILE_SHA256}" 1>&2 )

if ( [ -e "${DESTINATION_PATH}" ] ) then
  COMPUTED_HASH=$(shasum -a 256 "$DESTINATION_PATH" | awk '{ print $1 }' | xxd -r -p | base64)
else
  COMPUTED_HASH="File do not exists"
fi
( echo " - Cached file sha256_base64=${COMPUTED_HASH}" 1>&2 )

if ( [ "${COMPUTED_HASH}" != "${BASE64_FILE_SHA256}" ] ) then

  destination_folder=$( dirname "${DESTINATION_PATH}" )
  ( echo " - Create destination folder=${destination_folder}" 1>&2 )  
  mkdir -p "${destination_folder}"
  ( curl -vL -o "${DESTINATION_PATH}" "${URL}" 1>&2 )

  RE_COMPUTED_HASH=$(shasum -a 256 "$DESTINATION_PATH" | awk '{ print $1 }' | xxd -r -p | base64)
  ( echo " - Downloaded file sha256_base64=${RE_COMPUTED_HASH}" 1>&2 )

  if ( [ "${RE_COMPUTED_HASH}" != "${BASE64_FILE_SHA256}" ] ) then
    ( echo " - HASH DO NOT MATCH" 1>&2 )
    ( echo "   computed=${RE_COMPUTED_HASH}" 1>&2 )
    ( echo "   expected=${BASE64_FILE_SHA256}" 1>&2 )
    exit 1
  fi
fi

echo "{ \"msg\": \"OK!\", \"file_sha256_base64\": \"${BASE64_FILE_SHA256}\" }"
