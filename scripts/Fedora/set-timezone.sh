#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi
if (($# != 1)); then
  echo "Usage: sudo bash scripts/Fedora/set-timezone.sh AREA/CITY" >&2
  exit 2
fi
if [[ ! -r /etc/os-release ]]; then
  echo "Cannot determine the Linux distribution." >&2
  exit 1
fi
# shellcheck source=/dev/null
source /etc/os-release
if [[ ${ID:-} != fedora ]]; then
  echo "This script supports Fedora only." >&2
  exit 1
fi
if ! command -v timedatectl >/dev/null; then
  echo "timedatectl is required." >&2
  exit 1
fi

timezone=$1
if ! timedatectl list-timezones --no-pager | awk -v target="$timezone" '$0 == target { found = 1 } END { exit !found }'; then
  echo "Unknown timezone: ${timezone}. List valid values with: timedatectl list-timezones" >&2
  exit 2
fi

timedatectl set-timezone "$timezone"
timedatectl show --property=Timezone --value
