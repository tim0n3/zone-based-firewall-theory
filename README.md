# MikroTik Zone-Based Firewall (ZBF) Theory

Build a clean, scalable zone-based firewall on MikroTik RouterOS 7+ using
interface lists as zones, a dispatcher (jump matrix), and per-zone chains with
default deny.

This repo is a set of templates and explainers. It does not replace basic
RouterOS knowledge, but it will take you from "what is ZBF?" to deploying and
customizing your own ZBF rule set.

## What you are building

RouterOS does not have a single "ZBF object." You implement ZBF with:

- Zones defined as interface lists (LAN, WAN, VPN, and any extras)
- Dispatcher rules at the top of `input` and `forward` that jump to zone chains
- Per-zone chains for policy (LAN -> WAN allow, WAN -> LAN only dstnat, etc)
- Default drop at the end of each zone chain

This makes the policy clear, modular, and fast to evaluate.

## Repository map (start here)

- `generated/gemini-canvas-pro-3/README.md` - overview of the main template and
  deployment notes
- `generated/chatgpt-5.2-thinking-extended/README.md` - visualizer overview
- `generated/gemini-canvas-pro-3/MikroTik%20ZBF%20Filter%20Rules.rsc` - full
  filter replacement script (destructive to existing filter rules)
- `generated/chatgpt-5.2-thinking-extended/zone-based%20firewall-chains.rsc` -
  drop-in ZBF front-end (inserts rules at the top; non-destructive)
- `generated/chatgpt-5.2-thinking-extended/adding-zbf-rules.md` - step-by-step
  walkthrough for adding ZBF rules
- `generated/gemini-canvas-pro-3/ZBF%20Architecture%20%26%20Packet%20Flow.md` -
  Mermaid diagrams for architecture and packet flow
- `generated/gemini-canvas-pro-3/MikroTik%20ZBF%20Interactive%20Architecture.html`
  - interactive ZBF architecture explainer (open in a browser)
- `generated/gemini-canvas-pro-3/MikroTik%20ZBF%20Infographic.html` - interactive
  packet flow infographic (open in a browser)
- `generated/chatgpt-5.2-thinking-extended/Mikro%20Tik%20Zbf%20Visualiser.html`
  - alternate visual explainer (open in a browser)
- `before/zbf/pre-zbf.md` - example pre-ZBF export (reference only)

## Zero-to-hero path

1. Read the visuals and concepts
   - Open the HTML files listed above to get an intuitive model of the flow.
   - Skim `generated/gemini-canvas-pro-3/ZBF%20Architecture%20%26%20Packet%20Flow.md`
     for the packet processing order (RAW -> MANGLE -> NAT -> FILTER).
2. Inventory your router
   - RouterOS 7+.
   - Confirm your WAN uplink, LAN bridges/VLANs, and VPN interfaces.
   - Identify which devices or subnets you want to allow to manage the router.
3. Define your zones (interface lists)
   - At minimum: `LAN`, `WAN`, `VPN`.
   - Add members carefully; misclassified interfaces are the number one cause
     of lockouts.
4. Create the required address lists (used by the templates)
   - `safezone` - trusted external IPs (e.g., ICMP or management from WAN).
   - `IP_used_on_LAN` and `BTH` - allowed management sources on LAN.
   - `prod_blocklist` - optional blocklist used by the example output rules.
5. Pick a deployment path
   - Option A: full replacement of the filter table.
   - Option B: insert a ZBF front-end above your existing filter rules.
6. Apply the rules in Safe Mode, validate traffic, then customize.

## Prerequisites and safety

Always use Safe Mode when changing firewall rules. If you lose access, RouterOS
will roll back when the session drops.

Recommended before you start:

- Console or out-of-band access in case you lock yourself out.
- Backups:
  - `/export file=pre_zbf`
  - `/system backup save name=pre_zbf`
- Verify zone membership:
  - `/interface list member print`

## Deployment option A: replace filter rules

Use `generated/gemini-canvas-pro-3/MikroTik%20ZBF%20Filter%20Rules.rsc` if you
want a clean, opinionated ZBF filter table.

Notes:

- This script removes all existing filter rules first.
- It does not touch NAT, MANGLE, or RAW tables.
- It expects interface lists `LAN`, `WAN`, `VPN` and address lists like
  `safezone`, `IP_used_on_LAN`, and `BTH`.

Steps:

1. Open Winbox or Terminal and enable Safe Mode (`Ctrl+X`).
2. Paste the contents of the `.rsc` file.
3. Confirm you still have access and basic connectivity.
4. Exit Safe Mode to commit.

## Deployment option B: insert a ZBF front-end

Use `generated/chatgpt-5.2-thinking-extended/zone-based%20firewall-chains.rsc`
if you want to keep your existing rules and add a ZBF dispatcher above them.

Notes:

- This is non-destructive: it inserts rules at the top using `place-before=0`.
- It assumes you already have or want an `icmp` chain and (optionally)
  `kid-control`.
- It still requires correct interface lists and address lists.

Follow the detailed walkthrough in
`generated/chatgpt-5.2-thinking-extended/adding-zbf-rules.md`.

## Minimal setup examples (adapt to your router)

Create interface lists and add members:

```rsc
/interface list
add name=LAN
add name=WAN
add name=VPN

/interface list member
add list=LAN interface=bridge
add list=WAN interface=ether1
add list=VPN interface=wg0
```

Create address lists used by the templates:

```rsc
/ip firewall address-list
add list=safezone address=203.0.113.10 comment="trusted mgmt from WAN"
add list=IP_used_on_LAN address=192.168.88.50 comment="allowed Winbox host"
add list=BTH address=192.168.88.60 comment="allowed Winbox host"
```

## Validation checklist

- `/ip firewall filter print stats` shows counters on the dispatcher and zone
  chains you expect.
- LAN -> WAN works.
- VPN -> LAN works (if enabled).
- WAN -> LAN only works for dstnat or safezone sources.
- Router management works only from allowed sources.

If anything breaks, drop the Safe Mode session and the router will roll back.

## Customizing your own zone matrix

To add new zones like IOT, GUEST, or SERVERS:

1. Create new interface lists and add members.
2. Add two chains per zone:
   - `ZONE-ROUTER` for traffic to the router (INPUT)
   - `ZONE-OTHER` for traffic through the router (FORWARD)
3. Add dispatcher jumps for each zone in `input` and `forward`.
4. Default deny at the end of each zone chain.

The pattern is shown clearly in the Mermaid diagrams and in
`generated/chatgpt-5.2-thinking-extended/adding-zbf-rules.md`.

## Troubleshooting tips

- If traffic is unexpectedly dropped, check interface list membership first.
- Missing address lists will cause matches to fail, which often looks like a
  blanket drop.
- Use `log=yes` on drop rules temporarily, then remove once stable.

## License

See `LICENSE`.
