#!/bin/bash
set -euo pipefail

SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used to execute helm upgrade
        [ -dr | --dry-run ] Enable dry-run mode
        [ -d | --debug ] Enable debug
        [ -a | --atomic ] Enable helm install atomic option 
        [ -j | --job ] Cronjob defined in jobs folder
        [ -i | --image ] File with cronjob image tag and digest
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -hm | --history-max ] Set the maximum number of revisions saved per release
        [ --force ] Force helm upgrade
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
job=""
enable_atomic=false
enable_debug=false
enable_dryrun=false
post_clean=false
output_redirect=""
skip_dep=false
images_file=""
force=false
history_max=3

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
        -j | --job )
          [[ "${2:-}" ]] || "Job cannot be null" || help
          
          job=$2
          jobAllowedRes=$(isAllowedCronjob $job)
          if [[ -z $jobAllowedRes || $jobAllowedRes == "" ]]; then
              echo "$job is not allowed"
              echo "Allowed values: " $(getAllowedCronjobs)
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
if [[ -z $job || $job == "" ]]; then
  echo "Job cannot null"
  help
fi
if [[ $skip_dep == false ]]; then
  bash "$SCRIPTS_FOLDER"/helmDep.sh --untar
  skip_dep=true
fi

VALID_CONFIG=$(isCronjobEnvConfigValid $job $environment)
if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
  echo "Environment configuration '$environment' not found for cronjob '$job'"
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
if [[ $enable_dryrun == true ]]; then
  OPTIONS=$OPTIONS" --dry-run"
fi
if [[ $force == true ]]; then
  OPTIONS=$OPTIONS" --force"
fi

# START - Find image version and digest
IMAGE_VERSION_READER_OPTIONS=""
if [[ -n $images_file ]]; then
  IMAGE_VERSION_READER_OPTIONS=" -f $images_file"
fi

. "$SCRIPTS_FOLDER"/image-version-reader-v2.sh -e $environment -j $job $IMAGE_VERSION_READER_OPTIONS
# END - Find image version and digest


helm upgrade --dependency-update --take-ownership --create-namespace --history-max $history_max \
  $OPTIONS \
  --install $job "$ROOT_DIR/charts/interop-eks-cronjob-chart" \
  --namespace $ENV \
 -f \"$ROOT_DIR/commons/$ENV/values-cronjob.compiled.yaml\" \
 -f \"$ROOT_DIR/jobs/$job/$ENV/values.yaml\"
