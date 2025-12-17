#!/bin/bash

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_DIR="/Users/aligedik/Desktop/VTYS proje"

echo -e "${YELLOW}🚀 Akademik Not Sistemi Başlatılıyor...${NC}"

# 1. Docker container'ı başlat (eğer çalışmıyorsa)
echo -e "${GREEN}📦 Docker container kontrol ediliyor...${NC}"
if ! docker ps | grep -q akademik-sql; then
    if docker ps -a | grep -q akademik-sql; then
        docker start akademik-sql
        echo "   ⏳ SQL Server başlatılıyor, 5 saniye bekleniyor..."
        sleep 5
    else
        echo -e "${RED}   ❌ akademik-sql container bulunamadı!${NC}"
        echo "   Önce Docker container'ı oluşturun."
        exit 1
    fi
else
    echo "   ✓ SQL Server zaten çalışıyor"
fi

# 2. Backend'i arka planda başlat
echo -e "${GREEN}🔧 Backend başlatılıyor...${NC}"
cd "$PROJECT_DIR/backend"
node server.js &
BACKEND_PID=$!
sleep 2

# Backend'in başladığını kontrol et
if ps -p $BACKEND_PID > /dev/null; then
    echo "   ✓ Backend başlatıldı (PID: $BACKEND_PID)"
else
    echo -e "${RED}   ❌ Backend başlatılamadı!${NC}"
    exit 1
fi

# 3. Frontend'i arka planda başlat
echo -e "${GREEN}🎨 Frontend başlatılıyor...${NC}"
cd "$PROJECT_DIR/frontend"
npm run dev &
FRONTEND_PID=$!
sleep 3

# 4. Firefox'ta aç
echo -e "${GREEN}🌐 Firefox açılıyor...${NC}"
open -a Firefox http://localhost:5173

echo -e "${YELLOW}
========================================
✅ Sistem başarıyla başlatıldı!

📊 Backend:  http://localhost:5001 (PID: $BACKEND_PID)
🎨 Frontend: http://localhost:5173 (PID: $FRONTEND_PID)

🔐 Giriş Bilgileri:
   Admin:     admin / Admin@123
   Akademik:  ayse.akademik / Akademik@123
   Öğrenci:   mehmet.ogrenci / Ogrenci@123

Durdurmak için: Ctrl+C
========================================
${NC}"

# Ctrl+C ile kapatıldığında process'leri temizle
cleanup() {
    echo -e "\n${YELLOW}🛑 Sistem kapatılıyor...${NC}"
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}✓ Tüm servisler durduruldu.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Script'in çalışmaya devam etmesi için bekle
wait

