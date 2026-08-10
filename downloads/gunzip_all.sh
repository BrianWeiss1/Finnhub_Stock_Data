#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR" || exit

mapfile -d '' csv_files < <(find "$SCRIPT_DIR" -type f -name "*.csv.gz" -print0)

if [ "${#csv_files[@]}" -gt 0 ]; then
    echo "Decompressing all .csv.gz files under $SCRIPT_DIR (recursively)..."
    printf '%s\0' "${csv_files[@]}" | xargs -0 -P 8 -I{} sh -c 'echo "Processing: {}"; gunzip "{}"'
    echo "Done."
else
    echo "No .csv files found under $SCRIPT_DIR."
fi