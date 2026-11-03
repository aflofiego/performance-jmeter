# Performance Testing with Apache JMeter

[![Performance Tests](https://github.com/aflofiego/performance-jmeter/actions/workflows/performance.yml/badge.svg)](https://github.com/aflofiego/performance-jmeter/actions/workflows/performance.yml)

Load testing project built with **Apache JMeter 5.6**, simulating users who go through the full booking lifecycle of the public [Restful Booker](https://restful-booker.herokuapp.com/apidoc/index.html) API. It runs from **GitHub Actions**, produces the JMeter HTML dashboard and fails the build when performance criteria are not met.

## What the test does

Each virtual user repeats this flow for the duration of the test:

1. `POST /auth` — authenticates and extracts the token (JSON Extractor).
2. `GET /booking` — lists bookings.
3. `POST /booking` — creates a booking with random data and extracts its id.
4. `GET /booking/{id}` — reads the booking just created.
5. `DELETE /booking/{id}` — deletes it using the token, leaving no test data behind.

Between steps there is a random think time (1–1.5 s) to model real users.

## Highlights

- **Correlation** — token and booking id extracted from responses and reused in later requests.
- **Dynamic data** — JMeter functions (`__RandomString`, `__Random`, `__timeShift`) for unique bookings and future dates.
- **Assertions** — status code per request, token presence, and a response time SLA.
- **Parameterized plan** — users, ramp-up, duration, think time, SLA and host are passed as properties, with no edits to the `.jmx`.
- **Load profiles** — smoke, load and stress profiles in `run.sh`.
- **Pass/fail criteria** — `scripts/check-thresholds.sh` fails the run if the error rate or the 95th percentile go over the limits.
- **CI/CD** — GitHub Actions installs and caches JMeter, runs the selected profile, uploads the HTML dashboard and writes a results table on the run summary.

## Project structure

```
performance-jmeter/
├── .github/workflows/performance.yml   # CI pipeline
├── scripts/check-thresholds.sh         # Pass/fail criteria
├── test-plans/booking-lifecycle.jmx    # JMeter test plan
└── run.sh                              # Runs a profile and builds the report
```

## Load profiles

| Profile  | Users | Ramp-up | Duration | Purpose |
|----------|------:|--------:|---------:|---------|
| `smoke`  | 1     | 1 s     | 30 s     | Validates the script works end to end |
| `load`   | 10    | 60 s    | 5 min    | Expected load |
| `stress` | 25    | 60 s    | 5 min    | Above expected load |

The push and pull request pipeline only runs `smoke`. The `load` and `stress` profiles are run manually from the **Actions** tab.

## Pass/fail criteria

| Metric          | Threshold  | Override with   |
|-----------------|------------|-----------------|
| Error rate      | ≤ 5 %      | `MAX_ERROR_PCT` |
| 95th percentile | ≤ 3000 ms  | `MAX_P95_MS`    |
| Request SLA     | ≤ 3000 ms  | `-Jsla_ms`      |

## Running locally

Requirements: Java 17+, [Apache JMeter 5.6+](https://jmeter.apache.org/download_jmeter.cgi) on the `PATH`, and `jq`.

```bash
./run.sh smoke     # or: load, stress
```

The HTML dashboard is written to `results/<profile>/html-report/index.html`.

To run the plan directly with custom values:

```bash
jmeter -n -t test-plans/booking-lifecycle.jmx -l results.jtl -e -o report \
  -Jusers=5 -Jrampup=30 -Jduration=120 -Jthink_time_ms=1000 -Jsla_ms=3000
```

To edit the plan, open `test-plans/booking-lifecycle.jmx` in the JMeter GUI.

## A note on the target

Restful Booker is a free shared practice API, so the profiles are deliberately light. Point the plan at your own environment with `-Jhost=your-host -Jprotocol=http` before running heavier tests.

## Author

**Alex Figueroa Lofiego** — QA Automation Engineer Sr
[LinkedIn](https://www.linkedin.com/in/alex-figueroa-lofiego-bb5926158/)
