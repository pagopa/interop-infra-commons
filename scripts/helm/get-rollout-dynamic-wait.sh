#!/bin/bash
set -euo pipefail

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

usage() {
  cat <<EOF
Usage: $0 --deployment <deployment-name> --namespace <namespace> --batch-wait <seconds>

  --deployment | -d <deployment-name>   Name of the Deployment to inspect
  --namespace | -n <namespace>          Namespace of the Deployment (optional, defaults to "default")
  --batch-wait | -b <seconds>           Wait time for each rollout batch in seconds (default: 30s) -> TODO: obbligatorio

Given a Deployment name, a namespace and a Helm template, extracts:

  • spec.replicas  
  • spec.strategy.rollingUpdate.maxSurge  

Then computes an **estimated** rollout wait time assuming each rollout batch
takes \$BATCH_WAIT seconds (default 30s). You can override with the
environment variable BATCH_WAIT.

EOF
  exit 1
}


deployment=""
namespace=""
template=""
BATCH_WAIT="30"

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

computeDeploymentNameFromTemplate() {
    local template=$1
    if [[ -z "$template" ]]; then
        echo "Error: template must be set and non-empty" >&2
        exit 1
    fi

    local deploymentName=""
    local block=""
    local isDeployment=""

    # remove leading '---' and any newline that follows it
    template="${template#---$'\n'}"

    while [[ -n "$template" ]]; do
        # take everything up to the next '---' with leading newline (or the rest of the string)
        block="${template%%$'\n---'*}"
        isDeployment=$(echo "$block" | yq eval 'select(.kind == "Deployment")')

        if [[ -n "$isDeployment" ]]; then
            # Check name value in the Deployment metadata.
            deploymentName=$(echo "$block" | yq eval '.metadata.name // ""')
            break
        fi

        # if there's another separator, cut it (and the newline) off and repeat
        if [[ "$template" == *$'\n---'* ]]; then
            template="${template#*${block}$'\n---'}"
        else
            break
        fi
    done

    echo ${deploymentName:-""}
}

extractMaxSurgeFromTemplate() {
    local template=$1
    if [[ -z "$template" ]]; then
        echo "Error: template must be set and non-empty" >&2
        exit 1
    fi

    local maxSurge=""
    local block=""
    local isDeployment=""

    # remove leading '---' and any newline that follows it
    template="${template#---$'\n'}"

    while [[ -n "$template" ]]; do
        # take everything up to the next '---' with leading newline (or the rest of the string)
        block="${template%%$'\n---'*}"
        isDeployment=$(echo "$block" | yq eval 'select(.kind == "Deployment")')

        if [[ -n "$isDeployment" ]]; then
            # Check maxSurge value in the Deployment spec.
            maxSurge=$(echo "$block" | yq eval '.spec.strategy.rollingUpdate.maxSurge // ""')
            break
        fi

        # if there's another separator, cut it (and the newline) off and repeat
        if [[ "$template" == *$'\n---'* ]]; then
            template="${template#*${block}$'\n---'}"
        else
            break
        fi
    done

    echo ${maxSurge:-""}
}

extractReplicasFromTemplate() {
    local template=$1
    if [[ -z "$template" ]]; then
        echo "Error: template must be set and non-empty" >&2
        exit 1
    fi

    local replicas=""
    local block=""
    local isDeployment=""

    # remove leading '---' and any newline that follows it
    template="${template#---$'\n'}"

    while [[ -n "$template" ]]; do
        # take everything up to the next '---' with leading newline (or the rest of the string)
        block="${template%%$'\n---'*}"
        isDeployment=$(echo "$block" | yq eval 'select(.kind == "Deployment")')

        if [[ -n "$isDeployment" ]]; then
            # Check replicas value in the Deployment spec.
            replicas=$(echo "$block" | yq eval '.spec.replicas // ""')
            break
        fi

        # if there's another separator, cut it (and the newline) off and repeat
        if [[ "$template" == *$'\n---'* ]]; then
            template="${template#*${block}$'\n---'}"
        else
            break
        fi
    done

    echo $replicas
}


helmTemplate=$(. "$SCRIPTS_FOLDER"/helmTemplate-svc-single.sh -e "$namespace" -dtl -sd -m "$deployment" -i "$ROOT_DIR/commons/$namespace/images.yaml" -o console)
replicas=$(extractReplicasFromTemplate "$helmTemplate")
maxSurge=$(extractMaxSurgeFromTemplate "$helmTemplate")

deploymentName=$(computeDeploymentNameFromTemplate "$helmTemplate")

if [[ -z "$replicas" ]]; then
    echo "Error: Unable to extract replicas from template for deployment '$deployment' in namespace '$namespace'" >&2
    exit 1
fi
if [[ -z "$maxSurge" ]]; then # TODO: errore
    echo "Error: Unable to extract maxSurge from template or cluster for deployment '$deployment' in namespace '$namespace'" >&2
    exit 1
fi

#echo " Deployment: $deployment"
#echo " Namespace: $namespace"
#echo " BATCH_WAIT: ${BATCH_WAIT}"
#echo " Replicas: ${replicas:-<not set>}"
#echo " MaxSurge: ${maxSurge:-<not set>}"

echo $(dynamic_wait "$replicas" "$maxSurge" "$BATCH_WAIT")
