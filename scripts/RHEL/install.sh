#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo: sudo bash scripts/RHEL/install.sh" >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot determine the Linux distribution." >&2
  exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
if [[ ${ID:-} != rhel ]]; then
  echo "This script supports Red Hat Enterprise Linux only." >&2
  exit 1
fi

if [[ ${VERSION_ID%%.*} != 10 ]]; then
  echo "This script supports Red Hat Enterprise Linux 10 only; detected ${VERSION_ID:-unknown}." >&2
  exit 1
fi

if ! command -v systemctl >/dev/null || ! command -v dnf >/dev/null; then
  echo "Red Hat Enterprise Linux with systemd and dnf is required." >&2
  exit 1
fi
if ! command -v subscription-manager >/dev/null || ! subscription-manager identity >/dev/null 2>&1; then
  echo "Register this host with Red Hat Subscription Management before installing Docker." >&2
  exit 1
fi

conflicts=(docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc)
installed_conflicts=()
for package in "${conflicts[@]}"; do
  if rpm -q "$package" >/dev/null 2>&1; then
    installed_conflicts+=("$package")
  fi
done
if ((${#installed_conflicts[@]})); then
  echo "Conflicting packages found: ${installed_conflicts[*]}" >&2
  echo "Review the existing installation and remove conflicts manually before retrying." >&2
  exit 1
fi

fresh_install=false
if ! rpm -q docker-ce >/dev/null 2>&1; then
  fresh_install=true
fi
if [[ $fresh_install == true ]] && command -v docker >/dev/null; then
  echo "Docker is already present but is not installed as the docker-ce package. Review it manually before continuing." >&2
  exit 1
fi

echo "Installing Docker Engine and the Compose plugin for Red Hat Enterprise Linux ${VERSION_ID}."
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

# Configure log rotation only on a fresh install; preserve existing daemon settings.
if [[ $fresh_install == true && ! -e /etc/docker/daemon.json ]]; then
  install -m 0755 -d /etc/docker
  cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
  echo "Configured Docker log rotation for new containers."
else
  echo "Existing Docker daemon configuration was not changed."
fi

dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
systemctl is-active --quiet docker

docker --version
docker compose version
docker info --format 'Docker daemon: {{.ServerVersion}}'
echo "Docker is ready. Use sudo docker and sudo docker compose to manage it."
