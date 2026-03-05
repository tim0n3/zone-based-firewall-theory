# **MikroTik Zone-Based Firewall (ZBF) Template**

A modern, highly efficient Zone-Based Firewall (ZBF) configuration template for MikroTik RouterOS v7+.

Instead of evaluating a linear, top-to-bottom list of 50+ firewall rules for every packet, this architecture utilizes a "Jump Matrix." Packets are categorized by their ingress and egress interfaces (Zones) and immediately jumped to a highly specific, short sub-chain. This drastically reduces CPU load, lowers latency, and makes the firewall logic significantly easier to read and maintain.

## **🚀 Features**

* **Default Deny Strategy:** If traffic isn't explicitly permitted in a zone chain, it is dropped and logged.  
* **Matrix Logic:** Dedicated chains for inter-zone traffic (e.g., LAN-WAN, WAN-LAN, LAN-ROUTER).  
* **Prerouting Optimization:** Relies on RAW to drop bogons and bad TCP flags before connection tracking occurs.  
* **QoS Ready:** Built to interoperate with extensive MANGLE connection and packet marking.

## **📁 Repository Contents**

* zbf-filter.rsc: The core RouterOS deployment script (Filter rules only).  
* mikrotik-zbf-infographic.md: Mermaid.js flowcharts mapping the high-level topology and RouterOS packet lifecycle.  
* mikrotik\_zbf\_infographic.html: An interactive Single Page Application (SPA) demonstrating the jump matrix logic and packet flows.

## **📋 Prerequisites**

Before deploying the .rsc script, ensure your router has the following configured:

1. **Interface Lists:**  
   * WAN (Your internet-facing interfaces)  
   * LAN (Your local trusted bridges/VLANs)  
   * VPN (Your WireGuard or remote access tunnel interfaces)  
2. **Address Lists:**  
   * safezone (Trusted external IPs)  
   * IP\_used\_on\_LAN / BTH (Trusted management subnets)

## **🛠️ Deployment Instructions**

**DANGER:** This script flushes and replaces your entire /ip firewall filter table. Do not run this over a remote connection without safety nets in place.

1. Open **Winbox** and connect to your router.  
2. Open a **New Terminal**.  
3. **CRITICAL:** Enable **Safe Mode** (Click the 'Safe Mode' button in the top left, or press CTRL+X).  
4. Copy the contents of zbf-filter.rsc and paste it into the terminal.  
5. Verify your connection is still active and test basic connectivity.  
6. If everything works, disable **Safe Mode** to commit the changes to memory.

## **✅ Validation Checklist**

After applying the configuration, verify the traffic flows:

* \[ \] Run /ip firewall filter print in the terminal. The output should be neatly grouped by global chains (input, forward, output) followed by zone chains (LAN-WAN, etc.).  
* \[ \] Open a website from a LAN device. Check Winbox \-\> IP \-\> Firewall. The counters for the LAN-WAN jump rule and the inner accept rule should increment.  
* \[ \] Ping the router's gateway IP from the LAN. The LAN-ROUTER ICMP rule should increment.

## **⏪ Rollback / Undo**

If you lose connectivity during deployment:

1. Do **not** reboot the router manually.  
2. Simply close Winbox, or forcefully disconnect your network cable for 15-30 seconds.  
3. Because you used **Safe Mode**, RouterOS will detect the dropped management connection and automatically revert the firewall to its exact previous state.

## **📄 License**

This project is open-source and provided "as-is" without warranty. Please test in a lab environment before deploying to production.
