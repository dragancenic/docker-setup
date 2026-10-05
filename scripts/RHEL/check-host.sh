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
if command -v getenforce >/dev/null; then
  echo "SELinux: $(getenforce 2>/dev/null || echo unavailable)"
fi
if command -v subscription-manager >/dev/null; then
  if subscription-manager identity >/dev/null 2>&1; then
    echo "Red Hat subscription: registered"
  else
    echo "Red Hat subscription: not registered or status unavailable"
  fi
fi
if command -v docker >/dev/null; then
  docker --version
  docker compose version 2>/dev/null || echo "Docker Compose plugin unavailable or inaccessible."
else
  echo "Docker: not installed"
fi
if command -v systemctl >/dev/null; then
  echo "Docker service: $(systemctl is-active docker 2>/dev/null || true)"
  echo "firewalld service: $(systemctl is-active firewalld 2>/dev/null || true)"
fi
if command -v firewall-cmd >/dev/null; then
  if firewall_state=$(firewall-cmd --state 2>/dev/null); then
    echo "firewalld: ${firewall_state}"
  else
    echo "firewalld: status unavailable (try sudo)"
  fi
fi
