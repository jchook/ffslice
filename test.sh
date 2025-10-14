#!/bin/bash
#
# Unit tests for ffslice
#
# This script expects set -e and will exit on the first failure.
# To debug a failing test, add set -x somewhere inside the test function.
# To run a single test, pass part of the test description as the first argument.
#

# Enable test mode
export FFSLICE_TEST_MODE=1

# Source the ffslice script to get access to functions
source "$(dirname "$0")/ffslice"

# Blow up on errors
set -e

# Create temp dir for test output files
mkdir -p /tmp/ffslice-test
cd /tmp/ffslice-test

# ---
# Unit tests for timetosec
# ---

test_timetosec_seconds() {
  result=$(timetosec "30")
  [ "$result" -eq 30 ]
}

test_timetosec_minutes_seconds() {
  result=$(timetosec "1:30")
  [ "$result" -eq 90 ]
}

test_timetosec_hours_minutes_seconds() {
  result=$(timetosec "1:30:45")
  [ "$result" -eq 5445 ]
}

test_timetosec_zero_padded() {
  result=$(timetosec "01:05:03")
  [ "$result" -eq 3903 ]
}

# ---
# Integration tests for command construction
# ---

test_absolute_start_end() {
  output=$(main test.mp4 1:00 2:00)
  echo "$output" | grep -q -- "-ss 60"
  echo "$output" | grep -q -- "-i test.mp4"
  echo "$output" | grep -q -- "-t 60"
  echo "$output" | grep -q -- "-c copy"
}

test_absolute_start_no_end() {
  output=$(main test.mp4 30)
  echo "$output" | grep -q -- "-ss 30"
  echo "$output" | grep -q -- "-i test.mp4"
  echo "$output" | grep -q -- "-c copy"
  ! echo "$output" | grep -q -- "-t"
}

test_relative_start_from_end() {
  output=$(main test.mp4 -30)
  echo "$output" | grep -q -- "-sseof -30"
  echo "$output" | grep -q -- "-i test.mp4"
}

test_relative_end_from_start() {
  output=$(main test.mp4 1:00 +30)
  echo "$output" | grep -q -- "-ss 60"
  echo "$output" | grep -q -- "-t 30"
}

test_relative_end_from_file_end() {
  output=$(main test.mp4 1:00 -5)
  echo "$output" | grep -q -- "-ss 60"
  echo "$output" | grep -q -- "-to -5"
}

test_default_output_filename() {
  output=$(main test.mp4 1:00 2:00)
  echo "$output" | grep -q "test-1.00-2.00.mp4"
}

test_custom_output_filename() {
  output=$(main test.mp4 1:00 2:00 custom.mp4)
  echo "$output" | grep -q "custom.mp4"
}

test_output_directory() {
  mkdir -p /tmp/ffslice-test/outdir
  output=$(main test.mp4 1:00 2:00 /tmp/ffslice-test/outdir)
  echo "$output" | grep -q "/tmp/ffslice-test/outdir/test-1.00-2.00.mp4"
}

test_colon_replacement_in_filename() {
  output=$(main test.mp4 1:00 2:00)
  echo "$output" | grep -q "test-1.00-2.00.mp4"
  ! echo "$output" | grep -q "1:00"
}

test_forward_extra_args() {
  output=$(main test.mp4 1:00 2:00 out.mp4 -preset fast -vf scale=640:480)
  echo "$output" | grep -q -- "-preset fast"
  echo "$output" | grep -q -- "-vf scale=640:480"
}

test_hours_minutes_seconds_format() {
  output=$(main test.mp4 0:01:30 0:02:45)
  echo "$output" | grep -q -- "-ss 90"
  echo "$output" | grep -q -- "-t 75"
}

# ---
# Error handling tests
# ---

test_absolute_end_with_relative_start_fails() {
  if main test.mp4 -30 1:00 2>&1 | grep -q "Absolute end time not supported"; then
    return 0
  else
    return 1
  fi
}

test_end_before_start_fails() {
  if main test.mp4 2:00 1:00 2>&1 | grep -q "end must be after start"; then
    return 0
  else
    return 1
  fi
}

test_missing_arguments_shows_usage() {
  if main 2>&1 | grep -q "Usage:"; then
    return 0
  else
    return 1
  fi
}

test_missing_start_shows_usage() {
  if main test.mp4 2>&1 | grep -q "Usage:"; then
    return 0
  else
    return 1
  fi
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

# Clean-up
rm -rf /tmp/ffslice-test

echo ""
echo "All tests passed!"
