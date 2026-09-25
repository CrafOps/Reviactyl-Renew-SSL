# Reviactyl / Pterodactyl Node Installer

สคริปต์สำหรับเตรียมเครื่อง Server ใหม่ให้สามารถทำหน้าที่เป็น **Node** ของ Reviactyl / Pterodactyl Panel ที่มีอยู่แล้ว

เหมาะสำหรับกรณีที่มี Panel หลักอยู่แล้ว และต้องการเพิ่มเครื่อง Server อีกเครื่องเข้ามาเป็น Node โดยไม่ต้องติดตั้ง Panel ใหม่

---

## Features

* รองรับ Ubuntu
* ตรวจสอบ OS และ Architecture
* ติดตั้ง Docker อัตโนมัติ
* ติดตั้ง Wings
* ใช้ `config.yml` ที่สร้างจาก Panel หลัก
* เลือกตำแหน่งสำหรับเก็บ Server Data ได้
* รองรับ Disk แยกสำหรับ Server Storage
* สร้าง `systemd` service สำหรับ Wings
* ตั้ง Wings ให้ Start อัตโนมัติเมื่อเปิดเครื่อง
* ตรวจสอบสถานะ Docker / Wings / Storage
* ดู Wings Logs
* Restart / Start / Stop Wings
* Reinstall Wings

---

# Architecture

ตัวอย่างระบบ:

```text
                    Reviactyl Panel
                    AlmaLinux 9
                         │
             ┌───────────┴───────────┐
             │                       │
          Node 01                 Node 02
        AlmaLinux 9              Ubuntu 24.04
             │                       │
        Minecraft                 Minecraft
        Servers                   Servers
```

เครื่อง Node ใหม่จะ **ไม่ต้องติดตั้ง Reviactyl Panel**

ติดตั้งเฉพาะ:

```text
Docker
  ↓
Wings
  ↓
config.yml
  ↓
Node
```

แต่ละ Node จะมีทรัพยากรของตัวเอง เช่น:

```text
Node 01
├── CPU
├── RAM
├── Storage
└── Minecraft Servers

Node 02
├── CPU
├── RAM
├── Storage
└── Minecraft Servers
```

ทรัพยากรของ Node ไม่ได้ถูกรวมกันเป็นเครื่องเดียว

---

# Requirements

เครื่อง Node ใหม่ควรมี:

* Ubuntu 20.04 / 22.04 / 24.04
* Root หรือ sudo access
* Internet access
* Public IP หรือ Network ที่ Panel สามารถเข้าถึงได้
* Configuration ของ Node จาก Panel หลัก
* Domain / FQDN สำหรับ Node หรือ IP ที่สามารถใช้งานได้
* Port ที่จำเป็นสำหรับ Wings และ Game Server allocations

แนะนำให้ใช้ Ubuntu LTS รุ่นที่ยังได้รับการสนับสนุน

---

# Installation

## 1. Download Script

ดาวน์โหลด Installer:

```bash
wget https://raw.githubusercontent.com/CrafOps/Reviactyl-Renew-SSL/main/install-node.sh
```

---

## 2. Permission

ตั้ง Permission ให้สามารถ Execute ได้:

```bash
chmod +x install-node.sh
```

---

## 3. Run Installer

รันด้วย Root หรือ `sudo`:

```bash
sudo ./install-node.sh
```

จากนั้นจะเข้าสู่เมนูหลัก:

```text
======================================================
       Reviactyl / Pterodactyl Node Installer
======================================================

  1) Install Node
  2) Check Status
  3) Restart Wings
  4) View Wings Logs
  5) Start Wings
  6) Stop Wings
  7) Reinstall Wings
  0) Exit
```

เลือก:

```text
1) Install Node
```

---

# Installation Flow

Installer จะเตรียมระบบตามลำดับ:

```text
Check OS
   ↓
Check Architecture
   ↓
Install Dependencies
   ↓
Install Docker
   ↓
Configure Storage
   ↓
Install Node Configuration
   ↓
Install Wings
   ↓
Create systemd Service
   ↓
Enable Wings
   ↓
Start Wings
   ↓
Check Status
```

