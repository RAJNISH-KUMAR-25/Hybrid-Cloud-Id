# INSTALL.md — Full step-by-step build instructions

**Purpose:** Reproduce the Hybrid Cloud Identity Lab for domain `aniketlab.shop`. These instructions are written for beginners and explain exact GUI choices, commands and file placements.

> Assumptions:
> - You have VMware Workstation installed on the host computer.
> - You have the Windows Server 2022 ISO, Windows 10/11 ISO and the Azure AD Connect installer downloaded.
> - You own the domain `aniketlab.shop` and can add DNS records in your registrar.

---

## 0. Quick IP plan (example)
- DC (Domain Controller): `DC01` → IP `192.168.1.10`
- Gateway / Router: `192.168.1.1`
- Client: obtain via DHCP or static in same subnet `192.168.1.x`

Adjust values if your LAN uses a different subnet.

---

## 1. Create VM for Windows Server 2022 (VMware Workstation)
1. Open **VMware Workstation** → File → New Virtual Machine.
2. Choose **Typical (recommended)** → Next.
3. Select **Installer disc image file (iso)** → Browse → choose `Windows_Server_2022.iso` → Next.
4. Guest OS: **Microsoft Windows** → Version: **Windows Server 2019 x64** or **Windows Server 2022 x64** if shown → Next.
5. Name the VM `DC01` and choose a folder with enough disk space → Next.
6. Disk Capacity: **60 GB** → Store as single file → Next → Finish.
7. Edit VM settings:
   - Memory: **4096 MB** (4 GB) minimum (8 GB recommended)
   - Processors: **2** cores
   - Network Adapter: **Bridged** (recommended) OR **Host-only (VMnet1)** if you want isolated lab without internet; record which network you pick.
   - CD/DVD: ensure ISO is attached.
8. Power on the VM.

---

## 2. Install Windows Server 2022 (Desktop Experience)
1. Boot from ISO → select language → Next → Install now.
2. Choose **Windows Server 2022 Datacenter (Desktop Experience)** → Next.
3. Accept license → Next → Custom installation.
4. Select disk → Next → Wait for install.
5. When prompted, set the **Administrator** password (remember it).

After installation, log in to desktop.

---

## 3. Install VMware Tools (guest drivers)
- In VMware menu choose **VM → Install VMware Tools**.
- Run the installer from the mounted virtual CD inside the guest and accept defaults.
- Reboot if prompted.

---

## 4. Initial Server configuration
1. Open **Server Manager** → Local Server.
2. Change computer name:
   - Click the computer name → Change → set **Computer name** to `DC01` → OK → Restart when prompted.
3. Configure static IP:
   - Open `ncpa.cpl` (Network Connections) → Right-click adapter → Properties → IPv4 → Properties.
   - Choose **Use the following IP address** and enter:
     - IP: `192.168.1.10`
     - Subnet mask: `255.255.255.0`
     - Default gateway: `192.168.1.1`
     - Preferred DNS server: `192.168.1.10` (point to itself)
   - Click OK.
4. Run Windows Update (Settings → Update & Security) and reboot as required.

---

## 5. Install Active Directory Domain Services (AD DS) & DNS
1. Server Manager → Manage → Add Roles and Features.
2. Role-based or feature-based → select this server → Next.
3. Under **Server Roles** check **Active Directory Domain Services**. Click **Add Features** when prompted. Ensure **DNS Server** is selected too.
4. Click Next → Install.
5. After install completes, click the notification **Promote this server to a domain controller**.

**Promote to DC (wizard)**
1. Choose **Add a new forest**.
2. Root domain name: `aniketlab.shop` → Next.
3. Forest and domain functional levels: **Windows Server 2022** → set DSRM password → Next.
4. Accept DNS delegation warning (if present) → Next.
5. NetBIOS name will be suggested (e.g., `ANIKETLAB`) → Next.
6. Accept default locations for DB/SYSVOL → Next → Install.
7. Server reboots and becomes the Domain Controller.

---

## 6. Configure DNS (forwarders & reverse zone)
1. Server Manager → Tools → DNS.
2. Expand server → Forward Lookup Zones → confirm `aniketlab.shop` exists.
3. Right-click server name → Properties → Forwarders → Edit → add `8.8.8.8` (Google) or your ISP DNS → OK.
4. Optional: Create Reverse Lookup Zone → IP range `192.168.1.0/24` → finish.

---

## 7. (Optional) Configure DHCP on DC
> If your router already provides DHCP, you can skip. To let DC provide IPs:
1. Add Roles and Features → DHCP Server → Install.
2. After install, click **Complete DHCP configuration** in Server Manager.
3. DHCP console → IPv4 → New Scope:
   - Name: `ANIKETLAB-Scope`
   - Start IP: `192.168.1.100`, End IP: `192.168.1.200`
   - Subnet mask: `255.255.255.0`
   - Router: `192.168.1.1`
   - DNS server: `192.168.1.10`
