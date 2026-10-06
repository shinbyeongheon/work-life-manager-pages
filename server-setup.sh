#!/usr/bin/env bash
# Ubuntu/Debian 서버 초기 세팅 스크립트
# 사용법: sudo bash server-setup.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "root 권한이 필요합니다: sudo bash $0" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> 1. 기본 도구"
apt-get update -qq
apt-get install -y git curl wget build-essential vim htop tmux unzip jq

echo "==> 2. 보안 (ufw, fail2ban, 자동 보안 업데이트)"
apt-get install -y ufw fail2ban unattended-upgrades
# SSH를 먼저 허용한 뒤 활성화해야 접속이 끊기지 않음
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
systemctl enable --now fail2ban
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "==> 3. Docker + Compose"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker

echo "==> 4. Nginx + certbot"
apt-get install -y nginx certbot python3-certbot-nginx
systemctl enable --now nginx

cat <<'EOF'

완료! 아래는 자동으로 하지 않았으니 직접 진행하세요.

[SSH 키 로그인으로 전환 - 키 등록·접속 확인 후에만!]
  1) 로컬에서: ssh-copy-id user@서버IP   (키로 접속되는지 먼저 확인)
  2) /etc/ssh/sshd_config 수정:
       PasswordAuthentication no
       PermitRootLogin no
  3) sudo systemctl restart ssh

[HTTPS 인증서]
  sudo certbot --nginx -d example.com

[Docker를 sudo 없이 쓰려면]
  sudo usermod -aG docker $USER   (재로그인 필요)
EOF
