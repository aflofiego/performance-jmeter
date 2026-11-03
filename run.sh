#!/usr/bin/env bash
# Runs the booking lifecycle test plan with a predefined load profile
# and generates the JMeter HTML dashboard.
#
# Usage: ./run.sh [smoke|load|stress]
set -euo pipefail

PROFILE="${1:-smoke}"
PLAN="test-plans/booking-lifecycle.jmx"
OUT="results/${PROFILE}"

case "$PROFILE" in
  smoke)  USERS=1;  RAMPUP=1;  DURATION=30  ;;
  load)   USERS=10; RAMPUP=60; DURATION=300 ;;
  stress) USERS=25; RAMPUP=60; DURATION=300 ;;
  *) echo "Unknown profile: $PROFILE (use smoke, load or stress)"; exit 1 ;;
esac

rm -rf "$OUT"
mkdir -p "$OUT"

echo "Running profile '$PROFILE': $USERS users, ${RAMPUP}s ramp-up, ${DURATION}s duration"

jmeter -n \
  -t "$PLAN" \
  -l "$OUT/results.jtl" \
  -j "$OUT/jmeter.log" \
  -e -o "$OUT/html-report" \
  -Jusers="$USERS" \
  -Jrampup="$RAMPUP" \
  -Jduration="$DURATION" \
  -Jjmeter.reportgenerator.apdex_satisfied_threshold=1000 \
  -Jjmeter.reportgenerator.apdex_tolerated_threshold=3000

./scripts/check-thresholds.sh "$OUT/html-report/statistics.json"

echo "HTML report: $OUT/html-report/index.html"
