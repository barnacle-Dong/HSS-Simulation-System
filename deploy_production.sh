#!/bin/bash

# 반드시 root 권한으로 실행되어야 함
if [[ $EUID -ne 0 ]]; then
   echo "[-] 이 스크립트는 시스템 서비스 등록을 위해 sudo 권한이 필요합니다." 
   exit 1
fi

echo "=================================================="
echo " SKT HSS Production Service Deployment (Systemd)"
echo "=================================================="

# 1. KISA/GSMA 권장 보안 정책 보강 (sysctl)
echo "[*] Hardening Kernel Network Security (KISA/GSMA standards)..."
cat <<EOF > real_hss_system/defenses/sysctl_security.conf
# SYN Flooding Protection (KISA U-63)
net.ipv4.tcp_syncookies = 1

# Disable IP Source Routing (KISA U-65)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# ICMP Hardening (KISA U-41, U-64, U-66)
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# IP Spoofing Protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF
sysctl -p real_hss_system/defenses/sysctl_security.conf > /dev/null 2>&1

# 2. Systemd 서비스 등록
echo "[*] Registering HSS Core as a Systemd Service..."
cp real_hss_system/api/hss_core.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable hss_core.service > /dev/null 2>&1
systemctl restart hss_core.service

# 3. 방화벽 적용
bash real_hss_system/defenses/apply_policies.sh

echo "=================================================="
echo " Service Deployment Successful."
echo "--------------------------------------------------"
echo " [Service Status]  : systemctl status hss_core"
echo " [Real-time Logs]  : journalctl -u hss_core -f"
echo " [Database Path]   : real_hss_system/db/hss_production.db"
echo "=================================================="
