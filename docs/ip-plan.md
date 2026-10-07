# IP Plan and Network Reference

## Domain
| Item | Value |
|---|---|
| Domain name | somtech.com (lab-only) |
| NetBIOS name | SOMTECH |
| Domain controller | DC01.somtech.com (192.168.10.5) |

## Networks and VLANs
| Network | VLAN | Subnet | Gateway (pfSense) | Purpose |
|---|---|---|---|---|
| WAN | n/a | 192.168.1.0/24 | Home router | Internet access, pfSense WAN = 192.168.1.5 |
| LAN | n/a | 192.168.100.0/24 | 192.168.100.1 | pfSense management network |
| SERVERMGMT | 10 | 192.168.10.0/24 | 192.168.10.1 | Servers (static addresses) |
| CLIENTS | 20 | 192.168.20.0/24 | 192.168.20.1 | User workstations |
| ADMIN | 30 | 192.168.30.0/24 | 192.168.30.1 | Admin and technician machines |

## Static addresses
| Host | IP | Role |
|---|---|---|
| pfSense | .1 on each VLAN | Gateway, firewall, DHCP relay |
| DC01 | 192.168.10.5 | AD DS, DNS, DHCP |

## DHCP scopes (on DC01)
| Scope | Scope ID | Range | Router (003) | DNS (006) | Domain (015) |
|---|---|---|---|---|---|
| CLIENTS | 192.168.20.0 | .100 - .200 | 192.168.20.1 | 192.168.10.5 | somtech.com |
| ADMIN | 192.168.30.0 | .100 - .200 | 192.168.30.1 | 192.168.10.5 | somtech.com |

DHCP is relayed by pfSense (Services > DHCP Relay) to 192.168.10.5.
The built-in pfSense DHCP server is disabled on all interfaces.

## DNS
- AD-integrated forward zone: somtech.com
- AD-integrated reverse zones: 10.168.192.in-addr.arpa (and 20, 30 as added)
- Clients use 192.168.10.5 as their only DNS server
- DC01 uses itself for DNS, with a forwarder for internet names

## Active Directory structure
SomTech
- IT
- HR
- Finance
- Workstations
- Servers

## Virtual machines
| VM | VLAN tag | OS | Role |
|---|---|---|---|
| pfSense | trunk | pfSense CE | Firewall and router |
| DC01 | 10 | Windows Server 2022 | Domain controller |
| CLIENT-01 | 20 | Windows 10/11 Pro | User workstation |
| ADMIN-PC | 30 | Windows 10/11 Pro | Admin workstation (planned) |
| KALI | 30 | Kali Linux | Security testing (planned) |
