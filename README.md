# Reviactyl Server Tools

ชุด Script สำหรับช่วยจัดการและเตรียมระบบ Server ที่ใช้งาน **Reviactyl / Pterodactyl**

Repository นี้รวมเครื่องมือสำหรับ:

* เตรียม Server เครื่องใหม่ให้เป็น Node
* ติดตั้งและจัดการ Wings
* ต่ออายุ SSL Certificate สำหรับ Panel / Wings
* จัดการงานพื้นฐานที่เกี่ยวข้องกับ Infrastructure ของ Reviactyl

---

## 📦 Tools

### 🖥️ Node Installer

ติดตั้งและเตรียมเครื่อง Server ใหม่ให้สามารถทำหน้าที่เป็น **Node** ของ Reviactyl / Pterodactyl Panel ที่มีอยู่แล้ว

เหมาะสำหรับ:

* เพิ่ม Node ใหม่
* Ubuntu Server
* ติดตั้ง Docker อัตโนมัติ
* ติดตั้ง Wings
* ใช้ `config.yml` จาก Panel
* กำหนด Server Storage เอง
* รองรับ Disk แยก
* สร้างและจัดการ `systemd` service

📖 **Documentation**

[Node-README.md](./Node-README.md)

Quick install:

```bash
wget https://raw.githubusercontent.com/CrafOps/Reviactyl-Renew-SSL/main/install-node.sh
chmod +x install-node.sh
sudo ./install-node.sh
```

---

### 🔐 SSL Renewer

Script สำหรับช่วยต่ออายุ **Let's Encrypt SSL Certificate** บน Server ที่ใช้งาน Nginx และ Pterodactyl Panel / Wings

โดย Script จะ:

* หยุด Nginx ชั่วคราว
* เคลียร์ Port 80 สำหรับ Certbot
* ใช้ Certbot แบบ Standalone
* ต่ออายุ SSL Certificate
* Start Nginx กลับ
* Restart Wings

📖 **Documentation**

[Renew-README.md](./Renew-README.md)

Quick install:

```bash
wget https://raw.githubusercontent.com/CrafOps/Reviactyl-Renew-SSL/main/renew_ssl.sh
chmod +x renew_ssl.sh
sudo ./renew_ssl.sh panel.yourdomain.com
```

---

# 📚 Documentation

| Tool           | Documentation                        | Description                                           |
| -------------- | ------------------------------------ | ----------------------------------------------------- |
| Node Installer | [Node-README.md](./Node-README.md)   | เตรียมเครื่องใหม่ให้เป็น Reviactyl / Pterodactyl Node |
| SSL Renewer    | [Renew-README.md](./Renew-README.md) | ต่ออายุ Let's Encrypt SSL Certificate                 |

---

# 📁 Repository Structure

```text
Reviactyl-Renew-SSL/
│
├── README.md
│
├── Node-README.md
├── Renew-README.md
│
├── install-node.sh
└── renew_ssl.sh
```

---

# 🚀 Quick Start

## Add a New Node

หากต้องการเพิ่ม Server เครื่องใหม่เข้า Reviactyl:

```text
Reviactyl Panel
       │
       ▼
Create Node
       │
       ▼
Get Node Configuration
       │
       ▼
New Server
       │
       ▼
install-node.sh
       │
       ▼
Docker + Wings
       │
       ▼
Node Online
```

ดูรายละเอียด:

[Node-README.md](./Node-README.md)

---

## Renew SSL

หากต้องการต่ออายุ SSL:

```text
Server
   │
   ▼
Stop Nginx
   │
   ▼
Certbot Standalone
   │
   ▼
Renew SSL
   │
   ▼
Start Nginx
   │
   ▼
Restart Wings
```

ดูรายละเอียด:

[Renew-README.md](./Renew-README.md)

---

# ⚠️ Security

Script และ Configuration ใน Repository นี้ควรใช้งานเฉพาะกับ Server ที่คุณมีสิทธิ์ในการดูแล

**ห้ามเผยแพร่หรือ Commit Credential ลง Repository**

โดยเฉพาะ:

```text
/etc/pterodactyl/config.yml
```

เนื่องจาก Configuration ของ Node อาจมีข้อมูลสำคัญ เช่น:

* Token
* API Credentials
* Authentication Information
* Node Credentials

หาก Credential ถูกเปิดเผย ควรสร้าง Credential ใหม่จาก Panel

---

# ⚠️ Before Using

ควรตรวจสอบ Configuration ของ Server ก่อนใช้งาน Script โดยเฉพาะ:

* OS Version
* Docker
* Firewall
* DNS
* Network
* Node Configuration
* Wings / Agent Version
* Server Storage
* SSL Configuration

ควรทดสอบ Script บนเครื่องที่สามารถเข้าถึงได้โดยตรงก่อนนำไปใช้งานกับ Production Server

---

# 🔗 Repository

[CrafOps / Reviactyl-Renew-SSL](https://github.com/CrafOps/Reviactyl-Renew-SSL/blob/main/?utm_source=chatgpt.com)

---

# License

ใช้สำหรับการจัดการและดูแลระบบ Reviactyl / Pterodactyl Server ของคุณเอง
