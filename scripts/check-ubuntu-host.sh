#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  source /etc/os-release
  echo "OS: ${PRETTY_NAME:-unknown}"
fi
echo "Architecture: $(uname -m)"
echo "Disk space:"
df -h /
echo "Memory:"
free -h

if command -v timedatectl >/dev/null; then
  echo "Timezone: $(timedatectl show --property=Timezone --value 2>/dev/null || echo unavailable)"
  echo "Time synchronized: $(timedatectl show --property=NTPSynchronized --value 2>/dev/null || echo unavailable)"
fi
if command -v docker >/dev/null; then
  docker --version
  docker compose version 2>/dev/null || echo "Docker Compose plugin unavailable or inaccessible."
else
  echo "Docker: not installed"
fi
if command -v systemctl >/dev/null; then
  echo "Docker service: $(systemctl is-active docker 2>/dev/null || true)"
fi
if command -v ufw >/dev/null; then
  if ufw_status=$(LC_ALL=C ufw status 2>/dev/null); then
    echo "UFW: ${ufw_status%%$'\n'*}"
  else
    echo "UFW: status unavailable (try sudo)"
  fi
fi
if command -v dpkg-query >/dev/null; then
  if [[ $(dpkg-query -W -f='${Status}' unattended-upgrades 2>/dev/null || true) == 'install ok installed' ]]; then
    echo "unattended-upgrades: installed (review its policy separately)"
  else
    echo "unattended-upgrades: not installed"
  fi
fi
