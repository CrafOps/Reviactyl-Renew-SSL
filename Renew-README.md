# Pterodactyl SSL Renewer

สคริปต์สำหรับช่วยต่ออายุใบรับรอง SSL ของ **Let's Encrypt** สำหรับ Server ที่ใช้งาน **Pterodactyl Panel / Wings** และใช้ **Nginx** เป็น Web Server

สคริปต์จะใช้ Certbot แบบ **Standalone** โดยหยุด Nginx ชั่วคราวเพื่อเคลียร์ Port 80 จากนั้นต่ออายุ Certificate และเปิด Nginx กลับมาให้โดยอัตโนมัติ

---

## ✨ Features

* ต่ออายุ Let's Encrypt Certificate ผ่าน Certbot
* ใช้ `standalone` mode
* หยุด Nginx ก่อนต่ออายุ
* ตรวจสอบและเคลียร์ Process ที่ใช้ Port 80
* Start Nginx กลับหลังต่ออายุ
* Restart Wings หลังต่อ Certificate
* รับ Domain ผ่าน command-line argument
* ตรวจสอบ Root permission
* หยุดการทำงานทันทีเมื่อเกิด Error
* เหมาะสำหรับ Server ที่รัน Pterodactyl Panel / Wings

---

# 🚀 Usage

## 1. Download

ดาวน์โหลด Script:

```bash
wget https://raw.githubusercontent.com/CrafOps/Reviactyl-Renew-SSL/main/renew_ssl.sh
```

หรือ:

```bash
curl -O https://raw.githubusercontent.com/CrafOps/Reviactyl-Renew-SSL/main/renew_ssl.sh
```

---

## 2. Permission

ตั้ง Permission ให้สามารถ Execute ได้:

```bash
chmod +x renew_ssl.sh
```

---

## 3. Run

รันด้วย Root หรือ `sudo`:

```bash
sudo ./renew_ssl.sh panel.yourdomain.com
```

ตัวอย่าง:

```bash
sudo ./renew_ssl.sh panel.crafops.com
```

---

# 🛠️ Script Workflow

เมื่อรัน:

```bash
sudo ./renew_ssl.sh panel.crafops.com
```

Script จะทำงานตามลำดับ:

```text
Start
  │
  ▼
Check Root Permission
  │
  ▼
Check Domain
  │
  ▼
Stop Nginx
  │
  ▼
Clear Port 80
  │
  ▼
Certbot Standalone
  │
  ▼
Renew SSL Certificate
  │
  ▼
Start Nginx
  │
  ▼
Restart Wings
  │
  ▼
Done
```

---

# 🔐 SSL Renewal

Script ใช้:

```bash
certbot certonly --standalone
```

ตัวอย่างการทำงาน:

```bash
certbot certonly \
    --standalone \
    -d panel.yourdomain.com
```

Certbot จะสร้าง/ต่ออายุ Certificate ของ Domain ที่ระบุ

Certificate โดยปกติจะอยู่ภายใต้:

```text
/etc/letsencrypt/live/<domain>/
```

ตัวอย่าง:

```text
/etc/letsencrypt/live/panel.crafops.com/
├── cert.pem
├── chain.pem
├── fullchain.pem
└── privkey.pem
```

---

# 🌐 Nginx

เนื่องจาก Standalone mode ต้องใช้ Port 80 Script จะหยุด Nginx ก่อน:

```bash
systemctl stop nginx
```

จากนั้นตรวจสอบ Port 80:

```bash
ss -ltnp | grep ':80'
```

หากพบ Process ที่ยังค้างอยู่ Script จะจัดการตาม logic ที่กำหนดไว้ใน Script

หลังจาก Certbot ทำงานเสร็จ จะเปิด Nginx กลับ:

```bash
systemctl start nginx
```

---

# 🪽 Wings

หลังต่อ SSL สำเร็จ Script จะ Restart Wings:

```bash
systemctl restart wings
```

เพื่อให้ Wings เริ่มต้นใหม่และโหลด Certificate configuration ล่าสุด

ตรวจสอบ:

```bash
systemctl status wings
```

---

# 📋 Requirements

ก่อนใช้งานควรมี:

* Linux Server
* Pterodactyl Panel และ/หรือ Wings
* Nginx
* Certbot
* Let's Encrypt
* Root / sudo permission
* DNS ของ Domain ชี้มายัง Server
* Port 80 สามารถเข้าถึงจาก Internet ได้

