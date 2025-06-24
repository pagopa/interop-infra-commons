#!/bin/bash
set -euo pipefail

echo "Running helm template process"

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Environment used to detect values.yaml for template generation
        [ -d | --debug ] Enable Helm template debug
        [ -m | --microservices ] Generate templates for all microserviceservices
        [ -j | --jobs ] Generate templates for all cronjobs
        [ -i | --image ] File with microservices and cronjobs images tag and digest
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal
        [ -c | --clean ] Clean files and directories after scripts successfull execution
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -dtl | --disable-templating-lookup ] Disable Helm --dry-run=server option in order to avoid lookup configmaps and secrets when templating
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
enable_debug=false
template_microservices=false
template_jobs=false
post_clean=false
output_redirect=""
skip_dep=false
disable_templating_lookup=false
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
        -m | --microservices )
          template_microservices=true
          step=1
          shift 1
          ;;
        -j | --jobs )
          template_jobs=true
          step=1
          shift 1
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
echo "Environment: $environment"

ENV=$environment
DELIMITER=";"
MICROSERVICES_DIR=$(getMicroservicesDir)
CRONJOBS_DIR=$(getCronjobsDir)

OPTIONS=" "
if [[ $enable_debug == true ]]; then
  OPTIONS=$OPTIONS" -d"
fi
if [[ $post_clean == true ]]; then
  OPTIONS=$OPTIONS" -c"
fi
if [[ -n $output_redirect ]]; then
  OPTIONS=$OPTIONS" -o $output_redirect"
fi
if [[ -n $images_file ]]; then
  OPTIONS=$OPTIONS" -i $images_file"
fi
if [[ $skip_dep == false ]]; then
  bash "$SCRIPTS_FOLDER"/helmDep.sh --untar
fi

MICROSERVICE_OPTIONS=" "
if [[ $disable_templating_lookup != true ]]; then
  MICROSERVICE_OPTIONS=$MICROSERVICE_OPTIONS" --enable-templating-lookup"
fi
# Skip further execution of helm deps build and update since we have already done it in the previous line 
OPTIONS=$OPTIONS" -sd"

if [[ $template_microservices == true ]]; then
  echo "Start microservices templates generation"
  ALLOWED_MICROSERVICES=$(getAllowedMicroservicesForEnvironment "$ENV")
  
  if [[ -z $ALLOWED_MICROSERVICES || $ALLOWED_MICROSERVICES == "" ]]; then
    echo "No microservices found for environment '$ENV'. Skipping microservices templates generation."
  fi
  
  for CURRENT_SVC in ${ALLOWED_MICROSERVICES//;/ }
  do
    echo "Templating $CURRENT_SVC"
    VALID_CONFIG=$(isMicroserviceEnvConfigValid $CURRENT_SVC $ENV)
    if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
      echo "Environment configuration '$ENV' not found for microservice '$CURRENT_SVC'. Skip"
    else
      "$SCRIPTS_FOLDER"/helmTemplate-svc-single.sh -e $ENV -m $CURRENT_SVC $OPTIONS $MICROSERVICE_OPTIONS
    fi
  done

fi

if [[ $template_jobs == true ]]; then
  echo "Start cronjobs templates generation"
  ALLOWED_CRONJOBS=$(getAllowedCronjobsForEnvironment "$ENV")
  
  if [[ -z $ALLOWED_CRONJOBS || $ALLOWED_CRONJOBS == "" ]]; then
    echo "No cronjobs found for environment '$ENV'. Skipping cronjobs templates generation."
  fi
  
  for CURRENT_JOB in ${ALLOWED_CRONJOBS//;/ }
  do
    echo "Templating $CURRENT_JOB"
    VALID_CONFIG=$(isCronjobEnvConfigValid $CURRENT_JOB $ENV)
    if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
      echo "Environment configuration '$ENV' not found for cronjob '$CURRENT_JOB'"
    else
      "$SCRIPTS_FOLDER"/helmTemplate-cron-single.sh -e $ENV -j $CURRENT_JOB $OPTIONS
    fi
  done
fi

if [[ $post_clean == true ]]; then
  rm -rf "$ROOT_DIR/out/templates"
fi
