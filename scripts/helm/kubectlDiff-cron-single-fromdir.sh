#!/bin/bash
set -euo pipefail

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used to execute kubectl diff
        [ -j | --job ] Cronjob defined in jobs folder
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -cp | --chart-path ] Path to Chart.yaml file (overrides environment selection; must be an existing file)
        [ -dpi | --disable-plugins-install ] Do not install helm plugins (default: false)
        [ --argocd-plugin ] Set argocd plugin as caller of the script (default: false)
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
job=""
enable_debug=false
post_clean=false
skip_dep=false
chart_path=""
disable_plugins_install=false
argocd_plugin=false

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
        -sd | --skip-dep)
          skip_dep=true
          step=1
          shift 1
          ;;
        -cp | --chart-path )
          [[ "${2:-}" ]] || { echo "Error: The chart path (-cp/--chart-path) cannot be null or empty."; help; }
          chart_path=$2
          step=2
          shift 2
          ;;
        -dpi | --disable-plugins-install )
          disable_plugins_install=true
          step=1
          shift 1
          ;;
        --argocd-plugin )
          argocd_plugin=true
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

if [[ "$argocd_plugin" == "true" ]]; then
  suppressOutput
fi

if [[ $skip_dep == false ]]; then
  HELMDEP_OPTIONS="--untar"

  if [[ "$disable_plugins_install" == "true" ]]; then
    HELMDEP_OPTIONS="$HELMDEP_OPTIONS --disable-plugins-install"
  fi
  if [[ "$argocd_plugin" == "true" ]]; then
    HELMDEP_OPTIONS="$HELMDEP_OPTIONS --argocd-plugin"
  fi
  if [[ -n "$chart_path" ]]; then
    HELMDEP_OPTIONS="$HELMDEP_OPTIONS --chart-path "$chart_path""
  fi

  HELMDEP_OPTIONS="$HELMDEP_OPTIONS --environment "$environment""

  bash "$SCRIPTS_FOLDER"/helmDep.sh $HELMDEP_OPTIONS
fi

VALID_CONFIG=$(isCronjobEnvConfigValid $job $environment)
if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
  echo "Environment configuration '$environment' not found for cronjob '$job'"
  help
fi

ENV=$environment
OUT_DIR="$ROOT_DIR/out/templates/$ENV/cron_$job"
OUT_DIR=$( echo $OUT_DIR | sed  's/-/_/g' )
#rm -rf $OUT_DIR
#mkdir  -p $OUT_DIR

DIFF_CMD="kubectl diff --show-managed-fields=false -f "
#if [[ $enable_debug == true ]]; then
#    DIFF_CMD=$DIFF_CMD"--debug "
#fi

DIFF_CMD=$DIFF_CMD" $OUT_DIR/$job.out.yaml"


if [[ "$argocd_plugin" == "true" ]]; then
  restoreOutput --force
fi

eval $DIFF_CMD
#if [[ $post_clean == true ]]; then
#  rm -rf $OUT_DIR
#fi