---

# Docker

ถ้าเครื่องยังไม่มี Docker Script จะติดตั้งให้อัตโนมัติ

ตรวจสอบ Docker:

```bash
docker --version
```

ตรวจสอบ Service:

```bash
systemctl status docker
```

ควรเห็น:

```text
Active: active (running)
```

หาก Docker ไม่ทำงาน:

```bash
systemctl restart docker
```

แล้วตรวจสอบอีกครั้ง:

```bash
systemctl status docker
```

---

# Server Storage

Installer จะให้เลือกตำแหน่งสำหรับเก็บข้อมูลของ Server

ค่าเริ่มต้น:

```text
/var/lib/pterodactyl
```

ตัวอย่างการใช้ Disk แยก:

```text
/data/pterodactyl
```

หรือ:

```text
/mnt/games/pterodactyl
```

ตัวอย่าง:

```text
Server Storage

Storage path [/var/lib/pterodactyl]:
> /data/pterodactyl
```

หลังจากตั้งค่าแล้ว Server Data จะถูกจัดเก็บภายใต้ Directory ที่กำหนด

ตัวอย่าง:

```text
/data
└── pterodactyl
    ├── server-1
    ├── server-2
    └── server-3
```

> แนะนำให้ใช้ Disk แยกสำหรับ Game Server Data หากเครื่องมี NVMe / SSD / HDD สำหรับเก็บ Server โดยเฉพาะ

---

# Using Separate Disk

หากต้องการใช้ Disk แยก เช่น:

```text
/dev/sdb1
```

สามารถ Mount ไปยัง:

```text
/data
```

แล้วกำหนด Server Storage เป็น:

```text
/data/pterodactyl
```

ตรวจสอบ Disk:

```bash
lsblk
```

ตรวจสอบ Mount:

```bash
findmnt
```

ตรวจสอบพื้นที่:

```bash
df -h
```

ตัวอย่าง:

```text
Filesystem      Size  Used Avail Use%
/dev/sda2       100G   20G   80G  20%
/dev/sdb1       1.8T  100G  1.7T   6%
```

ในกรณีนี้สามารถใช้:

```text
/data/pterodactyl
```

เป็น Storage สำหรับ Game Server ได้

> ควรตั้งค่า `/etc/fstab` ให้ Disk Mount อัตโนมัติหลัง Reboot ก่อนนำ Node ไปใช้งานจริง

---

# Node Configuration

ก่อนติดตั้ง Node ต้องสร้าง Node ใน Reviactyl Panel ก่อน

ตัวอย่าง:

```text
Admin
└── Nodes
    └── Create Node
```

สร้าง Node เช่น:

```text
Name:
DDC-02

FQDN:
node02.example.com
```

หลังจากสร้าง Node แล้ว ให้เข้า Configuration ของ Node:

```text
Node
└── Configuration
```

จากนั้นนำ `config.yml` ที่ Panel สร้างให้มาใช้กับเครื่องใหม่

---

# Get config.yml From Panel

Configuration ของแต่ละ Node เป็น Configuration เฉพาะของ Node นั้น

ตัวอย่าง:

```text
Node 02
    ↓
Configuration
    ↓
config.yml
```

อย่านำ Configuration ของ Node อื่นมาใช้แทนกัน

---

# Method 1 — Configuration File

หากมีไฟล์:

```text
/root/config.yml
```

Installer สามารถรับ Path ของไฟล์ได้

ตัวอย่าง:

```text
1) Use config.yml file
```

จากนั้น:

```text
/root/config.yml
```

Installer จะนำ Configuration ไปไว้ที่:

```text
/etc/pterodactyl/config.yml
```

---

# Method 2 — Paste Configuration

หากไม่มีไฟล์ สามารถเลือก:

```text
2) Paste config from Panel
```

แล้วนำ Configuration จาก Panel มา Paste

เมื่อ Paste เสร็จให้กด:

```text
CTRL+D
```

เพื่อจบ Input

