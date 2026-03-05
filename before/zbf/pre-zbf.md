Here are my current /ip/firewall/{filter,nat,mangle,raw} rules:
# # 2026-03-05 17:09:31 by RouterOS 7.21.3
## filter table rules
```filter rules
/ip firewall filter
add action=jump chain=forward comment="jump to kid-control rules" jump-target=kid-control
add action=passthrough chain=input comment="0 -- INPUT Rules" disabled=yes
add action=fasttrack-connection chain=input comment="HARDEN IN: accept established/related/untracked" connection-state=\
    established,related disabled=yes
add action=accept chain=input comment="HARDEN IN: accept established/related/untracked" connection-state=established,related
add action=drop chain=input comment="HARDEN IN: drop invalid" connection-state=invalid
add action=accept chain=input in-interface=lo src-address=127.0.0.1
add action=accept chain=input dst-address=127.0.0.1 in-interface=lo
add action=accept chain=input comment="HARDEN IN: allow DHCP from LAN" dst-port=67,68 in-interface-list=LAN protocol=udp
add action=accept chain=input comment="HARDEN IN: allow DNS from LAN" dst-port=53 in-interface-list=LAN protocol=udp
add action=accept chain=input comment="HARDEN IN: allow DNS-tcp from LAN" dst-port=53 in-interface-list=LAN protocol=tcp
add action=accept chain=input comment="HARDEN IN: allow NTP from LAN" dst-port=123 in-interface-list=LAN protocol=udp
add action=accept chain=input comment="HARDEN IN: CAPsMAN discovery/control" dst-port=5246,5247 in-interface-list=!WAN protocol=\
    udp
add action=accept chain=input comment="HARDEN IN: allow SMBv2/3-tcp from lounge tv on LAN" disabled=yes dst-port=445 \
    in-interface=bridge protocol=tcp src-address=192.168.88.252
add action=jump chain=input comment="HARDEN IN: ICMP from LAN" connection-state=new in-interface-list=LAN jump-target=icmp \
    protocol=icmp
add action=jump chain=input comment="HARDEN IN: ICMP from VPN" connection-state=new in-interface-list=VPN jump-target=icmp \
    protocol=icmp
add action=jump chain=input comment="HARDEN IN: ICMP from safezone on WAN" connection-state=new in-interface-list=WAN \
    jump-target=icmp protocol=icmp src-address-list=safezone
add action=jump chain=input comment="HARDEN IN: ICMP from delect uptime kuma on WAN" connection-state=new in-interface-list=WAN \
    jump-target=icmp protocol=icmp src-address=xxx.xxx.xxx.xxx/32
add action=fasttrack-connection chain=input comment="HARDEN IN: allow management via VPN interface-list" disabled=yes \
    in-interface-list=VPN
add action=accept chain=input comment="HARDEN IN: allow management via VPN interface-list" in-interface-list=VPN
add action=accept chain=input comment="HARDEN IN: allow management via LAN interface-list" connection-state=new dst-address=\
    192.168.88.1 dst-port=8291 in-interface-list=LAN log=yes log-prefix="NOTICE: LAN -> router login attempt detected" protocol=\
    tcp src-address-list=IP_used_on_LAN
add action=accept chain=input comment="HARDEN IN: allow management via LAN interface-list" connection-state=new dst-address=\
    192.168.88.1 dst-port=8291 in-interface-list=LAN log-prefix="NOTICE: LAN -> router login att" protocol=tcp src-address-list=\
    BTH
add action=accept chain=input comment="ALLOW: WireGuard handshake from WAN" dst-port=26901 in-interface-list=WAN protocol=udp
add action=accept chain=input comment="ALLOW: WireGuard handshake from WAN" connection-state=new dst-port=51820,51821 \
    in-interface-list=WAN protocol=udp
add action=accept chain=input comment="ALLOW:  new conns from safezone" connection-state=new in-interface-list=!WAN \
    src-address-list=safezone
add action=drop chain=input comment="HARDEN IN: DROP all other WAN->router" in-interface-list=WAN limit=5,10:packet log-prefix=\
    "DROP_WAN_IN "
add action=drop chain=input comment="HARDEN IN: drop all not coming from LAN" in-interface-list=!LAN log-prefix=Drop-IN-Mik-__
add action=drop chain=input comment="HARDEN IN: final default drop" log-prefix=DROP_ALL_IN_BY_DEFAULT
add action=accept chain=output out-interface=lo src-address=127.0.0.1
add action=accept chain=output dst-address=127.0.0.1 out-interface=lo
add action=jump chain=output comment="defconf: accept ICMP" jump-target=icmp protocol=icmp
add action=fasttrack-connection chain=output comment="defconf: accept egress conns going to VPN" connection-state=\
    established,related,new disabled=yes out-interface-list=VPN
add action=accept chain=output comment="defconf: accept egress conns going to VPN" connection-state=established,related,new \
    out-interface-list=VPN
add action=accept chain=output comment="#--- VLAN.99 ---- accept established egress router traffic ---#" connection-state=\
    established,related,new disabled=yes out-interface=bridge.99
add action=drop chain=output comment="defconf: drop invalid pkts before leaving router" connection-state=invalid
add action=drop chain=output comment="defconf: drop blacklisted ips before leaving router" dst-address-list=prod_blocklist \
    log-prefix="REJECT -- BLACKLISTED FROM RTR ----"
add action=fasttrack-connection chain=output comment="defconf: accept established,related egress router traffic" \
    connection-state=established,related disabled=yes
add action=accept chain=output comment="defconf: accept established,related egress router traffic" connection-state=\
    established,related
add action=accept chain=output comment="defconf: accept new egress router traffic -- NEEDED for DNS and VPNs to work" \
    connection-state=new log-prefix="OUT-NEW --- "
add action=drop chain=output comment="defconf: reject egress router traffic at this point" limit=5,5:packet log-prefix=\
    REJECTED_EGRESS
add action=drop chain=forward comment="HARDEN FW: drop invalid" connection-state=invalid
add action=drop chain=forward comment="HARDEN FW: drop invalid" connection-state=new in-interface-list=WAN protocol=tcp \
    tcp-flags=!syn
add action=passthrough chain=forward comment="# ---- Forward In to iShield ---" connection-state=established,related disabled=yes \
    dst-address=192.168.88.152 in-interface-list=WAN out-interface=bridge
add action=passthrough chain=forward comment="# ---- Forward Out from iShield ---" connection-state=established,related,new \
    disabled=yes in-interface-list=LAN out-interface-list=WAN src-address=192.168.88.152
add action=accept chain=forward comment="HARDEN FW: accept established/related/untracked" connection-state=established,related
add action=reject chain=forward comment="DNS Hijack: deny DOH/DOT" dst-port=853 protocol=udp reject-with=icmp-port-unreachable
add action=reject chain=forward comment="DNS Hijack: deny DOH/DOT" dst-port=853 protocol=tcp reject-with=tcp-reset
add action=reject chain=forward comment="deny Huawei" connection-mark=Huawei-conn packet-mark=Huawei-pkts protocol=tcp \
    reject-with=tcp-reset src-address-list=huawei
add action=reject chain=forward comment="deny Huawei" connection-mark=Huawei-conn dst-address-list=huawei packet-mark=Huawei-pkts \
    protocol=tcp reject-with=tcp-reset
add action=reject chain=forward comment="deny Huawei" connection-mark=Huawei-conn packet-mark=Huawei-pkts protocol=udp \
    reject-with=icmp-port-unreachable src-address-list=huawei
add action=reject chain=forward comment="deny Huawei" connection-mark=Huawei-conn dst-address-list=huawei packet-mark=Huawei-pkts \
    protocol=udp reject-with=icmp-port-unreachable
add action=jump chain=forward comment="HARDEN FW: kid-control" jump-target=kid-control
add action=accept chain=forward comment="HARDEN FW: LAN->WAN allow" connection-state=new in-interface-list=LAN \
    out-interface-list=WAN
add action=accept chain=forward comment="HARDEN FW: LAN<->VPN allow (both directions)" connection-state=new in-interface-list=LAN \
    out-interface-list=VPN
add action=accept chain=forward comment="HARDEN FW: VPN<->LAN allow (both directions)" connection-state=new in-interface-list=VPN \
    out-interface-list=LAN
add action=accept chain=forward comment="ALLOW: conns from safezone" connection-state=new dst-port=1194 in-interface-list=WAN \
    protocol=tcp
add action=accept chain=forward comment="ALLOW: conns from safezone" connection-state=new dst-port=51820,51821 in-interface-list=\
    WAN protocol=udp
add action=accept chain=forward comment="HARDEN FW: allow WAN->LAN only if dstnat" connection-nat-state=dstnat in-interface-list=\
    WAN
add action=accept chain=forward comment="ALLOW: conns from safezone" connection-state=new in-interface-list=WAN src-address-list=\
    safezone
add action=drop chain=forward comment="HARDEN FW: DROP all other WAN forwarding" connection-nat-state=!dstnat in-interface-list=\
    WAN limit=5,10:packet log=yes log-prefix="DROP_WAN_FW "
add action=drop chain=forward comment="HARDEN FW: final default drop" log=yes log-prefix="# ---- FW-DROP-ALL ----"
add action=accept chain=icmp comment="echo reply" icmp-options=0:0 protocol=icmp
add action=accept chain=icmp comment="allow echo request" icmp-options=8:0 protocol=icmp
add action=drop chain=icmp comment="bad ICMP early termination" log-prefix="BAD ICMP ---" protocol=icmp
add action=drop chain=icmp comment="deny all other types"
```
## nat table rules
```nat
/ip firewall nat
add action=masquerade chain=srcnat comment="defconf: masquerade" ipsec-policy=out,none out-interface-list=WAN
add action=masquerade chain=srcnat comment="defconf: masquerade" out-interface-list=VPN
add action=dst-nat chain=dstnat comment="tinyfwd npm forward" disabled=yes dst-port=8664 in-interface-list=VPN log=yes \
    log-prefix="tinyfwd accessed" protocol=tcp to-addresses=192.168.88.199 to-ports=8081
add action=dst-nat chain=dstnat comment="# ---- OPNsense snmpd forward for LibreNMS ----" dst-port=65000 in-interface-list=WAN \
    protocol=udp src-address=xxx.xxx.xxx.xxx/32 to-addresses=192.168.88.2 to-ports=161
add action=dst-nat chain=dstnat comment="# ---- Munin port forward to OPNsense bridge ----" dst-port=4949 in-interface=wg2 log=\
    yes log-prefix=munin-connection protocol=tcp src-address=10.10.0.253 to-addresses=192.168.88.2 to-ports=4949
add action=dst-nat chain=dstnat dst-port=4949 in-interface=wg2 log-prefix=munin-connection protocol=udp src-address=10.10.0.253 \
    to-addresses=192.168.88.2 to-ports=4949
add action=dst-nat chain=dstnat dst-port=4949 in-interface-list=WAN log=yes log-prefix=munin-connection-from-wan protocol=tcp \
    src-address=154.65.102.24 to-addresses=192.168.88.2 to-ports=4949
add action=dst-nat chain=dstnat dst-port=4949 in-interface-list=WAN log-prefix=munin-connection protocol=udp src-address=\
    154.65.102.24 to-addresses=192.168.88.2 to-ports=4949
add action=redirect chain=dstnat comment="defconf: DNS-over-HTTPS (DoH)" disabled=yes dst-port=53 protocol=tcp src-address-list=\
    restricted_userss
add action=redirect chain=dstnat disabled=yes dst-port=53 protocol=udp src-address-list=restricted_userss
add action=redirect chain=dstnat comment="defconf: DNS-over-HTTPS (DoH)" disabled=yes dst-port=53 protocol=tcp src-address-list=\
    !unsafe-devices
add action=redirect chain=dstnat disabled=yes dst-port=53 protocol=udp src-address-list=!unsafe-devices
add action=redirect chain=dstnat comment="defconf: redirect all DNS through HAp ax^3" disabled=yes dst-port=53 protocol=tcp \
    src-address=!192.168.88.152
add action=redirect chain=dstnat disabled=yes dst-port=53 protocol=udp src-address=!192.168.88.152
add action=redirect chain=dstnat comment="CRACKDOWN: redirect all DNS through HAp ax^3" disabled=yes dst-port=53 protocol=tcp
add action=redirect chain=dstnat disabled=yes dst-port=53 protocol=udp
add action=dst-nat chain=dstnat comment="rTorrent 88.153 - laptop" disabled=yes dst-port=51413 in-interface-list=WAN log-prefix=\
    New:_TCP_SSH protocol=tcp to-addresses=192.168.88.153 to-ports=51413
add action=dst-nat chain=dstnat comment="rTorrent 88.153 - laptop" disabled=yes dst-port=51413 in-interface-list=WAN log-prefix=\
    New:_TCP_SSH protocol=udp to-addresses=192.168.88.153 to-ports=51413
add action=dst-nat chain=dstnat comment=wireguard-phones disabled=yes dst-port=443 in-interface-list=WAN protocol=udp \
    to-addresses=192.168.88.153 to-ports=443
add action=dst-nat chain=dstnat comment=wireguard-computers disabled=yes dst-port=80 in-interface-list=WAN protocol=udp \
    to-addresses=192.168.88.153 to-ports=80
add action=masquerade chain=srcnat comment="VLAN99 -> Internet" disabled=yes in-interface=bridge.99 out-interface-list=WAN \
    src-address=100.64.0.0/10
add action=masquerade chain=srcnat disabled=yes dst-address=100.64.0.0/10 in-interface=bridge out-interface=bridge.99 \
    src-address=192.168.88.0/24
add action=dst-nat chain=dstnat disabled=yes dst-port=80,443 log=yes log-prefix="WARN::iShield has been accessed" protocol=tcp \
    to-addresses=192.168.88.152
add action=dst-nat chain=dstnat disabled=yes dst-port=51821 in-interface-list=WAN log=yes log-prefix=\
    "WARN::iShield has been accessed" protocol=udp socks5-port=1 socks5-server=0.0.0.0 to-addresses=192.168.88.152 to-ports=51821
add action=dst-nat chain=dstnat disabled=yes dst-port=51820 log=yes log-prefix="WARN::iShield has been accessed" protocol=udp \
    socks5-port=1 socks5-server=0.0.0.0 to-addresses=192.168.88.152 to-ports=51820
add action=dst-nat chain=dstnat disabled=yes dst-port=1194 in-interface-list=WAN log=yes log-prefix=\
    "WARN::iShield has been accessed" protocol=tcp socks5-port=1 socks5-server=0.0.0.0 to-addresses=192.168.88.152 to-ports=1194
```
## mangle table rules
```mangle
/ip firewall mangle
add action=accept chain=output comment="# ---- quick accept hijacked DNS lookups before packet marking ----" disabled=yes \
    dst-address-list=DNS-Svrs dst-port=53 log-prefix="# ---- MANGLE-OUT:: VPN ---" out-interface=wg2 protocol=udp src-address=\
    10.10.0.100
add action=accept chain=output comment="# ---- quick accept hijacked DNS lookups before packet marking ----" disabled=yes \
    dst-address-list=DNS-Svrs dst-port=53 log-prefix="# ---- MANGLE-OUT:: VPN ---" out-interface=wg2 protocol=tcp src-address=\
    10.10.0.100
add action=accept chain=input comment="quick accept LAN to LAN before packet marking" disabled=yes in-interface=lo log-prefix=\
    "# ---- MANGLE-IN:: RTR ---" src-address=192.168.88.1
add action=accept chain=output comment="quick accept LAN to LAN before packet marking" disabled=yes log-prefix=\
    "# ---- MANGLE-OUT:: RTR ---" out-interface=bridge src-address=192.168.88.1
add action=accept chain=forward comment="quick accept LAN to LAN before packet marking" connection-mark=no-mark disabled=yes \
    dst-address-list=IP_used_on_LAN port=!53 protocol=tcp src-address-list=IP_used_on_LAN
add action=accept chain=forward connection-mark=no-mark disabled=yes dst-address-list=IP_used_on_LAN port=!53 protocol=udp \
    src-address-list=IP_used_on_LAN
add action=accept chain=forward comment="quick accept LAN to VPN before packet marking" connection-mark=no-mark connection-state=\
    new disabled=yes in-interface-list=LAN out-interface-list=VPN
add action=accept chain=forward comment="quick accept VPN to LAN before packet marking" connection-mark=no-mark connection-state=\
    new disabled=yes in-interface-list=VPN out-interface-list=LAN
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - from high-priority hosts" connection-mark=no-mark \
    connection-state=new new-connection-mark=conn_high_qos src-address-list=QOS_HIGH_HOSTS
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - to high-priority hosts" connection-mark=no-mark \
    connection-state=new dst-address-list=QOS_HIGH_HOSTS new-connection-mark=conn_high_qos
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - from VoIP servers" connection-mark=no-mark \
    connection-nat-state="" connection-state=new new-connection-mark=conn_realtime_qos src-address-list=QOS_VOIP_SERVERS
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - to VoIP servers" connection-mark=no-mark connection-state=new \
    dst-address-list=QOS_VOIP_SERVERS dst-port=80,443 new-connection-mark=conn_realtime_qos protocol=tcp
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - to VoIP servers" connection-mark=no-mark connection-state=new \
    dst-address-list=QOS_VOIP_SERVERS dst-port=443,3478-3481 new-connection-mark=conn_realtime_qos protocol=udp
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - to VoIP servers" connection-mark=no-mark connection-state=new \
    dst-address-list=QOS_VOIP_SERVERS new-connection-mark=conn_realtime_qos
add action=mark-connection chain=prerouting comment="QOS v2: BULK - from bulk hosts" connection-mark=no-mark connection-state=new \
    new-connection-mark=conn_bulk_qos src-address-list=QOS_BULK_HOSTS
add action=mark-connection chain=prerouting comment="QOS v2: BULK - to bulk hosts" connection-mark=no-mark connection-state=new \
    dst-address-list=QOS_BULK_HOSTS new-connection-mark=conn_bulk_qos
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - Rustdesk TCP" connection-mark=no-mark connection-state=new \
    dst-port=21115-21119 new-connection-mark=conn_high_qos protocol=tcp
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - Rustdesk UDP" connection-mark=no-mark connection-state=new \
    dst-port=21115-21119 new-connection-mark=conn_high_qos protocol=udp
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - STUN/TURN (real-time meetings)" connection-mark=no-mark \
    connection-state=new dst-port=3478-3481,5349 new-connection-mark=conn_high_qos protocol=udp
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - DNS,NTP,WireGuard (UDP)" connection-mark=no-mark \
    connection-state=new dst-port=53,123,51820-51821 new-connection-mark=conn_high_qos protocol=udp
add action=mark-connection chain=prerouting comment="QOS v2: HIGH - SSH,RDP,Winbox,DNS-tcp" connection-mark=no-mark \
    connection-state=new dst-port=22,53,1194,3389,8291 new-connection-mark=conn_high_qos protocol=tcp
add action=mark-connection chain=prerouting comment="QOS v2: BULK - from streaming devices" connection-mark=no-mark \
    connection-state=new new-connection-mark=conn_bulk_qos src-address-list=QOS_STREAMING_HOSTS
add action=mark-connection chain=prerouting comment="QOS v2: BULK - to streaming devices" connection-mark=no-mark \
    connection-state=new dst-address-list=QOS_STREAMING_HOSTS new-connection-mark=conn_bulk_qos
add action=mark-connection chain=prerouting comment="QOS v2: BULK - torrents TCP" connection-mark=no-mark connection-state=new \
    dst-port=51413,6881-6889 new-connection-mark=conn_bulk_qos protocol=tcp
add action=mark-connection chain=prerouting comment="QOS v2: BULK - torrents UDP" connection-mark=no-mark connection-state=new \
    dst-port=51413,6881-6889 new-connection-mark=conn_bulk_qos protocol=udp
add action=mark-connection chain=prerouting comment="QOS v2: BULK - RTMP streams" connection-mark=no-mark connection-state=new \
    dst-port=1935 new-connection-mark=conn_bulk_qos protocol=tcp
add action=mark-connection chain=prerouting comment="QOS v2: NORMAL - default for new connections" connection-mark=no-mark \
    connection-state=new new-connection-mark=conn_normal_qos
add action=mark-packet chain=prerouting comment="QOS v2: HIGH packets" connection-mark=conn_high_qos new-packet-mark=pm_high_qos \
    passthrough=no
add action=mark-packet chain=prerouting comment="QOS v2: REALTIME packets" connection-mark=conn_realtime_qos new-packet-mark=\
    pm_realtime_qos passthrough=no
add action=mark-packet chain=prerouting comment="QOS v2: NORMAL packets" connection-mark=conn_normal_qos new-packet-mark=\
    pm_normal_qos passthrough=no
add action=mark-packet chain=prerouting comment="QOS v2: BULK packets" connection-mark=conn_bulk_qos new-packet-mark=pm_bulk_qos \
    passthrough=no
```
raw table rules
```raw
/ip firewall raw
add action=drop chain=prerouting comment="# ---- Block TV ----" disabled=yes src-address=192.168.88.252
add action=accept chain=prerouting comment="# ---- RAW Rules Debug ----" disabled=yes
add action=accept chain=output disabled=yes
add action=drop chain=prerouting comment="# ---- HARDEN RAW: drop TCP NULL flags on WAN ----" in-interface-list=WAN protocol=tcp \
    tcp-flags=!fin,!syn,!rst,!psh,!ack,!urg
add action=drop chain=prerouting comment="# ---- HARDEN RAW: drop TCP weird flag combos on WAN ----" in-interface-list=WAN \
    protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
add action=drop chain=prerouting in-interface-list=WAN protocol=tcp tcp-flags=fin,syn
add action=drop chain=prerouting in-interface-list=WAN protocol=tcp tcp-flags=fin,rst
add action=drop chain=prerouting in-interface-list=WAN protocol=tcp tcp-flags=fin,!ack
add action=drop chain=prerouting in-interface-list=WAN protocol=tcp tcp-flags=fin,urg
add action=drop chain=prerouting in-interface-list=WAN protocol=tcp tcp-flags=syn,rst
add action=drop chain=prerouting in-interface-list=WAN protocol=tcp tcp-flags=rst,urg
add action=drop chain=prerouting comment="# ---- HARDEN RAW: drop TCP/UDP port 0 on WAN ----" in-interface-list=WAN protocol=tcp \
    src-port=0
add action=drop chain=prerouting dst-port=0 in-interface-list=WAN protocol=tcp
add action=drop chain=prerouting in-interface-list=WAN protocol=udp src-port=0
add action=drop chain=prerouting dst-port=0 in-interface-list=WAN protocol=udp
add action=drop chain=prerouting comment="# ---- HARDEN RAW: drop RFC1918/CGNAT/etc arriving on WAN (bogons) ----" \
    in-interface-list=WAN log-prefix="HARDEN RAW: DROP Bogons" src-address-list=bogons
add action=drop chain=prerouting comment="# ---- HARDEN RAW: drop spoofed LAN sources arriving on WAN ----" in-interface-list=WAN \
    src-address-list=IP_used_on_LAN
add action=accept chain=prerouting comment="# ---- Allow VPN communication ----" log-prefix="debug wgvpn ---" src-address-list=\
    VPN-networks
add action=accept chain=prerouting comment="# ---- Allow VPN communication ----" log-prefix="debug wgvpn ---" src-address-list=\
    safezone
add action=accept chain=prerouting comment="# ---- VPN -- early match, bypass blacklist matching. ----" dst-address-list=\
    VPN-networks log-prefix="debug wgvpn ---"
add action=drop chain=prerouting comment="# ---- (1) Blacklist drops: keep cheap, avoid logging by default ----" log-prefix=\
    bogons___ src-address-list=crowdsec-integration
add action=drop chain=prerouting dst-address-list=crowdsec-integration log-prefix=bogons___
add action=drop chain=prerouting log-prefix=bogons___ src-address-list=prod_blocklist
add action=drop chain=prerouting dst-address-list=prod_blocklist log-prefix=bogons___
add action=accept chain=prerouting comment="# ---- defconf: accept DHCP discover ----" dst-address=255.255.255.255 dst-port=67 \
    in-interface-list=LAN protocol=udp src-address=0.0.0.0 src-port=68
add action=accept chain=prerouting comment="# ---- Accept used protocols and drop all others ----" protocol=icmp
add action=accept chain=prerouting protocol=tcp
add action=accept chain=prerouting protocol=udp
add action=log chain=prerouting disabled=yes log-prefix=Prohibited-Protocol__
add action=drop chain=prerouting comment="# ---- Unused protocol protection ----"
add action=accept chain=output comment="# ---- VPN -- early match, bypass blacklist matching. ----" dst-address-list=VPN-networks \
    log-prefix="debug wgvpn ---"
```
