#!/usr/bin/env bash
# Regression checks for bin/extract-open. The fixture is built at run time so
# the Slack timestamps sit either side of the window relative to now.
# Run from anywhere: tests/extract-open/run.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
now=$(date +%s)
recent=$((now - 3 * 86400)).000100
old=$((now - 20 * 86400)).000200
fixture=$(mktemp)
trap 'rm -f "$fixture"' EXIT
cat > "$fixture" <<MD
# Open items — 2026-10-19 10:23

5 items  ·  2 owed by me  ·  0 follow-up  ·  0 owed to me  ·  3 meeting actions

## acme

- [ ] Send Jane the config
  - **owed-by-me** · Jane · 3d — "can you send the config?"
  <!-- slack:C0123:$recent -->

- [ ] Reply to Rick about the migration plan
  - **owed-by-me** · Rick · 20d · DM
  <!-- slack:D0456:$old -->

- [x] Send Steve the policy JSON
  - **action** · Steve · from 2026-10-10 Acme sync
  <!-- gong:5802802678030503927:9f2e -->

## uncategorised

- [ ] Write up the archive-tier findings
  - **action** · Kai · from 2026-10-01 team weekly
  with a second context line
  <!-- zoom:38DCDB7C-74B1-442F-BE85-390DF0BB96CC:1a4b -->
- [ ] hand-added line with no anchor

- [ ] Look up which teams churned
  - **owed-by-me** · me · hand-added
  <!-- manual:acme-churn -->

---
Last run: 2026-10-19 10:23 Europe/London
MD
out=$("${EO:-$here/../../bin/extract-open}" "$fixture")
fail=0
check() {  # <description> <jq expression that must print true>
    if [[ $(jq -r "$2" <<<"$out") == true ]]; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi
}
check "ticked and anchorless items are left out" 'length == 4'
check "Slack item inside the window is not carried when absent" \
    '[.[] | select(.anchor | startswith("slack:C0123"))][0].carry_if_absent == false'
check "Slack item past the window is carried" \
    '[.[] | select(.anchor | startswith("slack:D0456"))][0].carry_if_absent == true'
check "meeting action is always carried" \
    '[.[] | select(.source == "zoom")][0].carry_if_absent == true'
check "manual anchor is always carried" \
    '[.[] | select(.source == "manual")][0].carry_if_absent == true'
check "section is the customer heading" \
    '[.[] | select(.source == "zoom")][0].section == "uncategorised"'
check "block is verbatim, task line first, all context lines kept" \
    '[.[] | select(.source == "zoom")][0].block | (split("\n") | length == 4) and startswith("- [ ] Write up the archive-tier findings")'
wide=$("${EO:-$here/../../bin/extract-open}" --slack-days 30 "$fixture")
if [[ $(jq -r '[.[] | select(.anchor | startswith("slack:D0456"))][0].carry_if_absent' <<<"$wide") == false ]]
then echo "ok   --slack-days widens the window"; else echo "FAIL --slack-days widens the window"; fail=1; fi
if [[ $("${EO:-$here/../../bin/extract-open}" /nonexistent/open-items.md) == "[]" ]]
then echo "ok   missing file is an empty array"; else echo "FAIL missing file is an empty array"; fail=1; fi
exit $fail
