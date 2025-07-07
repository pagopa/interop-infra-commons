#!/bin/bash
set -euo pipefail

help() {
    echo "Usage:
        [ -u | --untar ] Untar downloaded charts
        [ -v | --verbose ] Show debug messages
        [ -h | --help ] This help"
    exit 2
}

PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
ROOT_DIR="$PROJECT_DIR"

SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"



args=$#
untar=false
step=1
verbose=false
# Check args
for (( i=0; i<$args; i+=$step ))
do
    case "$1" in
        -u| --untar )
          untar=true
          step=1
          shift 1
          ;;
        -v| --verbose )
          verbose=true
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

function setupHelmDeps()
{
    untar=$1
    # Create charts directory and copy Chart.yaml into it
    cd "$ROOT_DIR"

    if [[ $verbose == true ]]; then
        echo "Creating directory charts"
    fi
    mkdir -p charts

    if [[ $verbose == true ]]; then
        echo "Copying Chart.yaml to charts"
    fi
    cp Chart.yaml charts/
    # Execute helm commands
    echo "# Helm dependencies setup #"
    echo "-- Add PagoPA eks repos --"
    helm repo add interop-eks-microservice-chart https://pagopa.github.io/interop-eks-microservice-chart > /dev/null
    helm repo add interop-eks-cronjob-chart https://pagopa.github.io/interop-eks-cronjob-chart > /dev/null

    echo "-- Update PagoPA eks repo --"
    helm repo update interop-eks-microservice-chart > /dev/null
    helm repo update interop-eks-cronjob-chart > /dev/null

    if [[ $verbose == true ]]; then
        echo "-- Search PagoPA charts in repo --"
    fi
    helm search repo interop-eks-microservice-chart > /dev/null
    helm search repo interop-eks-cronjob-chart > /dev/null

    if [[ $verbose == true ]]; then
        echo "-- List chart dependencies --"
    fi
    helm dep list charts | awk '{printf "%-35s %-15s %-20s\n", $1, $2, $3}'

    cd charts

    if [[ $verbose == true ]]; then
        echo "-- Build chart dependencies --"
    fi
    # Execute helm dependency update command
    dep_up_result=$(helm dep up)
    if [[ $verbose == true ]]; then
        echo $dep_up_result
    fi

    cd "$ROOT_DIR"

    if [[ $untar == true ]]; then
    # Untar downloaded charts to the root charts directory
        for filename in charts/charts/*.tgz; do
            [ -e "$filename" ] || continue
            echo "Processing $filename"
            basename_file=$(basename "$filename" .tgz)
            chart_name="${basename_file%-*}"
            target_dir="charts/$chart_name"

            echo "→ Extracting to $target_dir"
            mkdir -p "$target_dir"
            tar -xzf "$filename" -C "$target_dir" --strip-components=1
            rm -f "$filename"
        done
    if [[ $verbose == true ]]; then
        echo "Removing charts/charts directory"
    fi
    rm -rf charts/charts

    set +e
    # Install helm diff plugin, first check if it is already installed
    if [[ $(helm plugin list | grep -c 'diff') -eq 0 ]]; then
        if [[ $verbose == true ]]; then
            echo "Installing helm-diff plugin"
        fi
        helm plugin install https://github.com/databus23/helm-diff
        diff_plugin_result=$?
    else
        if [[ $verbose == true ]]; then
            echo "Helm-diff plugin already installed"
        fi
        diff_plugin_result=0
    fi
    set -e

    echo "-- Helm dependencies setup ended --"
    exit 0
}

setupHelmDeps $untar