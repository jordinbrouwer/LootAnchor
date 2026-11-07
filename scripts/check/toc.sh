#!/usr/bin/env bash
# Every file listed in the .toc must exist.
set -euo pipefail
status=0
while IFS= read -r line; do
  line="${line%$'\r'}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  if [[ ! -f "$line" ]]; then
    echo "Missing file in TOC: $line"
    status=1
  fi
done < LootAnchor.toc
exit $status
