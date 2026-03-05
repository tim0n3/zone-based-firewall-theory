On MikroTik, the cleanest “zone-based firewall” pattern is:

* **Zones = interface-lists** (LAN, WAN, VPN, plus optional IOT, GUEST, SERVERS, MGMT)
* **One dispatcher rule-set** in `input` and `forward`
* **Per-zone chains** where you express policy (LAN -> WAN allow, WAN -> LAN only dstnat, etc)
* **Default deny** at the end of every zone chain

Below is a **drop-in starter ZBF** for your current setup (RouterOS 7.21.3) using your existing lists (`LAN`, `WAN`, `VPN`) and your existing `icmp` chain + `kid-control` chain.

---

## Zone policy (what this implements)

**INPUT (to router):**

* LAN -> router: DNS, NTP, DHCP, CAPsMAN, Winbox (only your allowed lists)
* VPN -> router: Winbox + SSH (easy to adjust), ICMP
* WAN -> router: WireGuard handshakes + ICMP only from your trusted sources
* Everything else: drop

**FORWARD (through router):**

* Established/related: allow
* Invalid + WAN weird TCP: drop
* Global blocks you already have: DoT/853 reject, Huawei reject
* LAN -> WAN: allow
* LAN <-> VPN: allow (as you have now)
* WAN -> LAN: **only if dstnat**
* Everything else: drop

---

## Before you paste anything (2 mins, saves pain)

1. **Use Safe Mode** (Winbox: `Ctrl+X`) before changing firewall rules.
2. Take a backup:

```rsc
/export file=pre_zbf
/system backup save name=pre_zbf
```

3. Make sure your zone membership is correct (this matters a lot):

```rsc
/interface list member print
```

At minimum, your WAN uplink must be in `WAN`, your bridge/VLAN L3 interfaces in `LAN`, and your WG interfaces in `VPN` (eg `wg2`).

---

## Paste-able ZBF rules (adds new rules at the TOP)

> This does not delete your existing rules. It **inserts** a new ZBF “front-end” above them. If something is missing from your zone lists, it will get dropped (which is why Safe Mode is important).

### 1) Build the zone chains (INPUT)

```rsc
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
```

### 2) Build the zone chains (FORWARD)

```rsc
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
```

### 3) Add the dispatchers at the TOP of `input` and `forward`

These are inserted in the correct order by using `place-before=0` and adding bottom-to-top.

```rsc
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
```

---

## Quick validation checks

After pasting, run:

```rsc
/ip firewall filter print stats where comment~"^ZBF"
/ip firewall filter print stats where log-prefix~"ZBF_"
```

Test:

* LAN client can browse (LAN -> WAN)
* VPN can reach LAN resources (VPN -> LAN)
* Port forwards still work (WAN -> LAN via dstnat)
* Winbox from allowed LAN IPs still works
* WireGuard handshakes from WAN still work

If anything breaks, **Safe Mode** will roll back automatically when you disconnect.

---

## Next step (making it “real” zone-based)

Right now you have 3 zones (LAN/WAN/VPN). If you want proper segmentation (IoT, Guest, Servers, Mgmt), the pattern stays the same:

* Create interface-lists: `IOT`, `GUEST`, `SERVERS`, `MGMT`
* Add VLAN L3 interfaces to those lists
* Add two chains per zone: `zbf-in-iot`, `zbf-fwd-iot`, etc
* Only allow the flows you want (eg Guest -> WAN only, IoT -> DNS/NTP + WAN only, IoT -> LAN blocked, etc)

If you paste your **`/interface list export`** (and your VLAN interfaces, eg `bridge.X` members), I’ll convert this into a full zone matrix for your actual VLANs without guessing.
