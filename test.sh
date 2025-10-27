#!/bin/bash
#
# Unit tests for ffslice
#
# This script expects set -e and will exit on the first failure.
# To debug a failing test, add set -x somewhere inside the test function.
# To run a single test, pass part of the test description as the first argument.
#

# Enable dry-run mode (prints commands instead of executing)
export FFSLICE_DRY_RUN=1

# Source the ffslice script to get access to functions
source "$(dirname "$0")/ffslice"

# Blow up on errors
set -e

# ---
# Test helpers
# Add more helpers here as needed to keep tests readable
# ---

contains() {
  grep -q -- "$@"
}

not_contains() {
  ! grep -q -- "$@"
}

equals() {
  [ "$1" = "$2" ]
}

contains_all() {
  local haystack="$(cat)"
  for needle in "$@"; do
    echo "$haystack" | contains "$needle" || return 1
  done
}

# ---
# Unit tests for timetosec
# ---

test_timetosec_seconds() {
  equals "$(timetosec "30")" "30"
}

test_timetosec_minutes_seconds() {
  equals "$(timetosec "1:30")" "90"
}

test_timetosec_hours_minutes_seconds() {
  equals "$(timetosec "1:30:45")" "5445"
}

test_timetosec_zero_padded() {
  equals "$(timetosec "01:05:03")" "3903"
}

test_timetosec_prevents_octal_interpretation() {
  equals "$(timetosec "1:09")" "69" # Nice
}

# ---
# Integration tests for command construction
# ---

test_absolute_start_end() {
  ffslice test.mp4 1:00 2:00 | contains_all "-ss 60" "-i test.mp4" "-t 60" "-c copy"
}

test_absolute_start_no_end() {
  output=$(ffslice test.mp4 30)
  echo "$output" | contains_all "-ss 30" "-i test.mp4" "-c copy"
  echo "$output" | not_contains "-t"
}

test_relative_start_from_end() {
  ffslice test.mp4 -30 | contains_all "-sseof -30" "-i test.mp4"
}

test_relative_end_from_start() {
  ffslice test.mp4 1:00 +30 | contains_all "-ss 60" "-t 30"
}

test_relative_end_from_file_end() {
  ffslice test.mp4 1:00 -5 | contains_all "-ss 60" "-to -5"
}

test_default_output_filename() {
  ffslice test.mp4 1:00 2:00 | contains "test-1.00-2.00.mp4"
}

test_custom_output_filename() {
  ffslice test.mp4 1:00 2:00 custom.mp4 | contains "custom.mp4"
}

test_output_directory() {
  local tmpdir=$(mktemp -d)
  ffslice test.mp4 1:00 2:00 "$tmpdir" | contains "$tmpdir/test-1.00-2.00.mp4"
  rm -rf "$tmpdir"
}

test_colon_replacement_in_filename() {
  output=$(ffslice test.mp4 1:00 2:00)
  echo "$output" | contains "test-1.00-2.00.mp4"
  echo "$output" | not_contains "1:00"
}

test_forward_extra_args() {
  ffslice test.mp4 1:00 2:00 out.mp4 -preset fast -vf scale=640:480 | contains_all "-preset fast" "-vf scale=640:480"
}

test_hours_minutes_seconds_format() {
  ffslice test.mp4 0:01:30 0:02:45 | contains_all "-ss 90" "-t 75"
}

# ---
# Error handling tests
# ---

test_absolute_end_with_relative_start_fails() {
  ffslice test.mp4 -30 1:00 2>&1 | contains "Absolute end time not supported"
}

test_end_before_start_fails() {
  ffslice test.mp4 2:00 1:00 2>&1 | contains "end must be after start"
}

test_missing_arguments_shows_usage() {
  ffslice 2>&1 | contains "Usage:"
}

test_missing_start_shows_usage() {
  ffslice test.mp4 2>&1 | contains "Usage:"
}

# ---
# Test harness
# ---

# Colorful output
if [ -t 1 ]; then IS_TTY=1; else IS_TTY=; fi
ttput() {
  if [ "$IS_TTY" = 1 ]; then
    tput "$@" 2>/dev/null
  fi
}
NONE="$(ttput sgr0)"
GREEN="$(ttput setaf 2)"
GRAY="$(ttput setaf 8)"

# Run the tests
# Note, this expects set -e and will exit on the first failure
FFSLICE_RAN_TESTS=
for test_fn in $(declare -F | awk '/declare -f test_/ {print $NF}'); do
  test_desc=$(echo "$test_fn" | sed 's/test_//' | sed 's/_/ /g')
  if [ -n "${1:-}" ] && grep -qviE "$1" <<< "$test_desc"; then
    continue
  fi
  FFSLICE_RAN_TESTS=1
  printf "%s" "${GRAY}+${NONE} $test_desc"
  $test_fn
  printf "\r%s\n" "${GREEN}✓${NONE}"
done

echo ""
if [ -z "$FFSLICE_RAN_TESTS" ]; then
  echo "No tests were run."
  exit 1
fi
echo "All tests passed!"
