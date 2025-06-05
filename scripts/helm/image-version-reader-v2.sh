#!/bin/bash
set -euo pipefail

PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
ROOT_DIR=$PROJECT_DIR

SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPTS_FOLDER"/common-functions.sh

help()
{
    echo "Usage:  [ -e | --environment ] Cluster environment used for image version search
        [ -m | --microservice ] Microservice defined in microservices folder. Cannot be used in conjunction with "job" option
        [ -j | --job ] Cronjob defined in jobs folder. Cannot be used in conjunction with "microservice" option
        [ -f | --file ] (optional) Yaml configuration file with image definition (tag/digest)
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
tagetValues=""
tag_placeholder="IMAGE_TAG_PLACEHOLDER"
digest_placeholder="IMAGE_DIGEST_PLACEHOLDER"

found_version=""
found_digest=""

CONTAINER_IMAGES_FOLDER="$ROOT_DIR/commons/$environment"

if [[ -n $microservice ]]; then
  target=$microservice
  tagetValues="values-microservice"
else
  target=$job
  tagetValues="values-cronjob"
fi


if [[ -n $configFile ]]; then
  if [[ ! -e "$configFile" ]]; then
    echo "Specified $configFile config file does not exist."
    help
  fi

  label=""

  if [[ -n $microservice ]]; then
    label="microservices"
  else 
    label="jobs"
  fi
  
  found_version=$(cat $configFile | yq ".images.$label.$target.tag")
  found_digest=$(cat $configFile | yq ".images.$label.$target.digest")

else
  if [[ ! -e "$CONTAINER_IMAGES_FOLDER/values-images.sh" ]]; then
    echo "$CONTAINER_IMAGES_FOLDER/values-images.sh file does not exist."
    help
  fi
  
  suffix="_IMAGE_VERSION"
  digestSuffix="_IMAGE_DIGEST"

  prefix=""

  if [[ -n $job ]]; then
    prefix="JOB_"
  fi

  target=$(echo $target | sed  's/-/_/g' | tr '[a-z]' '[A-Z]')
  targetRegex=$prefix$target$suffix

  found_version=$(cat "$CONTAINER_IMAGES_FOLDER/values-images.sh" | { egrep -i  "^$targetRegex" || :; } )
  if [[ -n $found_version ]]; then
    found_version=$(echo $found_version | cut -d '=' -f 2)
  fi
  
  digestTargetRegex=$prefix$target$digestSuffix
  found_digest=$(cat "$CONTAINER_IMAGES_FOLDER/values-images.sh" | { egrep -i  "^$digestTargetRegex" || :; } )
  if [[ -n $found_digest ]]; then
    found_digest=$(echo $found_digest | cut -d '=' -f 2)
  fi  
fi

export $tag_placeholder=$found_version
export $digest_placeholder=$found_digest

envsubst < "$CONTAINER_IMAGES_FOLDER/$tagetValues.yaml" > "$CONTAINER_IMAGES_FOLDER/$tagetValues.compiled.yaml"

cd "$SCRIPTS_FOLDER"