#!/bin/bash
set -euo pipefail

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used to execute kubectl diff
        [ -d | --debug ] Enable debug
        [ -j | --job ] Cronjob defined in jobs folder
        [ -i | --image ] File with cronjob image tag and digest
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print template output on terminal or set to a file path to redirect output
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
output_redirect=""
skip_dep=false
images_file=""
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
        -o | --output)
          [[ "${2:-}" ]] || "When specified, output cannot be null" || help
          output_redirect=$2
          if [[ $output_redirect != "console" ]] && [[ -z "$output_redirect" ]]; then
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
  skip_dep=true
fi

VALID_CONFIG=$(isCronjobEnvConfigValid $job $environment)
if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
  if [[ "$argocd_plugin" != "true" ]]; then
    echo "Environment configuration '$environment' not found for cronjob '$job'"
  fi
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
if [[ "$argocd_plugin" == "true" ]]; then
  OPTIONS="$OPTIONS --argocd-plugin "
fi

#HELM_TEMPLATE_CMD="$SCRIPTS_FOLDER/helmTemplate-cron-single.sh -e $ENV -j $job $OPTIONS"
#DIFF_CMD="KUBECTL_EXTERNAL_DIFF=$SCRIPTS_FOLDER/diff.sh kubectl diff --show-managed-fields=false  -f -"
#eval $HELM_TEMPLATE_CMD" | "$DIFF_CMD

HELM_TEMPLATE_SCRIPT="$SCRIPTS_FOLDER/helmTemplate-cron-single.sh"
DIFF_SCRIPT="$SCRIPTS_FOLDER/diff.sh"

"$HELM_TEMPLATE_SCRIPT" -e "$ENV" -j "$job" $OPTIONS | \
 KUBECTL_EXTERNAL_DIFF="$DIFF_SCRIPT" kubectl diff --show-managed-fields=false -f -
