#!/bin/bash
set -euo pipefail

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

usage() {
  cat <<EOF
Usage: $0 --deployment <deployment-name> --namespace <namespace> --batch-wait <seconds>

  --deployment | -d <deployment-name>   [required] Name of the Deployment to inspect
  --namespace | -n <namespace>          [required] Namespace of the Deployment
  --batch-wait | -b <seconds>           [required] Wait time for each rollout batch in seconds

Given a Deployment name, a namespace and a batch wait in seconds, extracts:

  • spec.replicas  
  • spec.strategy.rollingUpdate.maxSurge  

Then computes an **estimated** rollout wait time assuming each rollout batch takes <batch-wait> seconds.

EOF
  exit 1
}


deployment=""
namespace=""
BATCH_WAIT=""

while [[ $# -gt 0 ]];
do
    case "$1" in
        -d|--deployment )
          [[ "${2:-}" ]] || { echo "Error: --deployment requires a value" >&2; usage; }
          deployment=$2
          shift 2
          ;;
        -n|--namespace )
          [[ "${2:-}" ]] || { echo "Error: --namespace requires a value" >&2; usage; }
          namespace=$2
          shift 2
          ;;
        -b|--batch-wait )
          [[ "${2:-}" ]] || { echo "Error: --batch-wait requires a value" >&2; usage; }
          BATCH_WAIT=$2
          shift 2
          ;;
        -h | --help )
          usage
          ;;
        -*)
          echo "Unexpected option: $1" >&2
          usage
          ;;
        *)
          echo "Unexpected option: $1"
          usage
          ;;
    esac
done

if [[ -z "$deployment" ]]; then
    echo "Error: --deployment is required and must be set" >&2
    usage
fi
if [[ -z "$namespace" ]]; then
    echo "Error: --namespace is required and must be set" >&2
    usage
fi
if [[ -z "$BATCH_WAIT" ]]; then
    echo "Error: --batch-wait is required and must be set" >&2
    usage
fi

ceil() {
    local num=$1
    local denom=$2

    if [[ -z "$num" || -z "$denom" ]]; then
        echo "Error: num and denom must be set and non-empty" >&2
        exit 1
    fi
    if (( denom <= 0 )); then
        echo "Error: denom must be greater than zero" >&2
        exit 1
    fi
    if (( num < 0 )); then
        echo "Error: num must be non-negative" >&2
        exit 1
    fi

    echo $((num%denom?num/denom+1:num/denom))
}

dynamic_wait() {
    local replicas=$1
    local maxSurge=$2
    local waitPerBatch=$3
  
    if [[ -z "$replicas" ]]; then
        echo "Error: replicas is not set or empty" >&2
        exit 1
    fi
    if [[ -z "$maxSurge" ]]; then
        echo "Error: maxSurge is not set or empty" >&2
        exit 1
    fi
    if [[ -z "$waitPerBatch" ]]; then
        echo "Error: waitPerBatch is not set or empty" >&2
        exit 1
    fi

    # compute numeric surgeCount
    local surgeCount
    if [[ "$maxSurge" == *% ]]; then
        local pct=${maxSurge%\%}
        surgeCount=$(ceil $((replicas * pct)) 100)
    else
        surgeCount=$((maxSurge))
    fi
    # surgeCount between 1 and replicas
    (( surgeCount < 1 )) && surgeCount=1
    (( surgeCount > replicas )) && surgeCount=$replicas
    
    # compute how many “batches” are needed to rollout all replicas (max #surgeCount pods per batch)
    local batches=$( ceil $((replicas + surgeCount)) $surgeCount)

    # total wait = batches * wait per single batch in seconds
    echo $(( batches * waitPerBatch ))
    # TODO bc binary calculator
}

extractMaxSurgeFromTemplate() {
    local template=$1
    if [[ -z "$template" ]]; then
        echo "Error: template must be set and non-empty" >&2
        exit 1
    fi

    local maxSurge=$(echo "$template" | yq ea 'select(.kind == "Deployment") | .spec.strategy.rollingUpdate.maxSurge // ""')

    echo ${maxSurge:-""}
}

extractReplicasFromTemplate() {
    local template=$1
    if [[ -z "$template" ]]; then
        echo "Error: template must be set and non-empty" >&2
        exit 1
    fi

    local replicas=$(echo "$template" | yq ea 'select(.kind == "Deployment") | .spec.replicas // ""')

    echo ${replicas:-""}
}

helmTemplate=$(. "$SCRIPTS_FOLDER"/helmTemplate-svc-single.sh -e "$namespace" -dtl -sd -m "$deployment" -i "$ROOT_DIR/commons/$namespace/images.yaml" -o console)
replicas=$(extractReplicasFromTemplate "$helmTemplate")
maxSurge=$(extractMaxSurgeFromTemplate "$helmTemplate")

if [[ -z "$replicas" ]]; then
    echo "Error: Unable to extract replicas from template for deployment '$deployment' in namespace '$namespace'" >&2
    exit 1
fi
if [[ -z "$maxSurge" ]]; then
    echo "Error: Unable to extract maxSurge from template or cluster for deployment '$deployment' in namespace '$namespace'" >&2
    exit 1
fi

#echo " Deployment: $deployment"
#echo " Namespace: $namespace"
#echo " BATCH_WAIT: ${BATCH_WAIT}"
#echo " Replicas: ${replicas:-<not set>}"
#echo " MaxSurge: ${maxSurge:-<not set>}"

echo $(dynamic_wait "$replicas" "$maxSurge" "$BATCH_WAIT")
