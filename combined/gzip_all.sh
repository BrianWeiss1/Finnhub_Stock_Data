#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR" || exit

mapfile -d '' csv_files < <(find "$SCRIPT_DIR" -type f -name "*.csv" -print0)

if [ "${#csv_files[@]}" -gt 0 ]; then
    echo "Compressing all .csv files under $SCRIPT_DIR (recursively)..."
    printf '%s\0' "${csv_files[@]}" | xargs -0 -P "$(nproc)" -I{} sh -c 'echo "Processing: {}"; gzip "{}"'
    echo "Done."
else
    echo "No .csv files found under $SCRIPT_DIR."
fi