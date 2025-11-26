# TOPOLOGY.md

## Network topology (Mermaid)
```mermaid
graph TD
  Internet["Internet"]
  Router["Router / Gateway\n(192.168.1.1)"]
  DC["DC01\nWindows Server 2022\nAD DS, DNS (192.168.1.10)"]
  Client["CLIENT01\nWindows 10/11\n(Domain-joined)"]
  Azure["Microsoft Entra (Azure AD)\n(aniketlab.shop)"]
  Internet --> Router
  Router --> DC
  Router --> Client
  DC --> Azure
  Client --> Azure
```

## IP plan
- DC01: 192.168.1.10 (static)
- CLIENT01: DHCP or static in 192.168.1.100-200
- Router: 192.168.1.1

## Notes
- Use Bridged or Host-only VMnet consistently for both DC and client so they can reach each other.
