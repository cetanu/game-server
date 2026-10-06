"""Update the two game-server A records using Namecheap's DDNS password."""
import argparse
import ipaddress
import json
import os
from pathlib import Path
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DOMAIN = "vsyrakis.dev"
HOSTS = ("valheim", "factorio")
ENDPOINT = "https://dynamicdns.park-your-domain.com/update"


class UpdateError(Exception):
    pass


def read_password(config):
    password = os.environ.get("NAMECHEAP_DDNS_PASSWORD", "")
    if not password:
        try:
            password = json.loads(config.read_text()).get("ddns_password", "")
        except (OSError, ValueError, AttributeError):
            raise UpdateError(f"Cannot read configuration: {config}") from None
    if not isinstance(password, str) or not password.strip():
        raise UpdateError("Set ddns_password in config/namecheap-ddns.json or NAMECHEAP_DDNS_PASSWORD")
    return password.strip()


def fetch(url):
    try:
        with urllib.request.urlopen(url, timeout=20) as response:
            return response.read(65536)
    except (OSError, urllib.error.URLError, ValueError):
        # Exceptions can include the URL containing the credential. Never print it.
        raise UpdateError("HTTPS request failed; check network connectivity and try again") from None


def ipv4(value):
    try:
        address = ipaddress.IPv4Address(value.strip())
    except ipaddress.AddressValueError:
        raise UpdateError("Expected a valid public IPv4 address") from None
    if not address.is_global:
        raise UpdateError("Expected a publicly routable IPv4 address")
    return str(address)


def update(host, password, address):
    query = urllib.parse.urlencode(dict(host=host, domain=DOMAIN, password=password, ip=address))
    payload = fetch(f"{ENDPOINT}?{query}")
    try:
        result = ET.fromstring(payload)
    except ET.ParseError:
        # Namecheap can declare UTF-16 while sending UTF-8 bytes. Parse the
        # decoded text in that case, retaining normal handling for real UTF-16.
        try:
            result = ET.fromstring(payload.decode("utf-8-sig"))
        except (UnicodeDecodeError, ET.ParseError):
            raise UpdateError("Namecheap returned an invalid XML response") from None
    if result.findtext("ErrCount") != "0" or result.findtext("Done", "").lower() != "true":
        # Do not echo provider responses: they could contain credentials.
        raise UpdateError("Namecheap rejected the update; check DDNS password, enabled DDNS, and A+Dynamic records")
    returned_ip = result.findtext("IP")
    if returned_ip and returned_ip.strip() != address:
        raise UpdateError("Namecheap returned an unexpected IP address")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=ROOT / "config/namecheap-ddns.json")
    parser.add_argument("--ip", help="Explicit public IPv4; otherwise detect it using api.ipify.org")
    parser.add_argument("--check", action="store_true", help="Validate credential configuration without network requests")
    args = parser.parse_args(argv)
    try:
        password = read_password(args.config)
        if args.check:
            print("DDNS configuration ready for " + ", ".join(f"{host}.{DOMAIN}" for host in HOSTS))
            return 0
        address = ipv4(args.ip if args.ip else fetch("https://api.ipify.org").decode("ascii"))
    except (UpdateError, UnicodeDecodeError) as error:
        print(f"DDNS: {error}", file=sys.stderr)
        return 1
    failed = False
    for host in HOSTS:
        try:
            update(host, password, address)
            print(f"Updated {host}.{DOMAIN} -> {address}")
        except UpdateError as error:
            print(f"{host}.{DOMAIN}: {error}", file=sys.stderr)
            failed = True
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
