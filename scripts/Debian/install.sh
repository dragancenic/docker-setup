#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo: sudo bash scripts/Debian/install.sh" >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot determine the Linux distribution." >&2
  exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
if [[ ${ID:-} != debian ]]; then
  echo "This script supports Debian only." >&2
  exit 1
fi

if [[ ${VERSION_ID:-} != 13 ]]; then
  echo "This script supports Debian 13 only; detected ${VERSION_ID:-unknown}." >&2
  exit 1
fi

if ! command -v systemctl >/dev/null || ! command -v apt-get >/dev/null; then
  echo "Debian with systemd and apt-get is required." >&2
  exit 1
fi

conflicts=(docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc)
installed_conflicts=()
for package in "${conflicts[@]}"; do
  if [[ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true) == 'install ok installed' ]]; then
    installed_conflicts+=("$package")
  fi
done
if ((${#installed_conflicts[@]})); then
  echo "Conflicting packages found: ${installed_conflicts[*]}" >&2
  echo "Review the existing installation and remove conflicts manually before retrying." >&2
  exit 1
fi

fresh_install=false
if [[ $(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null || true) != 'install ok installed' ]]; then
  fresh_install=true
fi
if [[ $fresh_install == true ]] && command -v docker >/dev/null; then
  echo "Docker is already present but is not installed as the docker-ce package. Review it manually before continuing." >&2
  exit 1
fi

echo "Installing Docker Engine and the Compose plugin for Debian ${VERSION_ID}."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

debian_codename=${VERSION_CODENAME:-}
if [[ -z $debian_codename ]]; then
  echo "Debian codename is missing from /etc/os-release." >&2
  exit 1
fi

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${debian_codename}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

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

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
systemctl is-active --quiet docker

docker --version
docker compose version
docker info --format 'Docker daemon: {{.ServerVersion}}'
echo "Docker is ready. Use sudo docker and sudo docker compose to manage it."
