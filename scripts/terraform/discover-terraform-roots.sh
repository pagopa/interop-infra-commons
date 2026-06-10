#!/usr/bin/env bash
set -euo pipefail

mode="${1:-auto}"
base_path="${2:-.}"

roots="[]"

add_root() {
  local path="$1"
  local name
  name="$(basename "$path")"

  roots="$(echo "$roots" | jq -c \
    --arg path "$path" \
    --arg name "$name" \
    '. + [{"path": $path, "name": $name}]')"
}

has_tf_files() {
  local dir="$1"

  find "$dir" -maxdepth 1 -type f -name '*.tf' -print -quit | grep -q .
}

discover_modules_roots() {
  local modules_path="$1"

  if [ ! -d "$modules_path" ]; then
    return 0
  fi

  while IFS= read -r dir; do
    if has_tf_files "$dir"; then
      add_root "$dir"
    fi
  done < <(find "$modules_path" -mindepth 1 -maxdepth 1 -type d | sort)
}

discover_env_roots() {
  local search_path="$1"

  if [ ! -d "$search_path" ]; then
    return 0
  fi

  while IFS= read -r env_dir; do
    local root_dir

    root_dir="$(dirname "$env_dir")"

    if has_tf_files "$root_dir"; then
      add_root "$root_dir"
    fi
  done < <(find "$search_path" -type d -name env | sort)
}

case "$mode" in
  modules)
    discover_modules_roots "$base_path"
    ;;

  env-roots)
    discover_env_roots "$base_path"
    ;;

  auto)
    # 1. Root con cartella env.
    discover_env_roots "$base_path"

    # 2. Moduli diretti, utile per terraform/modules/*
    if [ -d "$base_path/terraform/modules" ]; then
      discover_modules_roots "$base_path/terraform/modules"
    fi
    
    roots="$(echo "$roots" | jq -c 'unique_by(.path)')"
    ;;

  *)
    echo "Unsupported discovery mode: $mode" >&2
    exit 1
    ;;
esac

echo "{\"include\":$roots}"