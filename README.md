# Docker Setup

Prepare an Ubuntu, Debian, Fedora, or Red Hat Enterprise Linux server for Docker workloads. The installers currently support Ubuntu 22.04, 24.04, and 26.04 LTS, Debian 13, Fedora 44, and Red Hat Enterprise Linux 10. This repository sets up Docker and its supporting components; application deployment belongs in separate projects.

## What the installer sets up

- Docker Engine and CLI, containerd, Buildx, and the Compose plugin from Docker's official package repository for [Ubuntu](https://docs.docker.com/engine/install/ubuntu/), [Debian](https://docs.docker.com/engine/install/debian/), [Fedora](https://docs.docker.com/engine/install/fedora/), or [Red Hat Enterprise Linux](https://docs.docker.com/engine/install/rhel/)
- Docker service enabled at boot
- Docker JSON log rotation (10 MB, 3 files) on a fresh installation when `/etc/docker/daemon.json` does not already exist

The script does not remove existing Docker packages or data. If it finds conflicting packages, it stops and lists them. It does not add users to the `docker` group.

## Optional Ubuntu host preparation

Run these scripts separately when their settings match your server:

```bash
# Show a read-only host summary before and after setup.
bash scripts/Ubuntu/check-host.sh

# Set an IANA timezone (example only).
sudo bash scripts/Ubuntu/set-timezone.sh Europe/Belgrade

# Allow the actual SSH port before enabling UFW. Add host ports only as needed.
sudo bash scripts/Ubuntu/configure-firewall.sh --ssh-port 22
# Example with additional host ports:
sudo bash scripts/Ubuntu/configure-firewall.sh --ssh-port 22 --allow-tcp 80 --allow-tcp 443
```

