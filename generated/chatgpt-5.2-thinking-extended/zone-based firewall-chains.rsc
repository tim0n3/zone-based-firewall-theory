/ip firewall filter
# -----------------------
# ZBF INPUT chains
# -----------------------

# LAN -> router
add chain=zbf-in-lan action=jump jump-target=icmp protocol=icmp comment="ZBF IN LAN: allow ICMP (via icmp chain)"
add chain=zbf-in-lan action=accept protocol=udp dst-port=67,68 comment="ZBF IN LAN: allow DHCP to router"
add chain=zbf-in-lan action=accept protocol=udp dst-port=53 comment="ZBF IN LAN: allow DNS (udp) to router"
add chain=zbf-in-lan action=accept protocol=tcp dst-port=53 comment="ZBF IN LAN: allow DNS (tcp) to router"
add chain=zbf-in-lan action=accept protocol=udp dst-port=123 comment="ZBF IN LAN: allow NTP to router"
add chain=zbf-in-lan action=accept protocol=udp dst-port=5246,5247 comment="ZBF IN LAN: allow CAPsMAN discovery/control"
add chain=zbf-in-lan action=accept protocol=tcp dst-port=8291 dst-address=192.168.88.1 src-address-list=IP_used_on_LAN log=yes log-prefix="NOTICE: LAN -> router login attempt detected " comment="ZBF IN LAN: allow Winbox (allowed list)"
add chain=zbf-in-lan action=accept protocol=tcp dst-port=8291 dst-address=192.168.88.1 src-address-list=BTH log-prefix="NOTICE: LAN -> router login att " comment="ZBF IN LAN: allow Winbox (BTH list)"
add chain=zbf-in-lan action=drop log=yes log-prefix="ZBF_DROP_IN_LAN " comment="ZBF IN LAN: drop the rest"

# VPN -> router
add chain=zbf-in-vpn action=jump jump-target=icmp protocol=icmp comment="ZBF IN VPN: allow ICMP (via icmp chain)"
add chain=zbf-in-vpn action=accept protocol=tcp dst-port=8291 comment="ZBF IN VPN: allow Winbox"
add chain=zbf-in-vpn action=accept protocol=tcp dst-port=22 comment="ZBF IN VPN: allow SSH (adjust if not used)"
# Optional if VPN clients use router DNS/NTP (enable if needed)
add chain=zbf-in-vpn action=accept disabled=yes protocol=udp dst-port=53 comment="ZBF IN VPN: allow DNS (udp) to router"
add chain=zbf-in-vpn action=accept disabled=yes protocol=tcp dst-port=53 comment="ZBF IN VPN: allow DNS (tcp) to router"
add chain=zbf-in-vpn action=accept disabled=yes protocol=udp dst-port=123 comment="ZBF IN VPN: allow NTP to router"
add chain=zbf-in-vpn action=drop log=yes log-prefix="ZBF_DROP_IN_VPN " comment="ZBF IN VPN: drop the rest"

# WAN -> router
add chain=zbf-in-wan action=accept protocol=udp dst-port=26901 comment="ZBF IN WAN: allow WireGuard handshake (26901)"
add chain=zbf-in-wan action=accept protocol=udp dst-port=51820,51821 comment="ZBF IN WAN: allow WireGuard handshake (51820-51821)"
# Your existing trusted ICMP sources
add chain=zbf-in-wan action=jump jump-target=icmp protocol=icmp src-address-list=safezone comment="ZBF IN WAN: allow ICMP from safezone"
add chain=zbf-in-wan action=jump jump-target=icmp protocol=icmp src-address=xxx.xxx.xxx.xxx/32 comment="ZBF IN WAN: allow ICMP from uptime kuma host"
# Optional: enable only if your WAN uses a DHCP client
add chain=zbf-in-wan action=accept disabled=yes protocol=udp dst-port=67,68 comment="ZBF IN WAN: allow DHCP client (enable if needed)"
add chain=zbf-in-wan action=drop log=yes log-prefix="ZBF_DROP_IN_WAN " comment="ZBF IN WAN: drop the rest"

/ip firewall filter
# -----------------------
# ZBF FORWARD chains
# -----------------------

# WAN -> inside
add chain=zbf-fwd-wan action=accept connection-nat-state=dstnat comment="ZBF FWD WAN: allow only dstnat forwards"
add chain=zbf-fwd-wan action=drop log=yes log-prefix="ZBF_DROP_FWD_WAN " comment="ZBF FWD WAN: drop the rest"

