#!/bin/sh
# Reads a test run's own verdict rather than letting it be grepped by eye.
set -u
# The iPad, deliberately. Ste's iPhone 17 Pro is the sim he demos from, and a
# test run installs over whatever is on it. Point this at his sim only when
# asked, with PBD_SIM=<udid>.
SIM="${PBD_SIM:-EAEE15F2-0E7D-43FD-84C9-DCB688719086}"   # iPad Pro 13-inch, iOS 26.5
LOG=$(mktemp -t pbd-testrun)
xcodebuild test \
  -project PBD.xcodeproj -scheme PBD \
  -destination "platform=iOS Simulator,id=$SIM" \
  "$@" >"$LOG" 2>&1
STATUS=$?
echo "log: $LOG"
echo "--- compile errors"; grep -E "error: " "$LOG" | grep -v "^/.*: error: -\[" | sort -u | head -20
echo "--- failures";      grep -E "error: -\[" "$LOG" | sort -u | head -40
echo "--- results";       grep -E "^Test Case .*(passed|failed|skipped)" "$LOG" | sort -u | head -40
echo "--- probe";         grep -E "PBD-PROBE" "$LOG" | head -40
echo "--- verdict";       grep -E "^\*\* TEST (SUCCEEDED|FAILED) \*\*|Executed .* tests" "$LOG" | tail -4
echo "exit: $STATUS"
exit $STATUS
