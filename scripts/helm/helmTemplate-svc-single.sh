#!/bin/bash
set -euo pipefail

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used for template generation
        [ -d | --debug ] Enable Helm template debug
        [ -m | --microservice ] Microservice defined in microservices folder
        [ -i | --image ] File with microservice image tag and digest
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal
        [ -c | --clean ] Clean files and directories after script successfull execution
        [ -v | --verbose ] Show debug messages
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -dtl | --disable-templating-lookup ] Disable Helm --dry-run=server option in order to avoid lookup configmaps and secrets when templating
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
microservice=""
enable_debug=false
post_clean=false
output_redirect=""
skip_dep=false
disable_templating_lookup=false
verbose=false
images_file=""

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
        -d | --debug)
          enable_debug=true
          step=1
          shift 1
          ;;
        -o | --output)
          [[ "${2:-}" ]] || "When specified, output cannot be null" || help
          output_redirect=$2
          if [[ $output_redirect != "console" ]]; then
            help
          fi

          step=2
          shift 2
          ;;
        -c | --clean)
          post_clean=true
          step=1
          shift 1
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
        -v| --verbose )
          verbose=true
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
  echo "Environment cannot be null"
  help
fi
if [[ -z $microservice || $microservice == "" ]]; then
  echo "Microservice cannot be null"
  help
fi
if [[ $skip_dep == false ]]; then
  bash "$SCRIPTS_FOLDER"/helmDep.sh --untar
fi

VALID_CONFIG=$(isMicroserviceEnvConfigValid $microservice $environment)
if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
  echo "Environment configuration '$environment' not found for microservice '$microservice'"
  help
fi

ENV=$environment
MICROSERVICE_DIR=$( echo $microservice | sed  's/-/_/g' )

OUT_DIR="$ROOT_DIR/out/templates/$ENV/microservice_$MICROSERVICE_DIR"
if [[ $output_redirect != "console" ]]; then
  rm -rf "$OUT_DIR"
  mkdir  -p "$OUT_DIR"
else
  OUT_DIR=""
fi

IMAGE_VERSION_READER_OPTIONS=""
if [[ -n $images_file ]]; then
  IMAGE_VERSION_READER_OPTIONS=" -f $images_file"
fi

# Find image version and digest
. "$SCRIPTS_FOLDER"/image-version-reader-v2.sh -e $environment -m $microservice $IMAGE_VERSION_READER_OPTIONS

TEMPLATE_CMD="helm template "
ADDITIONAL_VALUES=" "
if [[ $enable_debug == true ]]; then
  TEMPLATE_CMD=$TEMPLATE_CMD"--debug "
fi
if [[ $disable_templating_lookup == true ]]; then
  ADDITIONAL_VALUES=$ADDITIONAL_VALUES" --set enableLookup=false"
else
  TEMPLATE_CMD=$TEMPLATE_CMD"--dry-run=server --set enableLookup=true"
fi

OUTPUT_FILE="\"$OUT_DIR/$microservice.out.yaml\""
OUTPUT_TO="> $OUTPUT_FILE"
if [[ $output_redirect == "console" ]]; then
  OUTPUT_TO=""
fi

#TEMPLATE_CMD=$TEMPLATE_CMD" $microservice interop-eks-microservice-chart/interop-eks-microservice-chart -f \"$ROOT_DIR/commons/$ENV/values-microservice.compiled.yaml\" -f \"$ROOT_DIR/microservices/$microservice/$ENV/values.yaml\" $OUTPUT_TO"
TEMPLATE_CMD=$TEMPLATE_CMD" "$microservice" \"$ROOT_DIR/charts/interop-eks-microservice-chart\" -f \"$ROOT_DIR/commons/$ENV/values-microservice.compiled.yaml\" -f \"$ROOT_DIR/microservices/$microservice/$ENV/values.yaml\" $ADDITIONAL_VALUES $OUTPUT_TO"

eval $TEMPLATE_CMD
if [[ $verbose == true ]]; then
  echo "Successfully created Helm Template for microservice $microservice at $OUTPUT_FILE"
fi

if [[ $output_redirect != "console" && $post_clean == true ]]; then
  rm -rf $OUT_DIR
fi
