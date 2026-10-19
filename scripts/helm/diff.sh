#!/bin/bash
DIFF_ARGS=(
  "-u"
  "-N"
)
if [[ ! $ANSIBLE_MODE = YES ]]; then
  DIFF_ARGS+=("--color=always")
else
  DIFF_ARGS+=("--color=auto")
fi

sort_env_section() {
  target=$1
  kind=""
  fileName=""

  if [[ -d $1 ]]; then

    fileName=$(find $1 -name "*Deployment*")
    if [[ -n $fileName ]]; then
      fileName=$(basename $fileName)
      kind="Deployment"

    else
      fileName=$(find $1 -name "*CronJob*")
      if [[ -n $fileName ]]; then
        fileName=$(basename $fileName)
        kind="CronJob"

      else
        fileName=""
        kind=""

      fi
    fi

    target="$1/$fileName"
  fi
  
  if [[ $kind == "Deployment" ]]; then
    ORDERED_FLYWAY=$(KIND=$kind yq '(select(.kind == env(KIND)).spec.template.spec.initContainers[0].env | sort_by(.name))' "$target")
    ORDERED=$(KIND=$kind yq '(select(.kind == env(KIND)).spec.template.spec.containers[0].env | sort_by(.name))' "$target")
    
    NEW_FLYWAY_ENVS=$ORDERED_FLYWAY yq -i '.spec.template.spec.initContainers[0].env = env(NEW_FLYWAY_ENVS)' $target
    NEW_ENVS=$ORDERED yq -i '.spec.template.spec.containers[0].env = env(NEW_ENVS)' $target
  
  elif [[ $kind == "CronJob" ]]; then
    ORDERED=$(KIND=$kind yq '(select(.kind == env(KIND)).spec.jobTemplate.spec.template.spec.containers[0].env | sort_by(.name))' "$target")
    
    NEW_ENVS=$ORDERED yq -i '.spec.jobTemplate.spec.template.spec.containers[0].env = env(NEW_ENVS)' $target
  fi
}

if [[ $# -ne 2 ]]; then
  echo "Error: expected exactly two diff inputs." >&2
  exit 2
fi
for input_path in "$@"; do
  if [[ ! -e "$input_path" || ! -r "$input_path" ]]; then
    echo "Error: diff input '$input_path' does not exist or is not readable." >&2
    exit 2
  fi
done

sort_env_section "$1"
sort_env_section "$2"

SKIP_LINE=0
DIFF_OUTPUT=$(diff "${DIFF_ARGS[@]}" "$@")
DIFF_EXIT_CODE=$?

awk -v skip=$SKIP_LINE '
  BEGIN {
    exit_code = 0
  }
  { 
    if (skip == 1) {
      skip = 0
      next
    }
     else if ($0 ~ /generation/ || $0 ~ /diff/) {
      next
    } else if ($0 ~ /kubectl.kubernetes.io\/last-applied-configuration/) {
      skip = 1
      next
    }
    else if ($0 ~ /app.kubernetes.io\/managed-by/ || $skip == 1) {
      next
    }
    else if ($1 ~ /(---|\+\+\+)/) {
      exit_code = 1
      print $1, $2
    } else {
      print $0
    }
  }
  END {exit exit_code}' <<< "$DIFF_OUTPUT"
FILTER_EXIT_CODE=$?

if (( FILTER_EXIT_CODE > 1 )); then
  exit "$FILTER_EXIT_CODE"
fi
if (( DIFF_EXIT_CODE > 1 )); then
  exit "$DIFF_EXIT_CODE"
fi
if (( FILTER_EXIT_CODE == 1 )); then
  exit 1
fi
exit 0
