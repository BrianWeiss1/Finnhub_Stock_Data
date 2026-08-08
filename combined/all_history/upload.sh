#!/bin/bash
set -uo pipefail

BATCH_SIZE=900
MAX_RETRIES=500
PARALLEL=30   
LOG_FILE="upload_failures.log"
> "$LOG_FILE"

upload_one() {
    local release="$1"
    local file="$2"
    local attempt=1

    while (( attempt <= MAX_RETRIES )); do
        if gh release upload "$release" "$file" --clobber 2>>"$LOG_FILE"; then
            echo "OK: $file -> $release"
            return 0
        else
            wait_time=$(( attempt * 10 )) 
            echo "FAILED (attempt $attempt): $file -> $release. Retrying in ${wait_time}s..." | tee -a "$LOG_FILE"
            sleep "$wait_time"
            ((attempt++))
        fi
    done

    echo "GAVE UP: $file -> $release after $MAX_RETRIES attempts" | tee -a "$LOG_FILE"
    return 1
}

export -f upload_one
export MAX_RETRIES LOG_FILE

files=(*.csv.gz)
total=${#files[@]}
batch_num=1

for (( i=0; i<total; i+=BATCH_SIZE )); do
    release_name="data-2026-part${batch_num}"
    batch=("${files[@]:i:BATCH_SIZE}")

    gh release view "$release_name" >/dev/null 2>&1 || \
        gh release create "$release_name" --title "Stock Data 2026 Part ${batch_num}" --notes "Finnhub data batch ${batch_num}"

    existing=$(gh release view "$release_name" --json assets --jq '.assets[].name')

    to_upload=()
    for f in "${batch[@]}"; do
        if echo "$existing" | grep -qFx "$f"; then
            echo "Skipping $f (already in $release_name)"
        else
            to_upload+=("$f")
        fi
    done

    if (( ${#to_upload[@]} > 0 )); then
        printf '%s\n' "${to_upload[@]}" | xargs -P "$PARALLEL" -I{} bash -c 'upload_one "$0" "$1"' "$release_name" {}
    fi

    batch_num=$((batch_num + 1))
done

echo ""
echo "=== Upload run complete ==="
echo "Failures (if any) logged in $LOG_FILE"