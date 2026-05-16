#!/bin/bash

echo "=========================================="
echo " เริ่มต้นกระบวนการต่ออายุ SSL สำหรับ Pterodactyl "
echo "=========================================="

# 1. หยุดการทำงานของ Nginx และล้าง Process ที่ค้างอยู่
echo "[1/4] กำลังหยุดการทำงานของ Nginx..."
systemctl stop nginx
pkill -f nginx
sleep 2 # รอให้ระบบปิดตัวสนิท

# 2. รัน Certbot เพื่อขอใบรับรองใหม่
echo "[2/4] กำลังเริ่มรัน Certbot ต่ออายุใบรับรอง..."
certbot certonly --standalone -d panel.domain.name

# 3. เปิด Nginx กลับมาทำงานตามปกติ
echo "[3/4] กำลังเปิดการทำงานของ Nginx..."
systemctl start nginx

# 4. รีสตาร์ทระบบ Wings เพื่ออัปเดตใบรับรองใหม่
echo "[4/4] กำลังรีสตาร์ทระบบ Wings..."
systemctl restart wings

echo "=========================================="
echo "          ดำเนินการเสร็จสิ้นเรียบร้อย!          "
echo "=========================================="
