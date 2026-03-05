# ---------------------------------------------------------------------------
# DANGER: This script removes ALL existing filter rules and replaces them
# with the Zone-Based Firewall (ZBF) structure.
# MUST BE RUN IN SAFE MODE [CTRL+X in CLI, or 'Safe Mode' button in Winbox].
# ---------------------------------------------------------------------------

/ip firewall filter remove [find dynamic=no]

/ip firewall filter
# ===========================================================================
# 1. ICMP CHAIN (Reused by Zones)
# ===========================================================================
add chain=icmp action=accept protocol=icmp icmp-options=0:0 comment="ICMP: Echo Reply"
add chain=icmp action=accept protocol=icmp icmp-options=8:0 comment="ICMP: Echo Request"
add chain=icmp action=drop protocol=icmp comment="ICMP: Bad/Other ICMP Drop" log-prefix="BAD ICMP ---"

# ===========================================================================
# 2. GLOBAL INPUT (Traffic destined to Router)
# ===========================================================================
add chain=input action=accept connection-state=established,related,untracked comment="GLOBAL IN: Accept Est/Rel/Untracked"
add chain=input action=drop connection-state=invalid comment="GLOBAL IN: Drop Invalid"
add chain=input action=accept in-interface=lo comment="GLOBAL IN: Accept Loopback"

# Input Zone Jumps
add chain=input action=jump jump-target=LAN-ROUTER in-interface-list=LAN comment="JUMP: LAN to Router"
add chain=input action=jump jump-target=VPN-ROUTER in-interface-list=VPN comment="JUMP: VPN to Router"
add chain=input action=jump jump-target=WAN-ROUTER in-interface-list=WAN comment="JUMP: WAN to Router"
add chain=input action=drop comment="GLOBAL IN: Default Drop" log-prefix="DROP_ALL_IN_BY_DEFAULT"

# ---------------------------------------------------------------------------
# 2a. LAN to ROUTER Zone
# ---------------------------------------------------------------------------
add chain=LAN-ROUTER action=accept protocol=udp dst-port=67,68 comment="LAN->RTR: DHCP"
add chain=LAN-ROUTER action=accept protocol=udp dst-port=53 comment="LAN->RTR: DNS UDP"
add chain=LAN-ROUTER action=accept protocol=tcp dst-port=53 comment="LAN->RTR: DNS TCP"
add chain=LAN-ROUTER action=accept protocol=udp dst-port=123 comment="LAN->RTR: NTP"
add chain=LAN-ROUTER action=accept protocol=udp dst-port=5246,5247 comment="LAN->RTR: CAPsMAN"
add chain=LAN-ROUTER action=jump jump-target=icmp protocol=icmp comment="LAN->RTR: ICMP Check"
add chain=LAN-ROUTER action=accept protocol=tcp dst-port=8291 src-address-list=IP_used_on_LAN comment="LAN->RTR: Winbox Mgmt (IP_used_on_LAN)" log=yes log-prefix="NOTICE: LAN -> router login"
add chain=LAN-ROUTER action=accept protocol=tcp dst-port=8291 src-address-list=BTH comment="LAN->RTR: Winbox Mgmt (BTH)"
add chain=LAN-ROUTER action=accept src-address-list=safezone comment="LAN->RTR: Safezone new conns"
add chain=LAN-ROUTER action=return comment="RETURN: LAN->RTR to Default Drop"

# ---------------------------------------------------------------------------
# 2b. VPN to ROUTER Zone
# ---------------------------------------------------------------------------
add chain=VPN-ROUTER action=accept comment="VPN->RTR: Mgmt Allow All"
add chain=VPN-ROUTER action=jump jump-target=icmp protocol=icmp comment="VPN->RTR: ICMP Check"
add chain=VPN-ROUTER action=accept src-address-list=safezone comment="VPN->RTR: Safezone new conns"
add chain=VPN-ROUTER action=return comment="RETURN: VPN->RTR to Default Drop"

# ---------------------------------------------------------------------------
# 2c. WAN to ROUTER Zone
# ---------------------------------------------------------------------------
add chain=WAN-ROUTER action=accept protocol=udp dst-port=26901,51820,51821 comment="WAN->RTR: WireGuard Handshakes"
add chain=WAN-ROUTER action=jump jump-target=icmp protocol=icmp src-address-list=safezone comment="WAN->RTR: ICMP Safezone"
add chain=WAN-ROUTER action=jump jump-target=icmp protocol=icmp src-address=xxx.xxx.xxx.xxx/32 comment="WAN->RTR: ICMP Uptime Kuma"
add chain=WAN-ROUTER action=drop limit=5,10:packet comment="WAN->RTR: Drop All Other (Limit Logging)" log-prefix="DROP_WAN_IN "
add chain=WAN-ROUTER action=return comment="RETURN: WAN->RTR to Default Drop"

