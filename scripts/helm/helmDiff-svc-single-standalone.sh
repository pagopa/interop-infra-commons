#!/bin/bash
set -euo pipefail

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used to execute helm diff
        [ -d | --debug ] Enable debug
        [ -m | --microservice ] Microservice defined in microservices folder
        [ -i | --image ] File with microservice image tag and digest
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -dtl | --disable-templating-lookup ] Disable Helm --dry-run=server option in order to avoid lookup configmaps and secrets when templating
        [ -cp | --chart-path ] Path to Chart.yaml file (overrides environment selection; must be an existing file)
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
microservice=""
enable_debug=false
post_clean=false
skip_dep=false
images_file=""
disable_templating_lookup=false
chart_path=""

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
        -sd | --skip-dep)
          skip_dep=true
          step=1
          shift 1
          ;;
        -dtl | --disable-templating-lookup)
          disable_templating_lookup=true
          step=1
          shift 1
          ;;
        -cp | --chart-path )
          [[ "${2:-}" ]] || { echo "Error: The chart path (-cp/--chart-path) cannot be null or empty."; help; }
          chart_path=$2
          step=2
          shift 2
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
  echo "Environment cannot be null"
  help
fi
if [[ -z $microservice || $microservice == "" ]]; then
  echo "Microservice cannot be null"
  help
fi
if [[ $skip_dep == false ]]; then
  bash "$SCRIPTS_FOLDER"/helmDep.sh --untar --chart-path "$chart_path" --environment "$environment"
  skip_dep=true
fi

VALID_CONFIG=$(isMicroserviceEnvConfigValid $microservice $environment)
if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
  echo "Environment configuration '$environment' not found for microservice '$microservice'"
  help
fi

ENV=$environment
OPTIONS=" "
if [[ $enable_debug == true ]]; then
  OPTIONS=$OPTIONS" -d"
fi
if [[ -n $images_file ]]; then
  OPTIONS=$OPTIONS" -i $images_file"
fi
if [[ $skip_dep == true ]]; then
  OPTIONS=$OPTIONS" -sd "
fi

ADDITIONAL_VALUES=" "
if [[ $disable_templating_lookup == true ]]; then
  ADDITIONAL_VALUES=$ADDITIONAL_VALUES" --set enableLookup=false"
else
  OPTIONS=$OPTIONS" --dry-run=server"
  ADDITIONAL_VALUES=$ADDITIONAL_VALUES" --set enableLookup=true"
fi

# START - Find image version and digest
IMAGE_VERSION_READER_OPTIONS=""
if [[ -n $images_file ]]; then
  IMAGE_VERSION_READER_OPTIONS=" -f $images_file"
fi

. "$SCRIPTS_FOLDER"/image-version-reader-v2.sh -e $environment -m $microservice $IMAGE_VERSION_READER_OPTIONS
# END - Find image version and digest

set +e
helm diff upgrade --install  "$microservice"  "$ROOT_DIR/charts/interop-eks-microservice-chart" \
  --namespace "$ENV" --normalize-manifests --detailed-exitcode --dry-run=server --color=true \
  -f \"$ROOT_DIR/commons/$ENV/values-microservice.compiled.yaml\" \
  -f \"$ROOT_DIR/microservices/$microservice/$ENV/values.yaml\" \
 $ADDITIONAL_VALUES
diff_result=$?
set -e

#if [[ $diff_result -eq 0 ]]; then
#  echo "No changes detected"
#elif [[ $diff_result -eq 2 ]]; then
#  echo "Changes detected"
#else
#  echo "Unexpected error"
#fi

exit $diff_result