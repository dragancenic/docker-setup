# Docker Setup

Prepare an Ubuntu server for Docker workloads. The installer currently supports Ubuntu 22.04, 24.04, and 26.04 LTS. This repository sets up Docker and its supporting components; application deployment belongs in separate projects.

## What the installer sets up

- Docker Engine and CLI, containerd, Buildx, and the Compose plugin from [Docker's official apt repository](https://docs.docker.com/engine/install/ubuntu/)
- Docker service enabled at boot
- Docker JSON log rotation (10 MB, 3 files) on a fresh installation when `/etc/docker/daemon.json` does not already exist

The script does not remove existing Docker packages or data. If it finds conflicting packages, it stops and lists them. It does not add users to the `docker` group.

## Optional Ubuntu host preparation

Run these scripts separately when their settings match your server:

```bash
# Show a read-only host summary before and after setup.
bash scripts/check-ubuntu-host.sh

# Set an IANA timezone (example only).
sudo bash scripts/set-ubuntu-timezone.sh Europe/Belgrade

# Allow the actual SSH port before enabling UFW. Add host ports only as needed.
sudo bash scripts/configure-ubuntu-firewall.sh --ssh-port 22
# Example with additional host ports:
sudo bash scripts/configure-ubuntu-firewall.sh --ssh-port 22 --allow-tcp 80 --allow-tcp 443
```

The firewall script asks UFW to confirm activation. Keep the current SSH session open and verify a second connection before closing it. If the current session provides its SSH port, the script rejects a different `--ssh-port` value. Running UFW does **not** restrict Docker-published container ports; review those ports separately using [Docker's firewall guidance](https://docs.docker.com/engine/network/packet-filtering-firewalls/).

The host check reports whether `unattended-upgrades` is installed. Ubuntu Server normally includes automatic security updates, but review the host's actual policy before relying on them. See [Ubuntu's security update guidance](https://documentation.ubuntu.com/security/security-updates/).

## Quick start

Copy this folder to an Ubuntu server where you have sudo access, then run:

```bash
cd docker-setup
sudo bash scripts/install-ubuntu.sh
sudo docker compose version
sudo docker info --format '{{.ServerVersion}}'
```

You can rerun the script to install missing packages. Use `sudo docker` and `sudo docker compose` for administration. Membership in the `docker` group grants root-level privileges; add a user only after making that decision deliberately. See [Docker's Linux post-installation guide](https://docs.docker.com/engine/install/linux-postinstall/).

## Before production use

Review the [Ubuntu production checklist](docs/ubuntu-production-checklist.md) for SSH access, firewall rules, updates, backups, monitoring, and published container ports. The Docker installer does not change SSH, UFW, the system timezone, or swap; the optional scripts handle UFW and timezone independently.

Docker warns that published container ports can bypass UFW rules. Plan container access using [Docker's firewall guidance](https://docs.docker.com/engine/network/packet-filtering-firewalls/).