4. Activate scope and authorize DHCP server in AD.

---

## 8. Create OUs and Users & set UPN suffix
1. Server Manager → Tools → Active Directory Domains and Trusts:
   - Right-click top node → Properties → Under Alternative UPN suffixes add `aniketlab.shop` if not present → OK.
2. Server Manager → Tools → Active Directory Users and Computers:
   - Right-click domain → New → Organizational Unit → create `Users`, `Workstations`, `Servers`.
   - Right-click `Users` OU → New → User → create `rahul` (User logon name: `rahul@aniketlab.shop`) → set password.
3. Repeat for other test users.

---

## 9. Verify internal split-brain DNS note
- Your AD DNS zone `aniketlab.shop` is internal and resolves private addresses.
- Your registrar DNS will host public records (TXT for verification, MX for mail etc). Do not publish internal IPs publicly.

---

## 10. Azure tenant and domain verification
1. Sign in to https://portal.azure.com with your Azure account.
2. In Azure AD → Custom domain names → Add custom domain → Enter `aniketlab.shop` → Add domain.
3. Azure shows a TXT record to add at your registrar (e.g., `@  TXT  MS=msXXXXXXXX`).
4. At your registrar DNS settings, add the TXT as given; wait DNS propagation (minutes to hours).
5. Back in Azure Portal click **Verify**. Once verified, Azure shows domain as **Verified**.

---

## 11. Download & install Azure AD Connect
1. Download Azure AD Connect installer from Microsoft on the DC or a member server.
2. Run the installer as Administrator.
3. Choose **Customize** (not Express).
4. On **User sign-in** choose **Password Hash Synchronization** and **Enable single sign-on** → Next.
5. **Azure AD sign-in**: sign in using an Azure Global Admin account for your tenant.
6. **Connect to AD DS**: provide Enterprise Admin credentials for on-prem AD (example: `ANIKETLAB\\Administrator`) — the installer will create the sync service account automatically.
7. **Domain and OU filtering**: choose which OUs to sync (for lab, you can sync the Users OU).
8. Leave optional features default (Password writeback optional).
9. Confirm and **Install**. Enable "Start synchronization when configuration completes".

---

## 12. Force a sync and verify
1. On the AD Connect server open PowerShell (Admin) and run:
```powershell
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Delta
```
2. For a full initial sync use `-PolicyType Initial`.
3. Optional: Check Synchronization Service Manager:
`C:\\Program Files\\Microsoft Azure AD Sync\\UIShell\\miisclient.exe`
4. In Azure Portal → Azure AD → Users, verify synced users appear with source "Windows Server AD" or "Synced".

---

## 13. Create and configure a client VM, join domain
1. Create a Windows 10/11 VM in VMware. Important: use the **same VMware virtual network** as the DC (see below).
2. In client network adapter settings set DNS server to `192.168.1.10` (the DC).
3. Start client, login local account, then:
   - Right-click This PC → Properties → Advanced system settings → Computer Name → Change.
   - Join domain: `aniketlab.shop` → When prompted, enter domain admin creds `ANIKETLAB\\Administrator`.
   - Reboot.
4. At login choose Other user → `rahul@aniketlab.shop` and password.

---

## 14. Verify Seamless SSO
1. On the domain-joined client open Edge or Chrome.
2. Go to `https://myapps.microsoft.com`. Expected: **automatic sign-in** (silent) to Azure Apps.
3. Optional: verify Kerberos ticket on client:
```powershell
klist
```
Look for a valid TGT for the domain user — indicates Kerberos authentication.

---

## 15. Common troubleshooting
- DNS: Client must use DC IP as DNS. Test with `nslookup aniketlab.shop`.
- Time: Kerberos needs clocks within 5 minutes. `w32tm /resync`.
- Permissions: AD Connect on-prem credentials must be Enterprise Admin for account creation.
- Firewall: AD Connect needs outbound TCP 443. Ensure host firewall allows outbound HTTPS.
- SSO issues: Check `AZUREADSSOACC$` exists in AD; add `https://autologon.microsoftazuread-sso.com` to Local Intranet sites if browsers prompt.

---

## 16. Where to put screenshots & video
- Save screenshots with recommended filenames (see `docs/IMAGES.md`) into the `screenshots/` folder.
- Create a short demo video (30–60s) and save to `video/demo.mp4`. Also create `assets/demo-preview.gif` (short 4–6s GIF) for README preview.

---

## 17. Helpful scripts
- `scripts/sync-now.ps1` runs a delta sync.
- `scripts/check-time.ps1` shows and resyncs time service.

---

## 18. Final notes
- For production use a **member server** for AD Connect, follow least-privilege practices and review Microsoft documentation for high-availability.

Happy building — if anything fails, check DNS and time first; those cause most hybrid issues.
