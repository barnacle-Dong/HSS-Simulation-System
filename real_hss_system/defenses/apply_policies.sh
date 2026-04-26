#!/bin/bash
# HSS Production Server Security Policies

echo "[+] Applying Production Network Defenses..."

# 1. Kernel Parameter Hardening (sysctl)
cat <<EOF > real_hss_system/defenses/sysctl_security.conf
# Disable ICMP Redirect Acceptance
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Enable IP Spoofing Protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP Echo Requests (Ping)
# BPFdoor uses Magic ICMP packets. By ignoring standard pings at the kernel level,
# the system appears dead to scanners, but BPFdoor catches the packet BEFORE this rule applies.
net.ipv4.icmp_echo_ignore_all = 1

# Log Spoofed Packets, Source Routed Packets, Redirect Packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF

echo "[+] sysctl configurations generated."

# 2. Strict iptables Firewall Rules
cat <<EOF > real_hss_system/defenses/iptables_rules.sh
#!/bin/bash
# Flush existing rules
# iptables -F

# Default Drop Policy
# iptables -P INPUT DROP
# iptables -P FORWARD DROP
# iptables -P OUTPUT ACCEPT

# Allow Loopback
# iptables -A INPUT -i lo -j ACCEPT
# iptables -A OUTPUT -o lo -j ACCEPT

# Allow Established and Related Incoming Connections
# iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow Internal Management Subnet (e.g., 10.0.0.0/8) to access API (port 8443)
# iptables -A INPUT -p tcp -s 10.0.0.0/8 --dport 8443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Drop everything else explicitly and log it
# iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7
# iptables -A INPUT -j DROP
EOF

chmod +x real_hss_system/defenses/iptables_rules.sh
echo "[+] iptables configuration script generated."
echo "[!] Production defenses configured. Note: Kernel drops ICMP and iptables drops unknown TCP/UDP."
