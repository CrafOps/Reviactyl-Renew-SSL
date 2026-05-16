# Pterodactyl SSL Renewer Script

สคริปต์แบบง่ายสำหรับช่วยต่ออายุใบรับรอง SSL (Let's Encrypt) บน Server ที่รันระบบ **Pterodactyl Panel** และ **Wings** โดยจะทำหน้าที่ปิดบริการ Web Server (Nginx) ชั่วคราว สั่งต่ออายุผ่านโหมด Standalone และสั่งเปิดระบบกลับมาพร้อมใช้งานทันที

## 🚀 วิธีการใช้งาน (Usage)

1. ดาวน์โหลดสคริปต์ลงเครื่อง Server ของคุณ:
```bash
wget https://raw.githubusercontent.com/CrafOps/Reviactyl-Renew-SSL/main/renew_ssl.sh
```

2. ตั้งค่าอนุญาตให้สคริปต์สามารถทำงานได้ (Permission):
```bash
chmod +x renew_ssl.sh
```

3. รันสคริปต์โดยใส่ **ชื่อโดเมน** ของคุณตามท้าย (รันด้วยสิทธิ์ root หรือ sudo):
```bash
sudo ./renew_ssl.sh panel.yourdomain.com
```

## 🛠️ สคริปต์นี้ทำอะไรบ้าง?
- สั่งหยุดการทำงานของบริการ `nginx` และเคลียร์โปรเซสที่ค้างคาอยู่ทั้งหมดเพื่อเคลียร์พอร์ต 80/443
- รันคำสั่ง `certbot certonly --standalone` ตรงไปยังโดเมนที่ระบุ
- สั่งเริ่มการทำงานของ `nginx` ใหม่อีกครั้ง
- รีสตาร์ทบริการ `wings` เพื่อให้ Node อัปเดตไปใช้ใบรับรองความปลอดภัยเวอร์ชันล่าสุดอัตโนมัติ
