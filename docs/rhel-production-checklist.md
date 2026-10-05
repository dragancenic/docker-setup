# Red Hat Enterprise Linux production checklist

## Before installation

- [ ] Use Red Hat Enterprise Linux 10 and an account with sudo access.
- [ ] Register the host with Red Hat Subscription Management and confirm that required repositories are available.
- [ ] Confirm SSH key access from a second session before changing firewall rules.
- [ ] Create a server snapshot or another recovery option.
- [ ] Check available disk space and memory: `df -h`, `free -h`.
- [ ] Inspect any existing Docker or Podman installation and configuration: `command -v docker`, `command -v podman`, `ls /etc/docker`.
- [ ] Plan firewall rules and application ports before publishing containers.
- [ ] Run `bash scripts/RHEL/check-host.sh` to record the initial host state.
- [ ] Review the SELinux status and application requirements; do not disable SELinux as a substitute for correct container configuration.

## Docker installation

- [ ] Run `sudo bash scripts/RHEL/install.sh`.
- [ ] Check `sudo systemctl status docker`.
- [ ] Check `sudo docker compose version`.
- [ ] Check `sudo docker info --format '{{.ServerVersion}}'`.
- [ ] Optionally test container execution with `sudo docker run --rm hello-world` (downloads a test image).

## Before the first workload

- [ ] If needed, set the timezone with `sudo bash scripts/RHEL/set-timezone.sh AREA/CITY`.
- [ ] If using `firewalld`, run `sudo bash scripts/RHEL/configure-firewall.sh --ssh-port PORT` with the actual SSH port. Test a second SSH session after activation.
- [ ] Review Docker-published ports separately; `firewalld` does not reliably filter them.
- [ ] Apply RHEL security updates and set a schedule for Docker package updates.
- [ ] Decide where application data will be stored, and test backup and restore procedures.
- [ ] Monitor disk space, Docker service health, and application health.
- [ ] For each Compose project, review published ports, secrets, restart policies, SELinux labeling, and health checks.
- [ ] Pin image versions for workloads that require predictable upgrades instead of using `latest`.
