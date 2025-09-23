#!/usr/bin/env bash
set -euo pipefail

# defaults
MODE="go"
INPUT_PATH=""
FORMAT="tsv"
CONFIG_PATH=""
VERBOSE="false"
WORKDIR="."
OUTPUT_PATH="stay_or_go_report.tsv"
MIN_SCORE=""

# parse args --key=value
for arg in "$@"; do
  case $arg in
    --mode=*) MODE="${arg#*=}";;
    --input-path=*) INPUT_PATH="${arg#*=}";;
    --format=*) FORMAT="${arg#*=}";;
    --config-path=*) CONFIG_PATH="${arg#*=}";;
    --verbose=*) VERBOSE="${arg#*=}";;
    --workdir=*) WORKDIR="${arg#*=}";;
    --output-path=*) OUTPUT_PATH="${arg#*=}";;
    --min-score=*) MIN_SCORE="${arg#*=}";;
  esac
done

echo "==> stay_or_go action starting"
echo "mode=${MODE} workdir=${WORKDIR} format=${FORMAT} output=${OUTPUT_PATH} min_score=${MIN_SCORE}"

# map INPUT_GITHUB_TOKEN -> env(GITHUB_TOKEN/GH_TOKEN) and also pass as CLI flag
TOKEN="${INPUT_GITHUB_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -n "$TOKEN" ]]; then
  export GITHUB_TOKEN="$TOKEN"
  export GH_TOKEN="$TOKEN"
fi

# move to target repo dir
cd "${WORKDIR}"

 # Build command: stay_or_go <mode> [flags]
CMD=(stay_or_go "${MODE}")
[[ -n "${INPUT_PATH}" ]]  && CMD+=(-i "${INPUT_PATH}")
[[ -n "${CONFIG_PATH}" ]] && CMD+=(-c "${CONFIG_PATH}")
[[ "${VERBOSE}" == "true" ]] && CMD+=(-v)
CMD+=(-f "${FORMAT}")

# append token flag if available (do NOT echo the secret)
if [[ -n "${TOKEN:-}" ]]; then
  CMD+=(-g "$TOKEN")
fi

# Build a redacted command for logging (no secrets)
DISPLAY_CMD=(stay_or_go "${MODE}")
[[ -n "${INPUT_PATH}" ]]  && DISPLAY_CMD+=(-i "${INPUT_PATH}")
[[ -n "${CONFIG_PATH}" ]] && DISPLAY_CMD+=(-c "${CONFIG_PATH}")
[[ "${VERBOSE}" == "true" ]] && DISPLAY_CMD+=(-v)
DISPLAY_CMD+=(-f "${FORMAT}")

echo "==> Running: ${DISPLAY_CMD[*]} > ${OUTPUT_PATH}"
set +e
"${CMD[@]}" > "${OUTPUT_PATH}"
CODE=$?
set -e

if [[ $CODE -ne 0 ]]; then
  echo "::warning::stay_or_go exited with non-zero status (${CODE})."
fi

if [[ ! -s "${OUTPUT_PATH}" ]]; then
  echo "::error::Report not created or empty at ${OUTPUT_PATH}"
  exit 1
fi

# Check min_score if specified (only for TSV format)
if [[ -n "${MIN_SCORE}" ]] && [[ "${FORMAT}" == "tsv" ]]; then
  echo "==> Checking scores against minimum threshold: ${MIN_SCORE}"

  # Skip header line and check Score column (9th column)
  # Also skip lines where Skip column (10th column) is "true"
  LOW_SCORES=$(awk -F'\t' -v min_score="${MIN_SCORE}" '
    NR > 1 && $10 != "true" && $9 < min_score {
      printf "%s (score: %s)\n", $1, $9
    }
  ' "${OUTPUT_PATH}")

  if [[ -n "${LOW_SCORES}" ]]; then
    echo "::error::The following libraries have scores below the minimum threshold (${MIN_SCORE}):"
    echo "${LOW_SCORES}"
    exit 1
  else
    echo "==> All libraries meet the minimum score threshold"
  fi
fi

# expose output to GitHub Actions (only when running in GitHub Actions)
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "report_path=${OUTPUT_PATH}" >> "$GITHUB_OUTPUT"
fi
echo "==> Report generated at ${OUTPUT_PATH}"