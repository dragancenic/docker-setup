# Docker Setup

Prepare an Ubuntu, Debian, Fedora, or Red Hat Enterprise Linux server for Docker workloads. The installers currently support Ubuntu 22.04, 24.04, and 26.04 LTS, Debian 13, Fedora 44, and Red Hat Enterprise Linux 10. This repository sets up Docker and its supporting components; application deployment belongs in separate projects.

## What the installer sets up

- Docker Engine and CLI, containerd, Buildx, and the Compose plugin from Docker's official package repository for [Ubuntu](https://docs.docker.com/engine/install/ubuntu/), [Debian](https://docs.docker.com/engine/install/debian/), [Fedora](https://docs.docker.com/engine/install/fedora/), or [Red Hat Enterprise Linux](https://docs.docker.com/engine/install/rhel/)
- Docker service enabled at boot
- Docker JSON log rotation (10 MB, 3 files) on a fresh installation when `/etc/docker/daemon.json` does not already exist

The script does not remove existing Docker packages or data. If it finds conflicting packages, it stops and lists them. It does not add users to the `docker` group.

## First steps after installing Linux

Start here if the server is freshly installed and you only have a `root` account. Create a personal administrator account first, then use that account for the rest of this guide, with `sudo` when required.

### 1. Log in as root and create an administrator account

From your local computer, connect to the server (replace `SERVER_IP` with its address; add `-p PORT` if SSH uses a different port):

```bash
ssh root@SERVER_IP
```

In this root session, choose your username. The examples use `deploy`; replace it with the name you want. Use a simple Linux username, such as lowercase letters and digits, starting with a letter.

```bash
SERVER_USER=deploy
```

Run **only the block for your distribution**. On Ubuntu and Debian, administrators belong to the `sudo` group:

```bash
apt-get update
apt-get install -y sudo
adduser "$SERVER_USER"
usermod -aG sudo "$SERVER_USER"
```

On Fedora and RHEL, administrators belong to the `wheel` group. For RHEL, register the server with Red Hat Subscription Management before installing packages (`subscription-manager register`, using your organization's subscription details).

```bash
dnf install -y sudo
useradd --create-home --shell /bin/bash "$SERVER_USER"
passwd "$SERVER_USER"
usermod -aG wheel "$SERVER_USER"
```

Set a password when prompted; the new account will use it for `sudo`.

### 2. Enable SSH access and verify the new account

If you logged in as root with an SSH key stored in `/root/.ssh/authorized_keys`, the following commands authorize those same keys for the new account. Run them in the same root session, only if you want those keys to have access:

```bash
USER_HOME=$(getent passwd "$SERVER_USER" | cut -d: -f6)
USER_GROUP=$(id -gn "$SERVER_USER")
install -d -m 700 -o "$SERVER_USER" -g "$USER_GROUP" "$USER_HOME/.ssh"
install -m 600 -o "$SERVER_USER" -g "$USER_GROUP" /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
```

On Fedora and RHEL, also restore the SSH directory's SELinux labels:

```bash
restorecon -RF "$USER_HOME/.ssh"
```

If you use password authentication and the server allows it, log in with the new account's password instead. If your SSH key is not in root's `authorized_keys`, put your public key in the new account's `~/.ssh/authorized_keys` with the ownership and permissions shown above.

Keep the root session open. Open a **second terminal on your local computer** and connect with the username you chose:

```bash
ssh deploy@SERVER_IP
sudo -v
sudo id -u
```

Replace `deploy` and `SERVER_IP`, and use the same SSH port as before. The last command must print `0`. If login or `sudo` fails, fix it from the open root session before continuing. Once both work, use this new account for all remaining steps.

### 3. Update the system and install Git

In the new account's server session, run **only the block for your distribution**.

Ubuntu or Debian:

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git ca-certificates
```

Fedora or RHEL:

```bash
sudo dnf upgrade -y
sudo dnf install -y git ca-certificates
```

If the updates require a reboot, run `sudo reboot`, wait for the server to return, then reconnect with your new account before continuing.

### 4. Download this repository

Clone the repository into the new account's home directory, without `sudo`:

```bash
cd ~
git clone https://github.com/dragancenic/docker-setup.git
cd ~/docker-setup
```

Run the optional host preparation below if needed, then follow the Docker quick start for your distribution. All `scripts/...` commands in this guide assume your current directory is `~/docker-setup`. After reconnecting to the server, run `cd ~/docker-setup` again before using them.

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

After completing the first steps above, run these commands from `~/docker-setup` on your Ubuntu server:

```bash
sudo bash scripts/Ubuntu/install.sh
sudo docker compose version
sudo docker info --format '{{.ServerVersion}}'
```

You can rerun the script to install missing packages. Use `sudo docker` and `sudo docker compose` for administration. Membership in the `docker` group grants root-level privileges; add a user only after making that decision deliberately. See [Docker's Linux post-installation guide](https://docs.docker.com/engine/install/linux-postinstall/).

## Quick start: Debian 13

After completing the first steps above, run these commands from `~/docker-setup` on your Debian 13 server:

```bash
sudo bash scripts/Debian/install.sh
sudo docker compose version
sudo docker info --format '{{.ServerVersion}}'
```

The Debian installer stops if it finds conflicting Docker packages and never removes packages or Docker data itself. It also preserves an existing `/etc/docker/daemon.json`.

## Quick start: Fedora 44

After completing the first steps above, run these commands from `~/docker-setup` on your Fedora 44 server:

```bash
sudo bash scripts/Fedora/install.sh
sudo docker compose version
sudo docker info --format '{{.ServerVersion}}'
```

The Fedora installer stops if it finds conflicting Docker packages and never removes packages or Docker data itself. It also preserves an existing `/etc/docker/daemon.json`.

## Quick start: Red Hat Enterprise Linux 10

After completing the first steps above, including Red Hat Subscription Management registration, run these commands from `~/docker-setup` on your RHEL 10 server:

```bash
sudo bash scripts/RHEL/install.sh
sudo docker compose version
sudo docker info --format '{{.ServerVersion}}'
```

The RHEL installer confirms registration before making changes. It stops if it finds conflicting Docker packages and never removes packages or Docker data itself. It also preserves an existing `/etc/docker/daemon.json`.

## Before production use

Review the [Ubuntu production checklist](docs/ubuntu-production-checklist.md), [Debian production checklist](docs/debian-production-checklist.md), [Fedora production checklist](docs/fedora-production-checklist.md), or [RHEL production checklist](docs/rhel-production-checklist.md) for SSH access, firewall rules, updates, backups, monitoring, and published container ports. The Docker installers do not change SSH, the system timezone, or swap; the optional scripts handle the distribution's firewall and timezone independently.

Docker warns that published container ports can bypass host-firewall rules. Plan container access using [Docker's firewall guidance](https://docs.docker.com/engine/network/packet-filtering-firewalls/).