The firewall script asks UFW to confirm activation. Keep the current SSH session open and verify a second connection before closing it. If the current session provides its SSH port, the script rejects a different `--ssh-port` value. Running UFW does **not** restrict Docker-published container ports; review those ports separately using [Docker's firewall guidance](https://docs.docker.com/engine/network/packet-filtering-firewalls/).

The host check reports whether `unattended-upgrades` is installed. Ubuntu Server normally includes automatic security updates, but review the host's actual policy before relying on them. See [Ubuntu's security update guidance](https://documentation.ubuntu.com/security/security-updates/).

## Optional Debian host preparation

Run these scripts separately when their settings match your server:

```bash
# Show a read-only host summary before and after setup.
bash scripts/Debian/check-host.sh

# Set an IANA timezone (example only).
sudo bash scripts/Debian/set-timezone.sh Europe/Belgrade

# Allow the actual SSH port before enabling UFW. Add host ports only as needed.
sudo bash scripts/Debian/configure-firewall.sh --ssh-port 22
# Example with additional host ports:
sudo bash scripts/Debian/configure-firewall.sh --ssh-port 22 --allow-tcp 80 --allow-tcp 443
```

The firewall script asks UFW to confirm activation. Keep the current SSH session open and verify a second connection before closing it. If the current session provides its SSH port, the script rejects a different `--ssh-port` value. Running UFW does **not** restrict Docker-published container ports; review those ports separately using [Docker's firewall guidance](https://docs.docker.com/engine/network/packet-filtering-firewalls/).

The host check reports whether `unattended-upgrades` is installed. Review the host's actual automatic-update policy before relying on it.

## Optional Fedora host preparation

Run these scripts separately when their settings match your server:

```bash
# Show a read-only host summary before and after setup.
bash scripts/Fedora/check-host.sh

# Set an IANA timezone (example only).
sudo bash scripts/Fedora/set-timezone.sh Europe/Belgrade

# Allow the actual SSH port before enabling firewalld. Add host ports only as needed.
sudo bash scripts/Fedora/configure-firewall.sh --ssh-port 22
# Example with additional host ports:
sudo bash scripts/Fedora/configure-firewall.sh --ssh-port 22 --allow-tcp 80 --allow-tcp 443
```

The firewall script enables `firewalld`, then adds the specified ports to its default zone. Keep the current SSH session open and verify a second connection before closing it. If the current session provides its SSH port, the script rejects a different `--ssh-port` value. Docker-published container ports can bypass `firewalld`; review those ports separately using [Docker's firewall guidance](https://docs.docker.com/engine/network/packet-filtering-firewalls/).

## Optional Red Hat Enterprise Linux host preparation

Run these scripts separately when their settings match your server:

```bash
# Show a read-only host summary before and after setup.
bash scripts/RHEL/check-host.sh

# Set an IANA timezone (example only).
sudo bash scripts/RHEL/set-timezone.sh Europe/Belgrade

# Allow the actual SSH port before enabling firewalld. Add host ports only as needed.
sudo bash scripts/RHEL/configure-firewall.sh --ssh-port 22
# Example with additional host ports:
sudo bash scripts/RHEL/configure-firewall.sh --ssh-port 22 --allow-tcp 80 --allow-tcp 443
```

The firewall script enables `firewalld`, then adds the specified ports to its default zone. Keep the current SSH session open and verify a second connection before closing it. If the current session provides its SSH port, the script rejects a different `--ssh-port` value. Docker-published container ports can bypass `firewalld`; review those ports separately using [Docker's firewall guidance](https://docs.docker.com/engine/network/packet-filtering-firewalls/).

## Quick start: Ubuntu

Copy this folder to an Ubuntu server where you have sudo access, then run:

```bash
cd docker-setup
sudo bash scripts/Ubuntu/install.sh
sudo docker compose version
sudo docker info --format '{{.ServerVersion}}'
```

You can rerun the script to install missing packages. Use `sudo docker` and `sudo docker compose` for administration. Membership in the `docker` group grants root-level privileges; add a user only after making that decision deliberately. See [Docker's Linux post-installation guide](https://docs.docker.com/engine/install/linux-postinstall/).

## Quick start: Debian 13

Copy this folder to a Debian 13 server where you have sudo access, then run:

```bash
cd docker-setup
sudo bash scripts/Debian/install.sh
sudo docker compose version
sudo docker info --format '{{.ServerVersion}}'
```

The Debian installer stops if it finds conflicting Docker packages and never removes packages or Docker data itself. It also preserves an existing `/etc/docker/daemon.json`.

## Quick start: Fedora 44

Copy this folder to a Fedora 44 server where you have sudo access, then run:

```bash
cd docker-setup
sudo bash scripts/Fedora/install.sh
sudo docker compose version
sudo docker info --format '{{.ServerVersion}}'
```

The Fedora installer stops if it finds conflicting Docker packages and never removes packages or Docker data itself. It also preserves an existing `/etc/docker/daemon.json`.

## Quick start: Red Hat Enterprise Linux 10

Register the RHEL host with Red Hat Subscription Management, then copy this folder to it and run:

```bash
cd docker-setup
sudo bash scripts/RHEL/install.sh
sudo docker compose version
sudo docker info --format '{{.ServerVersion}}'
```

The RHEL installer confirms registration before making changes. It stops if it finds conflicting Docker packages and never removes packages or Docker data itself. It also preserves an existing `/etc/docker/daemon.json`.

## Before production use

Review the [Ubuntu production checklist](docs/ubuntu-production-checklist.md), [Debian production checklist](docs/debian-production-checklist.md), [Fedora production checklist](docs/fedora-production-checklist.md), or [RHEL production checklist](docs/rhel-production-checklist.md) for SSH access, firewall rules, updates, backups, monitoring, and published container ports. The Docker installers do not change SSH, the system timezone, or swap; the optional scripts handle the distribution's firewall and timezone independently.

Docker warns that published container ports can bypass host-firewall rules. Plan container access using [Docker's firewall guidance](https://docs.docker.com/engine/network/packet-filtering-firewalls/).
