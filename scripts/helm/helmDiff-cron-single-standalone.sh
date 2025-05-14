#!/bin/bash
set -euo pipefail

SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used to execute helm diff
        [ -d | --debug ] Enable debug
        [ -j | --job ] Cronjob defined in jobs folder
        [ -i | --image ] File with cronjob image tag and digest
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
job=""
enable_debug=false
post_clean=false
skip_dep=false
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
        -d | --debug)
          enable_debug=true
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
        -sd | --skip-dep)
          skip_dep=true
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
if [[ $enable_debug == true ]]; then
  OPTIONS=$OPTIONS" -d"
fi
if [[ -n $images_file ]]; then
  OPTIONS=$OPTIONS" -i $images_file"
fi
if [[ $skip_dep == true ]]; then
  OPTIONS=$OPTIONS" -sd "
fi

# START - Find image version and digest
IMAGE_VERSION_READER_OPTIONS=""
if [[ -n $images_file ]]; then
  IMAGE_VERSION_READER_OPTIONS=" -f $images_file"
fi

. "$SCRIPTS_FOLDER"/image-version-reader-v2.sh -e $environment -j $job $IMAGE_VERSION_READER_OPTIONS
# END - Find image version and digest

set +e
helm diff upgrade --install  "$job"  "$ROOT_DIR/charts/interop-eks-cronjob-chart" \
  --namespace "$ENV" --normalize-manifests --detailed-exitcode --dry-run=server --color=true \
  -f \"$ROOT_DIR/commons/$ENV/values-cronjob.compiled.yaml\" \
  -f \"$ROOT_DIR/jobs/$job/$ENV/values.yaml\"
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
