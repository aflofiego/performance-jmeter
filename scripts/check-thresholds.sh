#!/usr/bin/env bash
# Fails (exit 1) when the run breaks the performance criteria.
# JMeter itself always exits 0, so this is what turns a slow or failing run into a red build.
#
# Usage: check-thresholds.sh <statistics.json> [max_error_pct] [max_p95_ms]
set -euo pipefail

STATS="$1"
MAX_ERROR_PCT="${2:-${MAX_ERROR_PCT:-5}}"
MAX_P95_MS="${3:-${MAX_P95_MS:-3000}}"

ERROR_PCT=$(jq '.Total.errorPct' "$STATS")
P95=$(jq '.Total.pct2ResTime' "$STATS")
SAMPLES=$(jq '.Total.sampleCount' "$STATS")
THROUGHPUT=$(jq '.Total.throughput' "$STATS")

printf "Samples: %s | Throughput: %.2f req/s | Error rate: %.2f%% | p95: %.0f ms\n" \
  "$SAMPLES" "$THROUGHPUT" "$ERROR_PCT" "$P95"

FAILED=0
if (( $(echo "$ERROR_PCT > $MAX_ERROR_PCT" | bc -l) )); then
  echo "FAIL: error rate ${ERROR_PCT}% is above ${MAX_ERROR_PCT}%"
  FAILED=1
fi
if (( $(echo "$P95 > $MAX_P95_MS" | bc -l) )); then
  echo "FAIL: p95 ${P95} ms is above ${MAX_P95_MS} ms"
  FAILED=1
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: all thresholds met (error rate <= ${MAX_ERROR_PCT}%, p95 <= ${MAX_P95_MS} ms)"
fi
exit "$FAILED"