Configuration จะถูกบันทึกไว้ที่:

```text
/etc/pterodactyl/config.yml
```

---

# Configuration Security

ไฟล์:

```text
/etc/pterodactyl/config.yml
```

อาจมีข้อมูลสำคัญ เช่น:

* Token
* Authentication information
* Node credentials
* API credentials

Installer จะตั้ง Permission เป็น:

```text
600
```

ตรวจสอบได้ด้วย:

```bash
ls -l /etc/pterodactyl/config.yml
```

ตัวอย่าง:

```text
-rw------- 1 root root ... config.yml
```

**ห้ามเผยแพร่ `config.yml` ลง GitHub หรือส่งให้บุคคลอื่นโดยไม่จำเป็น**

หาก Configuration ถูกเปิดเผย ควรสร้าง Credential ใหม่จาก Panel

---

# Install Wings

Installer จะติดตั้ง Wings Binary ไว้ที่:

```text
/usr/local/bin/wings
```

ตรวจสอบ:

```bash
wings --version
```

หรือ:

```bash
/usr/local/bin/wings --version
```

---

# Wings Configuration

Configuration จะอยู่ที่:

```text
/etc/pterodactyl/config.yml
```

โครงสร้างโดยรวม:

```text
/etc/pterodactyl/
└── config.yml
```

Permission:

```text
600
```

---

# Systemd Service

Installer จะสร้าง Service:

```text
/etc/systemd/system/wings.service
```

จากนั้นตั้งให้ Wings เริ่มทำงานอัตโนมัติเมื่อเครื่อง Boot:

```bash
systemctl enable wings
```

Start:

```bash
systemctl start wings
```

Restart:

```bash
systemctl restart wings
```

Stop:

```bash
systemctl stop wings
```

ตรวจสอบ:

```bash
systemctl status wings
```

---

# Check Node

จาก Installer เลือก:

```text
2) Check Status
```

หรือใช้:

```bash
systemctl status wings
```

หากทำงานปกติควรเห็น:

```text
Active: active (running)
```

ตรวจสอบ Docker:

```bash
systemctl status docker
```

ตรวจสอบ Storage:

```bash
df -h
```

---

# Wings Logs

หาก Node ไม่ขึ้น Online ให้ตรวจสอบ Logs:

```bash
journalctl -u wings -n 100 --no-pager
```

ดู Logs แบบ Real-time:

```bash
journalctl -u wings -f
```

หรือเลือกจาก Installer:

```text
4) View Wings Logs
```

---

# Firewall

ต้องตรวจสอบ Firewall ของเครื่อง Node และ Firewall ของ VPS / Cloud Provider

Port ที่ต้องเปิดขึ้นอยู่กับ Configuration ของ Node เช่น:

* Wings / Agent Port
* Minecraft Server allocations
* Game Server Ports
* Service อื่น ๆ ที่ต้องการให้เข้าถึงจาก Internet

ตัวอย่าง Minecraft:

```text
25565
25566
25567
25568
...
```

ตรวจสอบ Firewall บน Ubuntu:

```bash
ufw status
```

หากจำเป็น:

```bash
ufw allow 80/tcp
ufw allow 443/tcp
```

สำหรับ Game Server ให้เปิดเฉพาะ Port ที่ใช้งานจริง

ตัวอย่าง:

```bash
ufw allow 25565/tcp
```

> Port ของ Wings ควรตรวจสอบจาก Node Configuration ที่สร้างจาก Panel ไม่ควรเดา Port เอง

---

# DNS / FQDN

หากใช้ FQDN เช่น:

```text
node02.example.com
```

DNS ต้องชี้มายัง IP ของ Node:

```text
node02.example.com
        │
        ▼
103.xxx.xxx.xxx
```

ตรวจสอบด้วย:

```bash
dig +short node02.example.com
```

หรือ:

```bash
nslookup node02.example.com
```

IP ที่ได้ควรตรงกับ IP ของ Node

---

# Menu

เมื่อรัน:

```bash
sudo ./install-node.sh
```

