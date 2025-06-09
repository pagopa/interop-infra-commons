#!/bin/bash
set -euo pipefail

echo "[MAIN-UPGRADE] Running helm upgrade process"

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Environment used to execute helm upgrade
        [ -d | --debug ] Enable debug
        [ -a | --atomic ] Enable helm install atomic option 
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal or "null" to redirect output to /dev/null
        [ -m | --microservices ] Execute diff for all microservices
        [ -j | --jobs ] Execute diff for all cronjobs
        [ -i | --image ] File with microservices and cronjobs images tag and digest
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -hm | --history-max ] Set the maximum number of revisions saved per release
        [ -nw | --no-wait ] Do not wait for the release to be ready
        [ -t | --timeout ] Set the timeout for the upgrade operation (default is 5m0s)
        [ --force ] Force helm upgrade
        [ -etl | --enable-templating-lookup ] Enable Helm to run with the --dry-run=server option in order to lookup configmaps and secrets when templating
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
enable_atomic=false
enable_debug=false
template_microservices=false
template_jobs=false
post_clean=false
output_redirect=""
skip_dep=false
images_file=""
force=false
history_max=3
wait=true
timeout="5m0s"
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
  echo "[MAIN-UPGRADE] Environment cannot be null"
  help
fi
echo "[MAIN-UPGRADE] Selected Environment: $environment"

ENV=$environment
DELIMITER=";"
MICROSERVICES_DIR=$(getMicroservicesDir)
CRONJOBS_DIR=$(getCronjobsDir)

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
  skip_dep=true
fi
# Skip further execution of helm deps build and update since we have already done it in the previous line 
OPTIONS=$OPTIONS" -sd -hm $history_max"

MICROSERVICE_OPTIONS=" "
if [[ $wait == true ]]; then
  MICROSERVICE_OPTIONS=$MICROSERVICE_OPTIONS" --timeout $timeout"
else
  MICROSERVICE_OPTIONS=$MICROSERVICE_OPTIONS" --no-wait" 
fi
if [[ $enable_templating_lookup == true ]]; then
  MICROSERVICE_OPTIONS=$MICROSERVICE_OPTIONS" --enable-templating-lookup"
fi

if [[ $template_microservices == true ]]; then
  echo "[MAIN-UPGRADE] Start microservices helm install"
  ALLOWED_MICROSERVICES=$(getAllowedMicroservicesForEnvironment "$ENV")
  
  if [[ -z $ALLOWED_MICROSERVICES || $ALLOWED_MICROSERVICES == "" ]]; then
    echo "[MAIN-UPGRADE] No microservices found for environment '$ENV'. Skipping microservices upgrade."
  fi
  
  for CURRENT_SVC in ${ALLOWED_MICROSERVICES//;/ }
  do
    echo "[MAIN-UPGRADE] Upgrade $CURRENT_SVC"
    sh "$SCRIPTS_FOLDER"/helmUpgrade-svc-single-standalone.sh -e $ENV -m $CURRENT_SVC $OPTIONS $MICROSERVICE_OPTIONS
  done
fi

if [[ $template_jobs == true ]]; then
  echo "[MAIN-UPGRADE] Start cronjobs helm install"
  ALLOWED_CRONJOBS=$(getAllowedCronjobsForEnvironment "$ENV")
  
  if [[ -z $ALLOWED_CRONJOBS || $ALLOWED_CRONJOBS == "" ]]; then
    echo "[MAIN-UPGRADE] No cronjobs found for environment '$ENV'. Skipping cronjobs upgrade."
  fi
  
  for CURRENT_JOB in ${ALLOWED_CRONJOBS//;/ }
  do
    echo "[MAIN-UPGRADE] Upgrade $CURRENT_JOB"
    sh "$SCRIPTS_FOLDER"/helmUpgrade-cron-single-standalone.sh -e $ENV -j $CURRENT_JOB $OPTIONS
  done
fi