#!/usr/bin/env bash
set -euo pipefail

OUTPUT_FILE="$1"
CMD="${@:2}"
$CMD > $OUTPUT_FILE