ติดตั้ง Certbot หากยังไม่มี:

```bash
apt update
apt install certbot -y
```

สำหรับ Ubuntu / Debian

---

# ⚠️ Important

เนื่องจาก Script ใช้:

```bash
certbot certonly --standalone
```

Domain ที่ต้องการต่อ SSL ต้องสามารถเข้าถึง Server ผ่าน:

```text
HTTP
Port 80
```

ได้

ตัวอย่าง:

```text
panel.crafops.com
      │
      ▼
103.xxx.xxx.xxx
      │
      ▼
Server
Port 80
```

หาก Port 80 ถูก Firewall, Cloudflare หรือ Reverse Proxy บังอยู่ อาจทำให้ HTTP-01 challenge ของ Let's Encrypt ไม่สำเร็จ

---

# ☁️ Cloudflare

หาก Domain ใช้ Cloudflare และเปิด Proxy:

```text
DNS
☁️ Proxied
```

Standalone HTTP-01 อาจมีปัญหาได้ ขึ้นอยู่กับ configuration

หากต้องการใช้ Standalone โดยตรง ควรตรวจสอบว่า Let's Encrypt สามารถเข้าถึง:

```text
http://panel.yourdomain.com/.well-known/acme-challenge/
```

ผ่าน Server ได้

---

# 🔥 Firewall

ต้องเปิด Port 80:

```bash
ufw allow 80/tcp
```

และ HTTPS:

```bash
ufw allow 443/tcp
```

ตรวจสอบ:

```bash
ufw status
```

หากใช้ Cloud Provider ให้ตรวจสอบ Security Group / Firewall ของ Provider ด้วย

---

# 🧪 Manual Test

สามารถทดสอบ Certbot ได้ก่อน:

```bash
sudo certbot certificates
```

ตรวจสอบ Certificate:

```bash
sudo ls -la /etc/letsencrypt/live/
```

และทดสอบ:

```bash
sudo certbot renew --dry-run
```

> `--dry-run` เป็นวิธีที่แนะนำสำหรับทดสอบ renewal โดยไม่แก้ Certificate จริง

---

# 🔧 Troubleshooting

## Nginx ไม่สามารถ Start ได้

ตรวจสอบ:

```bash
systemctl status nginx
```

และ:

```bash
nginx -t
```

หาก configuration มีปัญหา ให้แก้ก่อน:

```bash
nano /etc/nginx/nginx.conf
```

---

## Certbot ต่อ SSL ไม่สำเร็จ

ตรวจสอบว่า Port 80 ว่าง:

```bash
ss -ltnp | grep ':80'
```

ตรวจสอบ DNS:

```bash
dig +short panel.yourdomain.com
```

IP ที่ได้ควรเป็น IP ของ Server ที่กำลังรัน Script

---

## Wings ไม่ Start

ตรวจสอบ:

```bash
systemctl status wings
```

ดู Log:

```bash
journalctl -u wings -n 100 --no-pager
```

---

# 🔄 Recommended Renewal

สามารถตั้ง Cron ให้ตรวจสอบเป็นระยะได้ เช่น:

```bash
crontab -e
```

ตัวอย่าง:

```cron
0 3 * * * /root/renew_ssl.sh panel.yourdomain.com >> /var/log/pterodactyl-ssl-renew.log 2>&1
```

แต่ควรทดสอบ Script ด้วยตนเองก่อนเปิดใช้งาน Cron

---

# 📁 Files

ตัวอย่างไฟล์:

```text
renew_ssl.sh
README.md
```

Certificate:

```text
/etc/letsencrypt/
```

Log หากกำหนดเอง:

```text
/var/log/pterodactyl-ssl-renew.log
```

---

# ⚠️ Notes

Script นี้ออกแบบมาสำหรับระบบที่ต้องการใช้ **Certbot Standalone + Nginx**

หากระบบของคุณใช้:

* Cloudflare DNS Challenge
* Reverse Proxy
* Nginx Proxy Manager
* Traefik
* Caddy
* Load Balancer

ควรใช้วิธีต่อ Certificate ที่เหมาะกับ architecture นั้นแทนการหยุด Nginx และใช้ Standalone

---

# License

ใช้ได้สำหรับการจัดการ Server และ Infrastructure ของคุณเอง
