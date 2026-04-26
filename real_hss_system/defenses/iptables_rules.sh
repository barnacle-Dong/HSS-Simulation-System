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
