# 🏢 Enterprise Active Directory Security Lab on Proxmox VE

A segmented, enterprise-style home lab built on **Proxmox VE** with a **pfSense** firewall, three VLANs, and a **Windows Server 2022** domain controller providing **AD DS, DNS, and DHCP** (via DHCP relay). Built to gain hands-on experience with enterprise Windows infrastructure and to prepare a safe environment for security testing.

> **Status:** 🚧 In progress. See the [Project Status](#-project-status) checklist.

---

## 📌 Table of Contents
1. [Project Purpose](#-project-purpose)
2. [Technologies & Tools](#-technologies--tools)
3. [Network Design](#-network-design)
4. [Build Walkthrough](#-build-walkthrough)
5. [Troubleshooting Log](#-troubleshooting-log)
6. [Key Learnings](#-key-learnings)
7. [Project Status](#-project-status)
8. [Future Enhancements](#-future-enhancements)

---

## 🎯 Project Purpose

1. Gain hands-on experience with enterprise Windows infrastructure
2. Understand how Active Directory works in real-world environments
3. Create a safe, isolated environment for learning security concepts
4. Develop troubleshooting and problem-solving skills
5. Build a portfolio piece demonstrating technical capabilities

---

## 🧰 Technologies & Tools

| Layer | Technology |
|---|---|
| Virtualization | Proxmox VE |
| Firewall / Router | pfSense CE (VLANs, DHCP relay, firewall rules) |
| Domain Controller | Windows Server 2022 (AD DS, DNS, DHCP) |
| Clients | Windows 10 / 11 |
| Security testing | Kali Linux 2025.x (planned) |

**Skills applied:** VM deployment, virtual networking and VLANs, pfSense configuration, Windows Server administration, Active Directory administration, DNS and DHCP configuration, domain join and authentication, network troubleshooting, security lab setup.

---

## 🌐 Network Design

### Topology

```
                      INTERNET
                          │
                   [Home router]
                          │
                  ┌───────┴────────┐
                  │    Proxmox     │
                  └───────┬────────┘
                  WAN 192.168.1.5
                  ┌───────┴────────┐
                  │    pfSense     │
                  └───────┬────────┘
                          │  LAN trunk (VLAN-aware bridge in Proxmox)
        ┌─────────────────┼──────────────────┐
   VLAN 10 SERVERMGMT  VLAN 20 CLIENTS    VLAN 30 ADMIN
   192.168.10.0/24     192.168.20.0/24    192.168.30.0/24
   ┌──────────┐        ┌───────────┐      ┌────────────┐
   │  DC01    │        │ Win10/11  │      │ Admin PC   │
   │ AD·DNS·  │        │ clients   │      │ Kali (plan)│
   │ DHCP     │        └───────────┘      └────────────┘
   └──────────┘
```

> 📷 *Replace this with an exported diagram (draw.io / diagrams.net) saved as `docs/network-diagram.png`.*

### Addressing

| Network | VLAN | Subnet | Gateway | Notes |
|---|---|---|---|---|
| SERVERMGMT | 10 | 192.168.10.0/24 | 192.168.10.1 | DC01 = `192.168.10.5` (static) |
| CLIENTS | 20 | 192.168.20.0/24 | 192.168.20.1 | DHCP pool `.100–.200` |
| ADMIN | 30 | 192.168.30.0/24 | 192.168.30.1 | DHCP pool `.100–.200` |
| LAN (management) | n/a | 192.168.100.0/24 | 192.168.100.1 | pfSense management network |

**Domain:** `somtech.com` (lab-only name)

### Design decisions

- **Segmentation:** servers, user workstations, and admin machines are on separate VLANs so firewall rules can control traffic between them.
- **Centralized DHCP:** one DHCP server on DC01 serves all VLANs through **pfSense DHCP relay**, with one scope per VLAN.
- **DNS:** AD-integrated forward and reverse zones; clients use DC01 as their only DNS server.

---

## 🛠️ Build Walkthrough

### 1. Virtual networking (Proxmox + pfSense)
- Created a VLAN-aware Linux bridge for the lab network
- Deployed pfSense with a WAN interface and a trunk interface carrying VLANs 10, 20, and 30
- Assigned a gateway address on each VLAN interface

📷 `screenshots/01-pfsense-interfaces.png`

### 2. Domain Controller (DC01)
- Installed Windows Server 2022, renamed it `DC01`, set a static IP `192.168.10.5`
- Installed AD DS and DNS, promoted the server to a new forest `somtech.com`
- Created AD-integrated **reverse lookup zones** and verified PTR records

```powershell
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
Install-ADDSForest -DomainName "somtech.com" -DomainNetbiosName "SOMTECH" -InstallDns
```

📷 `screenshots/02-dns-reverse-lookup.png`

### 3. DHCP with relay
- Installed and authorized DHCP on DC01
- Created one scope per VLAN with router, DNS, and domain options
- Disabled pfSense's own DHCP server and enabled **DHCP Relay** for CLIENTS and ADMIN, pointing to `192.168.10.5`

```powershell
Add-DhcpServerv4Scope -Name "CLIENTS" -StartRange 192.168.20.100 -EndRange 192.168.20.200 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -ScopeId 192.168.20.0 -Router 192.168.20.1 -DnsServer 192.168.10.5 -DnsDomain "somtech.com"
```

📷 `screenshots/03-dhcp-relay-config.png`, `screenshots/04-dhcp-lease.png`

### 4. Client connectivity
- Client on VLAN 20 received `192.168.20.100` from DC01 through the relay
- Verified gateway, cross-VLAN ping to DC01, and DNS resolution

📷 `screenshots/05-client-ipconfig.png`

### 5. Domain join and authentication
- *(Add once complete)* Joined Windows client to `somtech.com` and logged in with a domain user
- OU structure: `SomTech → IT, HR, Finance, Workstations, Servers`

📷 `screenshots/06-domain-join.png`, `screenshots/07-aduc-ou-structure.png`

---

## 🧯 Troubleshooting Log

Real problems encountered during the build and how they were solved:

| # | Problem | Root cause | Fix |
|---|---|---|---|
| 1 | `nslookup 192.168.10.5` returned *Non-existent domain* | No reverse lookup zone / PTR record | Created AD-integrated IPv4 reverse zone and registered DNS |
| 2 | pfSense: *"DHCP Relay cannot be enabled while DHCP Server is enabled"* | Built-in DHCP server still active on an interface | Disabled the DHCP server on every interface, then enabled relay |
| 3 | `ipconfig /renew`: *no adapter is in the state permissible* | Missing / unsupported NIC driver on the VM | Installed VirtIO network driver (or used Intel E1000 temporarily) |
| 4 | Client could ping its gateway but not other VLANs (*General failure*) | DHCP scope was missing option 003 (Router) | Set router option on each scope and renewed the lease |
| 5 | DC01 had a public DNS (`8.8.8.8`) as alternate DNS | Risk of AD name-resolution failures | Removed it; DC uses only itself, with a DNS forwarder for internet names |

---

## 💡 Key Learnings

- **Active Directory fundamentals:** domain structure, OUs, users and groups
- **Windows networking:** DNS, DHCP, and how domain authentication depends on DNS
- **Virtualization:** building isolated, segmented environments for testing
- **Network segmentation:** VLANs, inter-VLAN routing, DHCP relay, and per-interface firewall rules
- **Troubleshooting method:** isolate by layer (link → IP → gateway → DNS → service → firewall)
- **Security mindset:** foundation for understanding attack and defense in AD environments

---

## ✅ Project Status

- [x] Proxmox VLAN-aware networking
- [x] pfSense with VLANs 10 / 20 / 30
- [x] Windows Server 2022 DC with AD DS and DNS
- [x] Reverse lookup zone and PTR records
- [x] DHCP scopes and DHCP relay across VLANs
- [x] Client receives address, gateway, and DNS from DHCP
- [ ] Client joined to domain with domain user login
- [ ] Admin workstation on VLAN 30
- [ ] Tightened inter-VLAN firewall rules
- [ ] Group Policy hardening
- [ ] Kali Linux testing machine

---

## 🚀 Future Enhancements

- **Firewall hardening:** restrict CLIENTS → DC01 to required AD ports only, block CLIENTS → ADMIN, restrict pfSense GUI to the ADMIN VLAN
- **Group Policy Objects:** password policy, account lockout, screen lock, security baselines
- **Second domain controller** with replication for redundancy
- **Centralized logging:** Windows Event Forwarding, Sysmon, and a log viewer such as Wazuh or Security Onion
- **Attack and defense exercises** in the isolated lab (for example Kerberoasting and Pass-the-Hash), focusing on the **detection** side: relevant Event IDs, audit policy, and mitigation

> ⚠️ All security testing is performed only inside this isolated lab environment.

---

## 📁 Repository Structure

```
.
├── README.md
├── docs/
│   ├── network-diagram.png
│   └── ip-plan.md
├── screenshots/
│   └── (numbered images referenced above)
└── scripts/
    ├── 01-install-adds.ps1
    ├── 02-dhcp-scopes.ps1
    └── 03-create-ou-users.ps1
```

---

## 👤 Author

**Your Name** · Aspiring Systems / Security Administrator
🔗 [LinkedIn](https://linkedin.com/in/your-profile) · 📧 your.email@example.com
