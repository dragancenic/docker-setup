#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage: sudo bash scripts/configure-ubuntu-firewall.sh --ssh-port PORT [--allow-tcp PORT] [--allow-udp PORT]...

Allow the specified SSH port before enabling UFW. Additional ports are optional.
Docker-published container ports can bypass UFW rules.
EOF
}

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot determine the Linux distribution." >&2
  exit 1
fi
# shellcheck source=/dev/null
source /etc/os-release
if [[ ${ID:-} != ubuntu ]]; then
  echo "This script supports Ubuntu only." >&2
  exit 1
fi

valid_port() {
  [[ $1 =~ ^[0-9]+$ ]] && ((10#$1 >= 1 && 10#$1 <= 65535))
}

ssh_port=''
extra_rules=()
while (($#)); do
  case $1 in
    --ssh-port|--allow-tcp|--allow-udp)
      option=$1
      if (($# < 2)) || ! valid_port "$2"; then
        echo "A valid port (1-65535) is required after ${option}." >&2
        usage >&2
        exit 2
      fi
      case $option in
        --ssh-port) ssh_port=$((10#$2)) ;;
        --allow-tcp) extra_rules+=("$((10#$2))/tcp") ;;
        --allow-udp) extra_rules+=("$((10#$2))/udp") ;;
      esac
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z $ssh_port ]]; then
  echo "Specify the SSH port with --ssh-port before changing firewall rules." >&2
  usage >&2
  exit 2
fi

if [[ -n ${SSH_CONNECTION:-} ]]; then
  read -r _ _ _ connected_port <<< "$SSH_CONNECTION"
  if [[ $connected_port != "$ssh_port" ]]; then
    echo "The current SSH session uses port ${connected_port}, but --ssh-port is ${ssh_port}. Aborting." >&2
    exit 1
  fi
fi

if ! command -v ufw >/dev/null; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y ufw
fi

echo "Allowing SSH on ${ssh_port}/tcp before enabling UFW."
ufw allow "${ssh_port}/tcp"
for rule in "${extra_rules[@]}"; do
  ufw allow "$rule"
done

ufw_status=$(LC_ALL=C ufw status)
if [[ $ufw_status != *'Status: active'* ]]; then
  ufw default deny incoming
  ufw default allow outgoing
  echo "UFW will now ask you to confirm activation. Keep your current SSH session open and test a second connection afterward."
  ufw enable
fi

ufw status verbose
echo "Reminder: Docker-published ports can bypass UFW. Review each published container port separately."