จะมีเมนู:

```text
======================================================
       Reviactyl / Pterodactyl Node Installer
======================================================

  1) Install Node
  2) Check Status
  3) Restart Wings
  4) View Wings Logs
  5) Start Wings
  6) Stop Wings
  7) Reinstall Wings
  0) Exit
```

## Install Node

```text
1) Install Node
```

ติดตั้งและเตรียม Node ใหม่

## Check Status

```text
2) Check Status
```

ตรวจสอบสถานะ Docker, Wings และ Storage

## Restart Wings

```text
3) Restart Wings
```

Restart Wings

## View Wings Logs

```text
4) View Wings Logs
```

แสดง Wings Logs

## Start Wings

```text
5) Start Wings
```

Start Wings

## Stop Wings

```text
6) Stop Wings
```

Stop Wings

## Reinstall Wings

```text
7) Reinstall Wings
```

ติดตั้ง Wings ใหม่

## Exit

```text
0) Exit
```

ออกจาก Installer

---

# File Locations

หลังติดตั้งจะมีไฟล์หลักดังนี้:

### Wings Binary

```text
/usr/local/bin/wings
```

### Node Configuration

```text
/etc/pterodactyl/config.yml
```

### Systemd Service

```text
/etc/systemd/system/wings.service
```

### Default Server Storage

```text
/var/lib/pterodactyl
```

หรือ Storage ที่เลือกเอง เช่น:

```text
/data/pterodactyl
```

---

# Example

สมมุติระบบเดิม:

```text
Reviactyl Panel
└── AlmaLinux 9
    └── reviactyl.example.com
```

มี Node เดิม:

```text
Node 01
└── AlmaLinux 9
```

ต้องการเพิ่ม:

```text
Node 02
└── Ubuntu 24.04
    ├── CPU: 32 Core
    ├── RAM: 128 GB
    └── NVMe: 2 TB
```

สร้าง Node ใน Panel:

```text
Name:
DDC-02

FQDN:
node02.example.com

IP:
103.xxx.xxx.xxx
```

จากนั้นเข้า Configuration ของ Node และนำ `config.yml` มาใช้กับเครื่อง Ubuntu

บนเครื่อง Ubuntu:

```bash
wget https://raw.githubusercontent.com/CrafOps/Reviactyl-Renew-SSL/main/install-node.sh
```

จากนั้น:

```bash
chmod +x install-node.sh
```

และ:

```bash
sudo ./install-node.sh
```

เลือก:

```text
1) Install Node
```

เลือก Storage:

```text
/data/pterodactyl
```

ใส่ Configuration จาก Panel

Installer จะเตรียม:

```text
Ubuntu
  │
  ├── Docker
  │
  ├── Wings
  │
  ├── /etc/pterodactyl/config.yml
  │
  ├── /data/pterodactyl
  │
  └── wings.service
```

เมื่อ Wings ทำงาน:

```text
Ubuntu Node
      │
      │
      ▼
Reviactyl Panel
      │
      ▼
Node 02 = Online
```

จากนั้นสามารถสร้าง Server ใหม่ใน Panel แล้วเลือก:

```text
Node:
DDC-02
```

ได้

---

# Important

`install-node.sh` **ไม่ได้สร้าง Node ใน Panel**

Node ต้องสร้างจาก Panel ก่อน เพราะ Configuration ของแต่ละ Node จะมีข้อมูลเฉพาะของ Node นั้น

Flow ที่ถูกต้อง:

```text
1. Reviactyl Panel
       │
       ▼
2. Create Node
       │
       ▼
3. Get Node Configuration
       │
       ▼
4. Ubuntu เครื่องใหม่
       │
       ▼
5. Run install-node.sh
       │
       ▼
6. Install Docker
       │
       ▼
7. Install Wings
       │
       ▼
8. Install config.yml
       │
       ▼
9. Start Wings
       │
       ▼
10. Node Online
```

---

# Security

อย่าเผยแพร่:

```text
/etc/pterodactyl/config.yml
```

โดยเฉพาะ Configuration ที่มี:

