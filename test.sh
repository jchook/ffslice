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
  local haystack="$1"
  shift
  for needle in "$@"; do
    echo "$haystack" | contains "$needle" || return 1
  done
}

# ---
# Unit tests for timetosec
# ---

test_timetosec_seconds() {
  result=$(timetosec "30")
  equals "$result" "30"
}

test_timetosec_minutes_seconds() {
  result=$(timetosec "1:30")
  equals "$result" "90"
}

test_timetosec_hours_minutes_seconds() {
  result=$(timetosec "1:30:45")
  equals "$result" "5445"
}

test_timetosec_zero_padded() {
  result=$(timetosec "01:05:03")
  equals "$result" "3903"
}

# ---
# Integration tests for command construction
# ---

test_absolute_start_end() {
  contains_all "$(ffslice test.mp4 1:00 2:00)" "-ss 60" "-i test.mp4" "-t 60" "-c copy"
}

test_absolute_start_no_end() {
  output=$(ffslice test.mp4 30)
  contains_all "$output" "-ss 30" "-i test.mp4" "-c copy"
  echo "$output" | not_contains "-t"
}

test_relative_start_from_end() {
  contains_all "$(ffslice test.mp4 -30)" "-sseof -30" "-i test.mp4"
}

test_relative_end_from_start() {
  contains_all "$(ffslice test.mp4 1:00 +30)" "-ss 60" "-t 30"
}

test_relative_end_from_file_end() {
  contains_all "$(ffslice test.mp4 1:00 -5)" "-ss 60" "-to -5"
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
  contains_all "$(ffslice test.mp4 1:00 2:00 out.mp4 -preset fast -vf scale=640:480)" "-preset fast" "-vf scale=640:480"
}

test_hours_minutes_seconds_format() {
  contains_all "$(ffslice test.mp4 0:01:30 0:02:45)" "-ss 90" "-t 75"
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
for test_fn in $(declare -F | awk '/declare -f test_/ {print $NF}'); do
  test_desc=$(echo "$test_fn" | sed 's/test_//' | sed 's/_/ /g')
  if [ -n "${1:-}" ] && grep -qviE "$1" <<< "$test_desc"; then
    continue
  fi
  printf "%s" "${GRAY}+${NONE} $test_desc"
  $test_fn
  printf "\r%s\n" "${GREEN}✓${NONE}"
done

echo ""
echo "All tests passed!"
