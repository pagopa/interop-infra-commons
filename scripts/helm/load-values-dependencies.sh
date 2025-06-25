#!/bin/bash
set -euo pipefail

# "Loading values dependencies"

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR

SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  
        [ -e | --environment ] Cluster environment used for dependencies search
        [ -m | --microservice ] Microservice defined in microservices folder. Cannot be used in conjunction with "job" option
        [ -j | --job ] Cronjob defined in jobs folder. Cannot be used in conjunction with "microservice" option
        [ -f | --file ] (optional) Yaml configuration file with dependencies definition
        [ -h | --help ] This help"
    exit 2
}

args=$#
environment=""
microservice=""
configFile=""
job=""

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
        -f | --file )
          [[ "${2:-}" ]] || "File cannot be null" || help
          
          configFile=$2
          
          step=2
          shift 2
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

if [[ -z $microservice || $microservice == "" ]] && [[ -z $job || $job == "" ]]; then
  echo "At least one from microservice and job option should be set"
  help
fi

if [[ -n $microservice ]] && [[ -n $job ]]; then
  echo "Only one from microservice and job option should be set"
  help
fi

target=""
if [[ -n $microservice ]]; then
  target=$microservice
else
  target=$job
fi

label=""
if [[ -n $microservice ]]; then
  label="microservices"
else 
  label="jobs"
fi

defaultConfigFile=$(getDependenciesDefaultConfigFile $ENV)
dependenciesValuesFolder=$(getDependencyValuesFolder $ENV)
targetDependenciesValuesFile=$(getComputedDependenciesFile $ENV $label $target)

rm -f $targetDependenciesValuesFile && touch $targetDependenciesValuesFile

if [[ -z $configFile || $configFile == "" ]]; then
  if [[ ! -e "$defaultConfigFile" ]]; then
    # "Default dependencies config file $defaultConfigFile does not exist."
    return 0
  else
    configFile="$defaultConfigFile"
    if [[ ! -e "$configFile" ]]; then
      echo "User defined dependencies config file $configFile does not exist."
      exit 1
    fi
  fi
fi

if [[ -n $configFile ]]; then
  declare -a found_deps=("")  
  found_deps+=( $(yq e -r ".dependencies.$label.$target // [] | .[]" "$configFile") )
  
  if [[ -z $found_deps || ${#found_deps[@]} -eq 0 ]]; then
    # "No dependencies found for $target in $configFile"
    return 0
  fi
  #echo "Found dependencies for $target: ${found_deps[*]}"
  for dep in "${found_deps[@]}"; do
    depFile="$dependenciesValuesFolder/values-$dep.yaml"
    if [[ ! -e "$depFile" ]]; then
      echo "Dependency values file $depFile does not exist."
      exit 1
    fi

    echo "$depFile" >> "$targetDependenciesValuesFile"
  done
fi