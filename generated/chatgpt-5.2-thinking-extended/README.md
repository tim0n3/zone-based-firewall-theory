# MikroTik Zone-Based Firewall Visualiser (RouterOS 7)

A single-page, self-contained website that **visually explains** a MikroTik **Zone-Based Firewall (ZBF)** design using **interface-lists as zones** (LAN / VPN / WAN / SafeZone).

It includes:
- An **interactive packet-flow diagram** with scenario toggles
- A **packet-processing pipeline** overview (RAW → MANGLE → NAT → FILTER)
- A **policy matrix** (what is allowed / denied)
- Human-readable **dispatcher pattern** explanation

---

## Demo

Open `index.html` in any browser.

No build step. No dependencies. No external assets required.

---

## Screenshots

Add screenshots here once you’ve taken them:

- `docs/screenshots/flow-lan-wan.png`
- `docs/screenshots/flow-wan-dstnat.png`

---

## What this explains

### Zones
- **LAN**: `192.168.88.0/24`
- **VPN**: `10.10.0.0/24`
- **WAN**: Internet-facing
- **SafeZone**: trusted IP list (eg allowed ICMP sources / trusted management sources)

### RouterOS tables in plain English
- **RAW**: cheap early drops (bogons/spoofs/blocklists), often before conntrack
- **MANGLE**: mark connections/packets for QoS shaping
- **NAT**: dstnat (port forwards) + srcnat/masquerade (outbound)
- **FILTER**: security policy enforcement  
  - `INPUT` = traffic to the router  
  - `FORWARD` = traffic through the router

### ZBF pattern (RouterOS)
RouterOS doesn’t have a single “ZBF object”. You implement it with:

- **interface-lists** for zones
- **dispatcher rules** at the top of `input` and `forward`
- **per-zone chains** (eg `zbf-in-lan`, `zbf-fwd-wan`)
- **default drop** at the end of each zone chain

---

## Repository layout

Suggested structure:

```

.
├─ index.html
└─ docs/
└─ screenshots/

````

---

## Usage

### Run locally
Just open:

- `index.html`

Or serve it:

```bash
python3 -m http.server 8080
````

Then browse to:

* `http://localhost:8080`

### Deploy (static hosting)

Works on any static host:

* GitHub Pages
* Cloudflare Pages
* Netlify
* Nginx/Apache
* S3-compatible static hosting

---

## Customising the content

### Update zone names/subnets

Edit the labels in `index.html`:

* Hero “Zones” pills
* Flow diagram left-side zone boxes
* Policy matrix table

### Add more zones (IoT / Guest / Servers)

The visual model supports more zones. Typical approach:

1. Add interface-lists (`IOT`, `GUEST`, `SERVERS`)
2. Add corresponding chains (`zbf-in-iot`, `zbf-fwd-iot`, etc)
3. Extend the matrix + flow scenarios

### Add scenarios

In `index.html`, find:

```js
const scenarios = { ... }
```

Each scenario provides:

* `title`
* `text` (displayed explanation)
* `draw()` (SVG paths)

Duplicate an existing scenario and tweak paths.

---

## Notes (accuracy expectations)

This site is an explainer for **how a ZBF design works on RouterOS 7**, not a full packet-tracing simulator.

Where it aims to be precise:

* Distinguishes `INPUT` vs `FORWARD`
* Shows the conceptual table order: **RAW → MANGLE → NAT → FILTER**
* Highlights key security posture patterns:

  * **WAN→LAN only if dstnat**
  * **tight WAN→router exposure**
  * **default deny by zone**

---

## Roadmap ideas (optional)

* Split the flow diagram into two:

  * “To router (INPUT)” lane
  * “Through router (FORWARD)” lane
* Show rule mapping from real exports (comments → flow steps)
* Export diagrams as PNG/SVG from the page
* Add dark/light theme toggle

---

## License

Choose one:

* MIT (recommended for a simple explainer)
* Apache-2.0

Add `LICENSE` file accordingly.

---

## Credits

Built as a companion visual to a MikroTik RouterOS 7 Zone-Based Firewall design using interface-lists and per-zone chains.
