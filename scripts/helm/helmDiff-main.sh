#!/bin/bash
set -euo pipefail

echo "Running helm diff process"

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Environment used to execute helm diff
        [ -d | --debug ] Enable debug
        [ -m | --microservices ] Execute diff for all microservices
        [ -j | --jobs ] Execute diff for all cronjobs
        [ -i | --image ] File with microservices and cronjobs images tag and digest
        [ -etl | --enable-templating-lookup ] Enable Helm to run with the --dry-run=server option in order to lookup configmaps and secrets when templating
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
enable_debug=false
template_microservices=false
template_jobs=false
post_clean=false
skip_dep=false
images_file=""
enable_templating_lookup=false

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
        -sd | --skip-dep)
          skip_dep=true
          step=1
          shift 1
          ;;
        -etl | --enable-templating-lookup)
          enable_templating_lookup=true
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
if [[ -n $images_file ]]; then
  OPTIONS=$OPTIONS" -i $images_file"
fi
if [[ $skip_dep == false ]]; then
  bash "$SCRIPTS_FOLDER"/helmDep.sh --untar
  skip_dep=true
fi
# Skip further execution of helm deps build and update since we have already done it in the previous line 
OPTIONS=$OPTIONS" -sd"

MICROSERVICE_OPTIONS=" "
if [[ $enable_templating_lookup == true ]]; then
  MICROSERVICE_OPTIONS=$MICROSERVICE_OPTIONS" --enable-templating-lookup"
fi

if [[ $template_microservices == true ]]; then
  echo "Start microservices templates diff"
  ALLOWED_MICROSERVICES=$(getAllowedMicroservicesForEnvironment "$ENV")

  if [[ -z $ALLOWED_MICROSERVICES || $ALLOWED_MICROSERVICES == "" ]]; then
    echo "No microservices found for environment '$ENV'. Skipping microservices diff."
  fi
  
  for CURRENT_SVC in ${ALLOWED_MICROSERVICES//;/ }
  do
    echo "Diff $CURRENT_SVC"
    "$SCRIPTS_FOLDER"/helmDiff-svc-single-standalone.sh -e $ENV -m $CURRENT_SVC $OPTIONS $MICROSERVICE_OPTIONS
  done
fi

if [[ $template_jobs == true ]]; then
  echo "Start cronjobs templates diff"
  ALLOWED_CRONJOBS=$(getAllowedCronjobsForEnvironment "$ENV")
  
  if [[ -z $ALLOWED_CRONJOBS || $ALLOWED_CRONJOBS == "" ]]; then
    echo "No cronjobs found for environment '$ENV'. Skipping cronjobs diff."
  fi
  
  for CURRENT_JOB in ${ALLOWED_CRONJOBS//;/ }
  do
    echo "Diff $CURRENT_JOB"
    "$SCRIPTS_FOLDER"/helmDiff-cron-single-standalone.sh -e $ENV -j $CURRENT_JOB $OPTIONS
  done
fi
