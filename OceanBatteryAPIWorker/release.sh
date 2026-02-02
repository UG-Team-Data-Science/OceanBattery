#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI is required (https://cli.github.com/, sudo apt install gh)." >&2
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 <tag> [release-title]" >&2
  exit 1
fi

tag="$1"
title="${2:-$tag}"

dist_dir="OceanBatteryAPIWorker/dist"
archive="OceanBatteryAPIWorker_dist_${tag}.tgz"

if [ ! -d "$dist_dir" ]; then
  echo "ERROR: $dist_dir not found. Build the worker with mcc first." >&2
  exit 1
fi

tar -czf "$archive" -C "OceanBatteryAPIWorker" "dist"

gh release create "$tag" "$archive" -t "$title" -n "Worker binary (${tag})"

echo "Release created: $tag"
