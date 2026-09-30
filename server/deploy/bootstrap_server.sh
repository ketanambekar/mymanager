#!/usr/bin/env bash
set -euo pipefail

APP_USER="mymanager"
APP_ROOT="/opt/mymanager"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y docker.io docker-compose-v2 fail2ban unattended-upgrades ufw ca-certificates curl

if ! id "$APP_USER" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "$APP_USER"
fi

install -d -m 700 -o "$APP_USER" -g "$APP_USER" "/home/$APP_USER/.ssh"
install -m 600 -o "$APP_USER" -g "$APP_USER" /root/.ssh/authorized_keys "/home/$APP_USER/.ssh/authorized_keys"
install -d -m 750 -o "$APP_USER" -g "$APP_USER" "$APP_ROOT"
usermod -aG docker "$APP_USER"

cat >/etc/ssh/sshd_config.d/99-mymanager-hardening.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PermitRootLogin prohibit-password
PubkeyAuthentication yes
X11Forwarding no
AllowTcpForwarding no
EOF
sshd -t
systemctl reload ssh

ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp
ufw --force enable

cat >/etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
bantime = 1h
findtime = 10m
maxretry = 5
EOF
systemctl enable --now fail2ban docker

if ! swapon --show --noheadings | grep -q .; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >>/etc/fstab
fi

cat >/etc/sysctl.d/99-mymanager.conf <<'EOF'
vm.swappiness=10
net.ipv4.tcp_syncookies=1
EOF
sysctl --system >/dev/null

dpkg-reconfigure -f noninteractive unattended-upgrades
echo "Server bootstrap complete. Application root: $APP_ROOT"