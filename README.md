# Docker Dynamic DNS (DDNS)

A simple container that keeps an eye on changes to your dynamic IP address, and updates an A-record at DNS providers that supports HTTP updates, such as no-ip, dyndns, google, etc.

Example providers update URLs:
- No IP: `https://dynupdate.no-ip.com/nic/update`
- DynDNS: `https://members.dyndns.org/v3/update`
- DuckDNS: `https://www.duckdns.org/v3/update`
- Google: `https://domains.google.com/nic/update`
- FreeDNS: `https://freedns.afraid.org/nic/update`
- DNS Made Easy: `https://cp.dnsmadeeasy.com/servlet/updateip?username={USERNAME}&password={PASSWORD}&id={ID}&ip={IP}`
- Loopia DNS: `https://dyndns.loopia.se`

Basic auth will automatically be added, as well as the 'myip' and 'hostname' query parameters. If anything else is required, it needs to be added to the DDNS_URL environment variable.
Placeholders are supported with the format {HOSTNAME}, which will translate to "${HOSTNAME}". I.e. the environment variable value.

## docker-compose example

```
version: '3.5'
services:
  ddns:
    image: ghcr.io/jimcronqvist/ddns:latest
    container_name: ddns
    restart: unless-stopped
    environment:
      - DDNS_URL=https://dyndns.loopia.se
      - USERNAME=jim
      - PASSWORD=xyz
      - HOSTNAME=something.domain.com
```
