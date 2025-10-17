#!/bin/bash
set -euo pipefail

echo "Running helm lint process"

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR
SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Environment used to detect values.yaml for linting
        [ -d | --debug ] Enable Helm template debug
        [ -m | --microservices ] Lint all microservices
        [ -j | --jobs ] Lint all cronjobs
        [ -i | --image ] File with microservices and cronjobs images tag and digest
        [ -o | --output ] Default output to predefined dir. Otherwise set to "console" to print linting output on terminal or set to a file path to redirect output
        [ -c | --clean ] Clean files and directories after scripts successfull execution
        [ -sd | --skip-dep ] Skip Helm dependencies setup
        [ -cp | --chart-path ] Path to Chart.yaml file (overrides environment selection; must be an existing file)
        [ -dpi | --disable-plugins-install ] Do not install helm plugins (default: false)
        [ --argocd-plugin ] Set argocd plugin as caller of the script (default: false)
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
enable_debug=false
lint_microservices=false
lint_jobs=false
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
        -m | --microservices )
          lint_microservices=true
          step=1
          shift 1
          ;;
        -j | --jobs )
          lint_jobs=true
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
          if [[ $output_redirect != "console" ]] && [[ -z "$output_redirect" ]]; then
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
if [[ "$argocd_plugin" != "true" ]]; then
  echo "Environment: $environment"
fi

if [[ "$argocd_plugin" == "true" ]]; then
  suppressOutput
fi

ENV=$environment

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
if [[ -n $chart_path ]]; then
    OPTIONS=$OPTIONS" -cp $chart_path"
fi
if [[ "$argocd_plugin" == "true" ]]; then
  OPTIONS="$OPTIONS --argocd-plugin"
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

# Skip further execution of helm deps build and update since we have already done it in the previous line
OPTIONS=$OPTIONS" -sd"


if [[ $lint_microservices == true ]]; then
  echo "Start linting microservices"

  ALLOWED_MICROSERVICES=$(getAllowedMicroservicesForEnvironment "$ENV")
  if [[ -z $ALLOWED_MICROSERVICES || $ALLOWED_MICROSERVICES == "" ]]; then
    echo "No microservices found for environment '$ENV'. Skipping microservices linting."
  fi
  
  for CURRENT_SVC in ${ALLOWED_MICROSERVICES//;/ }
  do
    echo "Linting $CURRENT_SVC"
    
    VALID_CONFIG=$(isMicroserviceEnvConfigValid $CURRENT_SVC $ENV)
    if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
      echo "Environment configuration '$ENV' not found for microservice '$CURRENT_SVC'. Skip"
    else
      "$SCRIPTS_FOLDER"/helmLint-svc-single.sh -e $ENV -m $CURRENT_SVC $OPTIONS
    fi
  done
fi

if [[ $lint_jobs == true ]]; then
  echo "Start linting cronjobs"
  
  ALLOWED_CRONJOBS=$(getAllowedCronjobsForEnvironment "$ENV")
  if [[ -z $ALLOWED_CRONJOBS || $ALLOWED_CRONJOBS == "" ]]; then
    echo "No cronjobs found for environment '$ENV'. Skipping cronjobs linting."
  fi
  for CURRENT_JOB in ${ALLOWED_CRONJOBS//;/ }
  do
    echo "Linting $CURRENT_JOB" 
  
    VALID_CONFIG=$(isCronjobEnvConfigValid $CURRENT_JOB $ENV)
    if [[ -z $VALID_CONFIG || $VALID_CONFIG == "" ]]; then
      echo "Environment configuration '$ENV' not found for cronjob '$CURRENT_JOB'"
    else
      "$SCRIPTS_FOLDER"/helmLint-cron-single.sh -e $ENV -j $CURRENT_JOB $OPTIONS
    fi
  done
fi

if [[ $post_clean == true ]]; then
  rm -rf "$ROOT_DIR/out/lint"
fi

if [[ "$argocd_plugin" == "true" ]]; then
  restoreOutput
fi