# ===========================================================================
# 3. GLOBAL FORWARD (Traffic passing through Router)
# ===========================================================================
add chain=forward action=accept connection-state=established,related,untracked comment="GLOBAL FW: Accept Est/Rel/Untracked"
add chain=forward action=drop connection-state=invalid comment="GLOBAL FW: Drop Invalid"
add chain=forward action=drop in-interface-list=WAN protocol=tcp tcp-flags=!syn connection-state=new comment="GLOBAL FW: Drop TCP !SYN from WAN"
add chain=forward action=jump jump-target=kid-control comment="GLOBAL FW: Kid Control Jump"

# Global Drops / Hijacks
add chain=forward action=reject protocol=udp dst-port=853 reject-with=icmp-port-unreachable comment="GLOBAL FW: DNS Hijack (Deny DOH/DOT)"
add chain=forward action=reject protocol=tcp dst-port=853 reject-with=tcp-reset
add chain=forward action=reject connection-mark=Huawei-conn protocol=tcp reject-with=tcp-reset comment="GLOBAL FW: Deny Huawei TCP"
add chain=forward action=reject connection-mark=Huawei-conn protocol=udp reject-with=icmp-port-unreachable comment="GLOBAL FW: Deny Huawei UDP"

# Forward Zone Jumps
add chain=forward action=jump jump-target=LAN-WAN in-interface-list=LAN out-interface-list=WAN comment="JUMP: LAN to WAN"
add chain=forward action=jump jump-target=LAN-VPN in-interface-list=LAN out-interface-list=VPN comment="JUMP: LAN to VPN"
add chain=forward action=jump jump-target=VPN-LAN in-interface-list=VPN out-interface-list=LAN comment="JUMP: VPN to LAN"
add chain=forward action=jump jump-target=WAN-LAN in-interface-list=WAN out-interface-list=LAN comment="JUMP: WAN to LAN"
add chain=forward action=drop comment="GLOBAL FW: Default Drop" log=yes log-prefix="# ---- FW-DROP-ALL ----"

# ---------------------------------------------------------------------------
# 3a. LAN to WAN Zone
# ---------------------------------------------------------------------------
add chain=LAN-WAN action=accept comment="LAN->WAN: Allow All Egress"
add chain=LAN-WAN action=return comment="RETURN: LAN->WAN to Default Drop"

# ---------------------------------------------------------------------------
# 3b. LAN to VPN Zone
# ---------------------------------------------------------------------------
add chain=LAN-VPN action=accept comment="LAN->VPN: Allow All"
add chain=LAN-VPN action=return comment="RETURN: LAN->VPN to Default Drop"

# ---------------------------------------------------------------------------
# 3c. VPN to LAN Zone
# ---------------------------------------------------------------------------
add chain=VPN-LAN action=accept comment="VPN->LAN: Allow All"
add chain=VPN-LAN action=return comment="RETURN: VPN->LAN to Default Drop"

# ---------------------------------------------------------------------------
# 3d. WAN to LAN Zone
# ---------------------------------------------------------------------------
add chain=WAN-LAN action=accept connection-nat-state=dstnat comment="WAN->LAN: Allow Port Forwards (dstnat)"
add chain=WAN-LAN action=accept src-address-list=safezone comment="WAN->LAN: Allow Safezone Address List"
add chain=WAN-LAN action=drop limit=5,10:packet comment="WAN->LAN: Drop All Other (Limit Logging)" log=yes log-prefix="DROP_WAN_FW "
add chain=WAN-LAN action=return comment="RETURN: WAN->LAN to Default Drop"

# ===========================================================================
# 4. GLOBAL OUTPUT (Traffic originating from Router)
# ===========================================================================
add chain=output action=accept connection-state=established,related,untracked comment="GLOBAL OUT: Accept Est/Rel/Untracked"
add chain=output action=drop connection-state=invalid comment="GLOBAL OUT: Drop Invalid"
add chain=output action=accept in-interface=lo comment="GLOBAL OUT: Accept Loopback"
add chain=output action=jump jump-target=icmp protocol=icmp comment="GLOBAL OUT: ICMP Check"
add chain=output action=accept out-interface-list=VPN comment="GLOBAL OUT: Accept VPN Egress"
add chain=output action=drop dst-address-list=prod_blocklist comment="GLOBAL OUT: Drop Blacklisted IPs" log-prefix="REJECT -- BLACKLISTED FROM RTR ----"
add chain=output action=accept connection-state=new comment="GLOBAL OUT: Accept New Egress (DNS/VPN tunnels)" log-prefix="OUT-NEW --- "
add chain=output action=drop comment="GLOBAL OUT: Default Drop" limit=5,5:packet log-prefix="REJECTED_EGRESS"