```text
Token
API credentials
Authentication information
Node credentials
```

ไม่ควร Commit ลง Git:

```text
config.yml
```

และไม่ควร Upload ไปยัง Public Repository

หาก Configuration ถูกเปิดเผย ควรสร้างหรือ Generate Credential ใหม่จาก Panel

---

# Troubleshooting

## Wings ไม่ Start

ตรวจสอบ:

```bash
systemctl status wings
```

ดู Log:

```bash
journalctl -u wings -n 100 --no-pager
```

หรือ:

```bash
journalctl -u wings -f
```

---

## Docker ไม่ทำงาน

ตรวจสอบ:

```bash
systemctl status docker
```

ลอง Restart:

```bash
systemctl restart docker
```

แล้ว:

```bash
systemctl restart wings
```

---

## Node ยัง Offline

ตรวจสอบตามลำดับ:

1. IP / FQDN ของ Node
2. DNS
3. Firewall
4. Port ของ Wings / Agent
5. `config.yml`
6. Docker
7. Wings Logs
8. Network ระหว่าง Panel และ Node

ดู Log:

```bash
journalctl -u wings -f
```

---

## DNS ไม่ตรง

ตรวจสอบ:

```bash
dig +short node02.example.com
```

IP ที่ได้ต้องตรงกับ IP ของ Node

---

## Port ไม่สามารถเชื่อมต่อได้

ตรวจสอบ Port ที่กำลัง Listen:

```bash
ss -lntup
```

ตรวจสอบเฉพาะ Port:

```bash
ss -lntup | grep 8080
```

เปลี่ยน `8080` เป็น Port ที่กำหนดใน Node Configuration

---

## Storage ไม่พอ

ตรวจสอบ:

```bash
df -h
```

ตรวจสอบ Storage ที่กำหนด:

```bash
df -h /data/pterodactyl
```

ตรวจสอบ Mount:

```bash
findmnt /data
```

หากใช้ Disk แยก ควรตรวจสอบว่า Disk ถูก Mount อัตโนมัติหลัง Reboot

```bash
cat /etc/fstab
```

---

## ตรวจสอบ Docker Containers

ดู Container:

```bash
docker ps
```

ดูทั้งหมด:

```bash
docker ps -a
```

หาก Wings ทำงานแต่ Server ไม่สามารถ Start ได้ ให้ตรวจสอบ Docker และ Wings Logs เพิ่มเติม

---

# Updating Wings

หากต้องการติดตั้ง Wings Version ใหม่ สามารถใช้:

```text
7) Reinstall Wings
```

จาก Installer

หลังติดตั้งควรตรวจสอบ:

```bash
wings --version
```

และ:

```bash
systemctl status wings
```

> ก่อน Update ควรตรวจสอบ Compatibility ระหว่าง Wings/Agent กับ Version ของ Panel ที่ใช้งานอยู่

---

# Reboot Test

หลังติดตั้ง Node เสร็จ แนะนำให้ทดสอบ Reboot:

```bash
reboot
```

หลังเครื่องกลับมา:

```bash
systemctl status docker
```

และ:

```bash
systemctl status wings
```

ตรวจสอบ Storage:

```bash
df -h
```

จากนั้นตรวจสอบ Node จาก Reviactyl Panel ว่ายัง Online

โดยเฉพาะกรณีใช้ Disk แยก ควรตรวจสอบว่า Disk ถูก Mount ก่อนที่ Wings จะเริ่มทำงาน

---

# Quick Install

สำหรับเครื่องที่เตรียมไว้แล้ว สามารถใช้:

```bash
wget https://raw.githubusercontent.com/CrafOps/Reviactyl-Renew-SSL/main/install-node.sh
chmod +x install-node.sh
sudo ./install-node.sh
```

จากนั้นเลือก:

```text
1) Install Node
```

และทำตามขั้นตอนของ Installer

---

# License

ใช้สำหรับการติดตั้งและจัดเตรียม Node สำหรับระบบ Reviactyl / Pterodactyl ของคุณเอง
