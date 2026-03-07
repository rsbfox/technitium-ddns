# technitium-ddns

_Not affiliated with or endorsed by Technitium._

Dynamic DNS updater for [Technitium DNS Server](https://technitium.com/dns/).

Reads standard BIND9 zone files and pushes records to Technitium via its HTTP
API. Designed for self-hosted DNS on a home server with a dynamic WAN IP.
Supports split-horizon DNS so internal clients get LAN addresses and external
clients get WAN addresses automatically.

## Features

- BIND9 zone file format — works with existing zone files
- Supports A, AAAA, CAA, CNAME, MX, NS, PTR, SOA, SRV, TXT
- Technitium APP records with `$APP` directive for any installed app
- Split Horizon shorthand — `true`/`false` generates the right JSON automatically
- `${WAN}` and `${LAN}` placeholders substituted at runtime
- `$ORIGIN` with relative names (no trailing dot appended to current origin)
- Multi-line records with `( )`, multi-part TXT strings, full escape sequence support
- `serial auto` — lets Technitium manage SOA serial with its date scheme
- `--dry-run` — prints resolved FQDNs and real IPs, no API calls made
- Zones auto-created if missing
- Automatic WAN IP detection and bogon address validation
- Logs to terminal when interactive, syslog when run from cron/systemd
- Optional FreeDNS update support

## Requirements

- [Technitium DNS Server](https://technitium.com/dns/)

## Optional

**Split Horizon** — install from the Technitium app store to use `APP true/false`
records. Returns `${LAN}` to private clients and `${WAN}` to public clients.

**WildIp** — install from the Technitium app store. Resolves the IP encoded
in the label itself, e.g. `1.2.3.4.wildip.example.com → A 1.2.3.4`.

**FreeDNS** ([freedns.afraid.org](https://freedns.afraid.org)) — free dynamic DNS. Register subdomains on any of thousands of community-shared domains. They also support pointing an NS record at your own server, making Technitium authoritative for that subdomain — enabling wildcard records, split-horizon DNS, and automated DNS-01 Let's Encrypt challenges. Set FREEDNS_KEYS in the config to push IP updates on each run.

#UNTESTED **wan-routable** — a networkd-dispatcher script that triggers `technitium-ddns`
automatically when the WAN interface obtains a new routable IP. Requires
`systemd-networkd` and `networkd-dispatcher`.

Install:

```
sudo cp wan-routable /etc/networkd-dispatcher/routable.d/wan-routable
sudo chown root:root /etc/networkd-dispatcher/routable.d/wan-routable
sudo chmod 755 /etc/networkd-dispatcher/routable.d/wan-routable
```

Edit `WAN_IFACE` at the top of `wan-routable` to match your interface name.

## Install

Install dependencies:

```
sudo apt install grepcidr jq gettext-base curl perl
```

Install the script:

```
sudo cp technitium-ddns /usr/local/bin/technitium-ddns
sudo chown root:root /usr/local/bin/technitium-ddns
sudo chmod 755 /usr/local/bin/technitium-ddns
```

Install config and example zone:

```
sudo mkdir -p /etc/technitium-ddns/example.com
sudo cp technitium-ddns.conf /etc/technitium-ddns/
sudo cp example.com/main.zone /etc/technitium-ddns/example.com/
sudo chown root:root /etc/technitium-ddns/technitium-ddns.conf
sudo chmod 640 /etc/technitium-ddns/technitium-ddns.conf
sudo chown root:root /etc/technitium-ddns/example.com/main.zone
sudo chmod 640 /etc/technitium-ddns/example.com/main.zone
```

Edit the config:

```
sudo nano /etc/technitium-ddns/technitium-ddns.conf
```

See what it will do before touching anything:

```
sudo technitium-ddns --dry-run
```

## Usage

```
sudo technitium-ddns                       # all zones
sudo technitium-ddns your.domain           # one zone
sudo technitium-ddns --dry-run             # preview all zones
sudo technitium-ddns --dry-run your.domain # preview one zone
sudo technitium-ddns example.com           # always dry run, feature demo
```

Override IPs without editing config:

```
sudo WAN=1.2.3.4 LAN=192.168.1.1 technitium-ddns
```

## Zone File Format

Each zone is a directory under `/etc/technitium-ddns/` named after the zone's
FQDN, containing a file called `main.zone`:

```
/etc/technitium-ddns/
    technitium-ddns.conf
    example.com/
        main.zone          ← always dry run, feature demo
    your.domain/
        main.zone          ← your zone, must be root:root 640
    0.168.192.in-addr.arpa/
        main.zone          ← reverse zone
```

Zone files are standard BIND9 format. Copy and edit `example.com/main.zone`
to get started. Run `sudo technitium-ddns example.com` to see a full dry run
of the example zone demonstrating every supported feature.

```bind
$TTL 1h
$APP SplitHorizon.SimpleAddress Split Horizon

@       IN SOA  ns1 hostmaster auto 3600 900 604800 300
@       IN NS   ns1
@       IN MX   10 mail
@       IN TXT  "v=spf1 ip4:${WAN} ~all"
@       IN CAA  0 issue "letsencrypt.org"
@       IN APP  true          ; split horizon — LAN gets ${LAN}, WAN gets ${WAN}

ns1     IN A    ${WAN}
mail    IN A    ${WAN}
home    IN APP  false         ; LAN only
```

### $APP directive

Sets the Technitium app for all following APP records. Multiple `$APP`
directives can appear in one file.

```bind
$APP SplitHorizon.SimpleAddress Split Horizon

@    IN APP true              ; {"private":["${LAN}"],"public":["${WAN}"]}
home IN APP false             ; {"private":["${LAN}"]}
vpn  IN APP {"private":["10.0.0.2"],"public":["1.2.3.4"]}  ; custom JSON

$APP WildIp.App Wild IP

wildip IN APP                 ; no recordData
```

`true`/`false` shorthand is only valid for `SplitHorizon.SimpleAddress`.
All other apps accept JSON or empty.

## Configuration

`/etc/technitium-ddns/technitium-ddns.conf` must be `root:root 640`.

| Variable | Required | Description |
|---|---|---|
| `WAN_IFACE` | if needed | Network interface for WAN IP detection |
| `LAN_IFACE` | if needed | Network interface for LAN IP detection |
| `TECH_TOKEN` | yes* | Technitium API token (*not needed for `--dry-run`) |
| `TECH_API_BASE` | no | API base URL (default: `http://localhost:5380/api`) |
| `FREEDNS_KEYS` | no | Comma-separated afraid.org update keys |

`WAN_IFACE` and `LAN_IFACE` are only required if your zone files use `${WAN}`,
`${LAN}`, or `SplitHorizon.SimpleAddress` APP records. Zones with only static
records need neither.

## Status

Tested on Ubuntu 24.04 with Technitium DNS Server. Vibe coded with. Use at your own risk.
