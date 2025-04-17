#!/bin/bash
set -euo pipefail

SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used to execute kubectl diff
        [ -d | --debug ] Enable debug
        [ -m | --microservice ] Microservice defined in microservices folder
        [ -i | --image ] File with microservice image tag and digest
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -ftcf | --force-template-configmap-first ] Force a first helm template to get the configmap hash before performing a second helm template followed by kubectl apply
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
images_file=""
force_template_configmap_first=false

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
        -o | --output)
          [[ "${2:-}" ]] || "When specified, output cannot be null" || help
          output_redirect=$2
          if [[ $output_redirect != "console" ]]; then
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
        -ftcf | --force-template-configmap-first) 
          force_template_configmap_first=true
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
if [[ -n $output_redirect ]]; then
  OPTIONS=$OPTIONS" -o $output_redirect"
else
  OPTIONS=$OPTIONS" -o console "
fi
if [[ -n $images_file ]]; then
  OPTIONS=$OPTIONS" -i $images_file"
fi
if [[ $skip_dep == true ]]; then
  OPTIONS=$OPTIONS" -sd "
fi

#HELM_TEMPLATE_CMD="$SCRIPTS_FOLDER/helmTemplate-svc-single.sh -e $ENV -m $microservice $OPTIONS"
#APPLY_CMD="kubectl apply --show-managed-fields=false -f -"
#eval $HELM_TEMPLATE_CMD" | "$APPLY_CMD

HELM_TEMPLATE_SCRIPT="$SCRIPTS_FOLDER/helmTemplate-svc-single.sh"
APPLY_CMD="kubectl apply --show-managed-fields=false -f -"

if [[ $force_template_configmap_first == true ]]; then
  CONFIGMAP_YAML=$("$HELM_TEMPLATE_SCRIPT" -e "$ENV" -m "$microservice" $OPTIONS | yq eval 'select(.kind == "ConfigMap")' -)
  if [[ -n "$CONFIGMAP_YAML" ]]; then
    CONFIGMAP_HASH=$(echo "$CONFIGMAP_YAML" | sha256sum | awk '{print $1}')
    "$HELM_TEMPLATE_SCRIPT" -e "$ENV" -m "$microservice" --configmap-hash "$CONFIGMAP_HASH" --dry-run $OPTIONS | $APPLY_CMD
  fi
else
  "$HELM_TEMPLATE_SCRIPT" -e "$ENV" -m "$microservice" $OPTIONS | $APPLY_CMD
fi
