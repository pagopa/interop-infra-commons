#!/bin/bash
set -euo pipefail

echo "Running helm upgrade process"

SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Environment used to execute helm upgrade
        [ -dr | --dry-run ] Enable dry-run mode
        [ -d | --debug ] Enable debug
        [ -a | --atomic ] Enable helm install atomic option 
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal
        [ -m | --microservices ] Execute diff for all microservices
        [ -j | --jobs ] Execute diff for all cronjobs
        [ -i | --image ] File with microservices and cronjobs images tag and digest
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ --force ] Force helm upgrade
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
enable_atomic=false
enable_debug=false
enable_dryrun=false
template_microservices=false
template_jobs=false
post_clean=false
output_redirect=""
skip_dep=false
images_file=""
force=false

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
        -dr | --dry-run)
          enable_dryrun=true
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
        --force)
          force=true
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
if [[ $enable_atomic == true ]]; then
  OPTIONS=$OPTIONS" --atomic"
fi
if [[ $enable_debug == true ]]; then
  OPTIONS=$OPTIONS" --debug"
fi
if [[ $enable_dryrun == true ]]; then
  OPTIONS=$OPTIONS" --dry-run"
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
OPTIONS=$OPTIONS" -sd"

if [[ $template_microservices == true ]]; then
  echo "Start microservices helm install"
  for dir in "$MICROSERVICES_DIR"/*;
  do
    CURRENT_SVC=$(basename "$dir");
    echo "Upgrade $CURRENT_SVC"
    sh "$SCRIPTS_FOLDER"/helmUpgrade-svc-single-standalone.sh -e $ENV -m $CURRENT_SVC $OPTIONS
  done
fi

if [[ $template_jobs == true ]]; then
  echo "Start cronjobs helm install"
  for dir in "$CRONJOBS_DIR"/*;
  do
    CURRENT_JOB=$(basename "$dir");
    echo "Upgrade $CURRENT_JOB"
    sh "$SCRIPTS_FOLDER"/helmUpgrade-cron-single-standalone.sh -e $ENV -j $CURRENT_JOB $OPTIONS
  done
fi