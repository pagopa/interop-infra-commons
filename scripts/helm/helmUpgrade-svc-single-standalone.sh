#!/bin/bash
set -euo pipefail

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used to execute helm upgrade
        [ -d | --debug ] Enable debug
        [ -a | --atomic ] Enable helm install atomic option 
        [ -m | --microservice ] Microservice defined in microservices folder
        [ -i | --image ] File with microservice image tag and digest
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal or "null" to redirect output to /dev/null
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -hm | --history-max ] Set the maximum number of revisions saved per release
        [ -nw | --no-wait ] Do not wait for the release to be ready
        [ -t | --timeout ] Set the timeout for the upgrade operation (default is 5m0s)
        [ --force ] Force helm upgrade
        [ -dtl | --disable-templating-lookup ] Disable Helm --dry-run=server option in order to avoid lookup configmaps and secrets when upgrading
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
microservice=""
enable_atomic=false
enable_debug=false
post_clean=false
output_redirect=""
skip_dep=false
images_file=""
force=false
history_max=3
wait=true
timeout="5m0s"
disable_templating_lookup=false

step=1
for (( i=0; i<$args; i+=$step ))
do
    case "$1" in
        -e| --environment )
            [[ "${2:-}" ]] || "Environment cannot be null" || help

          environment=$2
          step=2
          shift 2
          ;;
        -a | --atomic)
          enable_atomic=true
          step=1
          shift 1
          ;;
        -d | --debug)
          enable_debug=true
          step=1
          shift 1
          ;;
        -m | --microservice )
          [[ "${2:-}" ]] || "Microservice cannot be null" || help

          microservice=$2
          serviceAllowedRes=$(isAllowedMicroservice $microservice)
          if [[ -z $serviceAllowedRes || $serviceAllowedRes == "" ]]; then
            echo "$microservice is not allowed"
            echo "Allowed values: " $(getAllowedMicroservices)
            help
          fi

          step=2
          shift 2
          ;;
        -i | --image )
          images_file=$2
          
          step=2
          shift 2
          ;;
        -o | --output)
          [[ "${2:-}" ]] || "When specified, output cannot be null" || help
          output_redirect=$2
          if [[ $output_redirect != "console" && $output_redirect != "null" ]]; then
            help
          fi

          step=2
          shift 2
          ;;
        -sd | --skip-dep)
          skip_dep=true
          step=1
          shift 1
          ;;
        -hm | --history-max )
          [[ "${2:-}" ]] || "When specified, history-max cannot be null" || help
          history_max=$2
          if [[ $history_max -lt 0 ]]; then
            echo "History-max must be equal or greater than 0"
            help
          fi

          step=2
          shift 2
          ;;
        --force)
          force=true
          step=1
          shift 1
          ;;
        -nw | --no-wait)
          wait=false
          step=1
          shift 1
          ;;
        -t | --timeout)
          [[ "${2:-}" ]] || "When specified, timeout cannot be null" || help
          timeout=$2
          
          step=2
          shift 2
          ;;
        -dtl | --disable-templating-lookup)
          disable_templating_lookup=true
          step=1
          shift 1
          ;;
        -h | --help )
          help
          ;;
        *)
          echo "Unexpected option: $1"
          help

          ;;
    esac
done

if [[ -z $environment || $environment == "" ]]; then
  echo "[SVC-UPGRADE] Environment cannot be null"
  help
fi
if [[ -z $microservice || $microservice == "" ]]; then
  echo "[SVC-UPGRADE] Microservice cannot be null"
  help
fi
if [[ $skip_dep == false ]]; then
  bash "$SCRIPTS_FOLDER"/helmDep.sh --untar
  skip_dep=true
fi

VALID_CONFIG=$(isMicroserviceEnvConfigValid $microservice $environment)
if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
  echo "[SVC-UPGRADE] Environment configuration '$environment' not found for microservice '$microservice'"
  help
fi

ENV=$environment
OPTIONS=" "
if [[ $enable_atomic == true ]]; then
  OPTIONS=$OPTIONS" --atomic"
fi
if [[ $enable_debug == true ]]; then
  OPTIONS=$OPTIONS" --debug"
fi
if [[ $force == true ]]; then
  OPTIONS=$OPTIONS" --force"
fi
if [[ $wait == true ]]; then
  OPTIONS=$OPTIONS" --wait --timeout $timeout"
fi

ADDITIONAL_VALUES=" "
if [[ $disable_templating_lookup == true ]]; then
  ADDITIONAL_VALUES=$ADDITIONAL_VALUES" --set enableLookup=false"
else
  OPTIONS=$OPTIONS" --dry-run=server"
  ADDITIONAL_VALUES=$ADDITIONAL_VALUES" --set enableLookup=true"
fi

OUTPUT_REDIRECT=" "
if [[ -n $output_redirect && $output_redirect == "null" ]]; then
  OUTPUT_REDIRECT=$OUTPUT_REDIRECT" >/dev/null"
fi

# START - Find image version and digest
IMAGE_VERSION_READER_OPTIONS=""
if [[ -n $images_file ]]; then
  IMAGE_VERSION_READER_OPTIONS=" -f $images_file"
fi

echo "[SVC-UPGRADE] Computing image version and digest for microservice '$microservice'."
. "$SCRIPTS_FOLDER"/image-version-reader-v2.sh -e $environment -m $microservice $IMAGE_VERSION_READER_OPTIONS
# END - Find image version and digest

UPGRADE_CMD="helm upgrade "
UPGRADE_CMD=$UPGRADE_CMD"--dependency-update --take-ownership --create-namespace --history-max $history_max "
UPGRADE_CMD=$UPGRADE_CMD"$OPTIONS "
UPGRADE_CMD=$UPGRADE_CMD"--namespace $ENV "
UPGRADE_CMD=$UPGRADE_CMD"--install $microservice \"$ROOT_DIR/charts/interop-eks-microservice-chart\" "
UPGRADE_CMD=$UPGRADE_CMD"-f \"$ROOT_DIR/commons/$ENV/values-microservice.compiled.yaml\" "
UPGRADE_CMD=$UPGRADE_CMD"-f \"$ROOT_DIR/microservices/$microservice/$ENV/values.yaml\" "
UPGRADE_CMD=$UPGRADE_CMD"$ADDITIONAL_VALUES $OUTPUT_REDIRECT"

echo "[SVC-UPGRADE] Executing $microservice upgrade command."
eval $UPGRADE_CMD
