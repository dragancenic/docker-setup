# Ubuntu production checklist

## Before installation

- [ ] Use a supported Ubuntu LTS release and an account with sudo access.
- [ ] Confirm SSH key access from a second session before changing SSH rules.
- [ ] Create a server snapshot or another recovery option.
- [ ] Check available disk space and memory: `df -h`, `free -h`.
- [ ] Inspect any existing Docker installation and configuration: `command -v docker`, `ls /etc/docker`.
- [ ] Plan firewall rules and application ports before publishing containers.
- [ ] Run `bash scripts/Ubuntu/check-ubuntu-host.sh` to record the initial host state.

## Docker installation

- [ ] Run `sudo bash scripts/Ubuntu/install-ubuntu.sh`.
- [ ] Check `sudo systemctl status docker`.
- [ ] Check `sudo docker compose version`.
- [ ] Check `sudo docker info --format '{{.ServerVersion}}'`.
- [ ] Optionally test container execution with `sudo docker run --rm hello-world` (downloads a test image).

## Before the first workload

- [ ] If needed, set the timezone with `sudo bash scripts/Ubuntu/set-ubuntu-timezone.sh AREA/CITY`.
- [ ] If using UFW, run `sudo bash scripts/Ubuntu/configure-ubuntu-firewall.sh --ssh-port PORT` with the actual SSH port. Test a second SSH session after activation.
- [ ] Review Docker-published ports separately; UFW does not reliably filter them.
- [ ] Apply Ubuntu security updates and set a schedule for Docker package updates.
- [ ] Review the `unattended-upgrades` policy on the host; do not assume third-party Docker packages are updated automatically.
- [ ] Decide where application data will be stored, and test backup and restore procedures.
- [ ] Monitor disk space, Docker service health, and application health.
- [ ] For each Compose project, review published ports, secrets, restart policies, and health checks.
- [ ] Pin image versions for workloads that require predictable upgrades instead of using `latest`.