# LAN -> elsewhere
# (run kid-control only for NEW connections from LAN)
add chain=zbf-fwd-lan action=jump jump-target=kid-control connection-state=new comment="ZBF FWD LAN: kid-control (new conns)"
# Optional intrazone (only matters for routed VLANs)
add chain=zbf-fwd-lan action=accept disabled=yes in-interface-list=LAN out-interface-list=LAN connection-state=new comment="ZBF FWD LAN: allow LAN->LAN (enable if you route between VLANs and want it)"
add chain=zbf-fwd-lan action=accept in-interface-list=LAN out-interface-list=WAN connection-state=new comment="ZBF FWD LAN: allow LAN->WAN"
add chain=zbf-fwd-lan action=accept in-interface-list=LAN out-interface-list=VPN connection-state=new comment="ZBF FWD LAN: allow LAN->VPN"
add chain=zbf-fwd-lan action=drop log=yes log-prefix="ZBF_DROP_FWD_LAN " comment="ZBF FWD LAN: drop the rest"

# VPN -> elsewhere
add chain=zbf-fwd-vpn action=accept in-interface-list=VPN out-interface-list=LAN connection-state=new comment="ZBF FWD VPN: allow VPN->LAN"
add chain=zbf-fwd-vpn action=accept disabled=yes in-interface-list=VPN out-interface-list=WAN connection-state=new comment="ZBF FWD VPN: allow VPN->WAN (enable if VPN clients should use your Internet)"
add chain=zbf-fwd-vpn action=drop log=yes log-prefix="ZBF_DROP_FWD_VPN " comment="ZBF FWD VPN: drop the rest"

/ip firewall filter
# -----------------------
# ZBF DISPATCHERS (INPUT) - insert at top
# -----------------------
add chain=input action=drop comment="ZBF INPUT: drop (no zone match)" place-before=0
add chain=input action=jump in-interface-list=LAN jump-target=zbf-in-lan comment="ZBF INPUT: dispatch LAN->router" place-before=0
add chain=input action=jump in-interface-list=VPN jump-target=zbf-in-vpn comment="ZBF INPUT: dispatch VPN->router" place-before=0
add chain=input action=jump in-interface-list=WAN jump-target=zbf-in-wan comment="ZBF INPUT: dispatch WAN->router" place-before=0
add chain=input action=accept in-interface=lo src-address=127.0.0.1 comment="ZBF INPUT: allow loopback" place-before=0
add chain=input action=drop connection-state=invalid comment="ZBF INPUT: drop invalid" place-before=0
add chain=input action=accept connection-state=established,related,untracked comment="ZBF INPUT: accept established/related/untracked" place-before=0

# -----------------------
# ZBF DISPATCHERS (FORWARD) - insert at top
# -----------------------
add chain=forward action=drop log=yes log-prefix="ZBF_DROP_FWD_DEFAULT " comment="ZBF FORWARD: drop (no zone match)" place-before=0
add chain=forward action=jump in-interface-list=LAN jump-target=zbf-fwd-lan comment="ZBF FORWARD: dispatch LAN" place-before=0
add chain=forward action=jump in-interface-list=VPN jump-target=zbf-fwd-vpn comment="ZBF FORWARD: dispatch VPN" place-before=0
add chain=forward action=jump in-interface-list=WAN jump-target=zbf-fwd-wan comment="ZBF FORWARD: dispatch WAN" place-before=0

# Keep your existing "global" forward behaviours, but move them into the ZBF front-end:
add chain=forward action=reject dst-port=853 protocol=udp reject-with=icmp-port-unreachable comment="ZBF GLOBAL: deny DoT (udp/853)" place-before=0
add chain=forward action=reject dst-port=853 protocol=tcp reject-with=tcp-reset comment="ZBF GLOBAL: deny DoT (tcp/853)" place-before=0

add chain=forward action=reject connection-mark=Huawei-conn packet-mark=Huawei-pkts protocol=tcp reject-with=tcp-reset src-address-list=huawei comment="ZBF GLOBAL: deny Huawei (tcp src list)" place-before=0
add chain=forward action=reject connection-mark=Huawei-conn packet-mark=Huawei-pkts protocol=tcp reject-with=tcp-reset dst-address-list=huawei comment="ZBF GLOBAL: deny Huawei (tcp dst list)" place-before=0
add chain=forward action=reject connection-mark=Huawei-conn packet-mark=Huawei-pkts protocol=udp reject-with=icmp-port-unreachable src-address-list=huawei comment="ZBF GLOBAL: deny Huawei (udp src list)" place-before=0
add chain=forward action=reject connection-mark=Huawei-conn packet-mark=Huawei-pkts protocol=udp reject-with=icmp-port-unreachable dst-address-list=huawei comment="ZBF GLOBAL: deny Huawei (udp dst list)" place-before=0

add chain=forward action=drop connection-state=new in-interface-list=WAN protocol=tcp tcp-flags=!syn comment="ZBF GLOBAL: drop new tcp !syn from WAN" place-before=0
add chain=forward action=drop connection-state=invalid comment="ZBF GLOBAL: drop invalid" place-before=0
add chain=forward action=accept connection-state=established,related,untracked comment="ZBF GLOBAL: accept established/related/untracked" place-before=0

  
