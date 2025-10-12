# LIVEIT Deployment Guide (DigitalOcean + AWS + Appwrite)

Tujuan

- Menyediakan panduan langkah demi langkah untuk deploy backend LIVEIT dengan memanfaatkan kredit DigitalOcean (DO) dan AWS, serta langganan Appwrite Pro.
- Fokus hemat biaya untuk MVP, tetapi siap skala dan mudah dipindah saat kredit habis.

—

Arsitektur Rekomendasi (MVP)

- Appwrite Pro (sudah berlangganan):
  - Auth: email/password, OAuth (Google/Apple/FB), recovery/reset.
  - Storage privat: avatar/cover/ilustrasi renungan (akses via backend proxy).
  - Databases (opsional): konten renungan harian dan editorial.
  - Functions + Scheduler (opsional): publish renungan harian, pembersihan data sementara.
- Backend (NestJS) di DigitalOcean:
  - 1 Droplet (Ubuntu) untuk API.
  - DO Managed PostgreSQL untuk data aplikasi (Profiles/Habit/UserHabit/Checkin).
  - Redis: awalnya self-host ringan (opsi: DO Managed Redis nanti).
- AWS (pakai kredit $100):
  - SES (email transaksi) + S3 (backup harian Postgres offsite).
  - Route 53 opsional; bisa pakai Cloudflare gratis untuk DNS/CDN/SSL.

—

Prasyarat

- Domain dan DNS (Cloudflare disarankan untuk SSL/TLS dan caching dasar).
- Akun Appwrite Pro aktif dan kredensial API.
- Akun DigitalOcean dan AWS dengan kredit aktif.
- Akses ke repo ini dan kemampuan SSH ke server.

—

Konfigurasi Appwrite

- Env backend yang dibutuhkan:
  - `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, `APPWRITE_API_KEY` (server key dengan akses Users/Account).
  - `APP_URL` (URL backend, mis. `https://api.liveit.yourdomain.com`).
  - `FRONTEND_URL` (URL aplikasi klien, mis. `https://app.liveit.yourdomain.com`).
- OAuth provider (Google/Apple/FB):
  - Daftarkan redirect:
    - `APP_URL/auth/google/callback`
    - `APP_URL/auth/oauth/:provider/callback`
- Email pemulihan:
  - Konfigurasi SMTP (disarankan gunakan AWS SES) di Appwrite Console agar fitur forgot/reset berjalan.
- Storage:
  - Buat bucket privat untuk avatar/covers jika perlu.

—

Provision di DigitalOcean

1) Droplet (Ubuntu 22.04)
- Tipe: Basic 2GB (1 vCPU, 2GB RAM) cukup untuk awal. Tambah ke 2 vCPU bila perlu.
- SSH key + firewall DO (buka 22, 80, 443).

2) Managed PostgreSQL
- Basic 1 vCPU/1GB/10GB cukup untuk 1k–10k user awal.
- Dapatkan `DATABASE_URL` (SSL on jika diwajibkan oleh DO). Format contoh:
  `postgresql://username:password@host:port/dbname?sslmode=require`

3) Redis
- Tahap awal: self-host di Droplet (hemat). Alternatif: DO Managed Redis Basic jika beban naik.
- Sesuaikan env: `REDIS_HOST`, `REDIS_PORT`.

—

Menyiapkan Server (Droplet)

Login dan setup dasar:

```
ssh root@your-droplet-ip
apt update && apt upgrade -y
apt install -y curl git build-essential ufw
ufw allow OpenSSH && ufw allow 80 && ufw allow 443 && ufw enable
```

Opsi A — Docker (disarankan jika Anda punya compose):

```
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER
apt install -y docker-compose-plugin
```

Opsi B — Node.js + PM2:

```
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm i -g pm2
```

Nginx + TLS (Let’s Encrypt):

```
apt install -y nginx certbot python3-certbot-nginx
```

Blok server Nginx contoh (reverse proxy ke Node pada port 3000):

```
server {
  server_name api.liveit.yourdomain.com;
  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $host;
  }
}
```

Aktifkan TLS:

```
ln -s /etc/nginx/sites-available/your.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
certbot --nginx -d api.liveit.yourdomain.com --redirect
```

—

Konfigurasi Aplikasi

Siapkan `.env` (lihat `.env.example`) di server:

```
DATABASE_URL="postgresql://..."
JWT_KEY="<random-32+ chars>"

APP_URL="https://api.liveit.yourdomain.com"
FRONTEND_URL="https://app.liveit.yourdomain.com"

APPWRITE_ENDPOINT="https://fra.cloud.appwrite.io/v1"
APPWRITE_PROJECT_ID="..."
APPWRITE_API_KEY="..."

OTC_TTL_SECONDS=180
EMAIL_CLAIM_TTL_SECONDS=900

REDIS_HOST=localhost
REDIS_PORT=6379
```

Build & run (Node + PM2):

```
npm ci
npm run build
pm2 start dist/main.js --name liveit-api
pm2 save && pm2 startup
```

—

Database: Migrasi & Seed

Production: gunakan deploy, bukan dev.

```
npx prisma migrate deploy
npx prisma db seed
```

Verifikasi cepat:

- `GET /habits/catalog` → harus keluar 3 habit kurasi (seed).
- Flow: `POST /habits` → `GET /habits` → `POST /habits/:id/checkin` → `DELETE /habits/:id/checkin`.
- Auth dasar: register/login/claim-username/forgot/reset.

—

Backup Harian ke AWS S3

1) Install AWS CLI & konfigurasi kredensial IAM (S3 + SES minimal):

```
apt install -y awscli
aws configure
```

2) Script backup (contoh `/opt/backup/pg_backup.sh`):

```
#!/usr/bin/env bash
set -euo pipefail
DATE=$(date +"%Y-%m-%d_%H-%M")
FILE="/tmp/liveit_${DATE}.sql.gz"
pg_dump "$DATABASE_URL" | gzip > "$FILE"
aws s3 cp "$FILE" s3://your-backup-bucket/liveit-db/ --storage-class STANDARD_IA
rm -f "$FILE"
```

3) Cron harian:

```
crontab -e
0 2 * * * DATABASE_URL="postgresql://..." bash /opt/backup/pg_backup.sh >> /var/log/pg_backup.log 2>&1
```

Uji restore di staging secara berkala.

—

Email Transaksional via AWS SES

- Verifikasi domain dan atur SMTP di Appwrite (untuk recovery) dan/atau di backend jika dibutuhkan.
- Catatan: SES sangat murah; kredit $100 cukup lama.

—

Monitoring & Alerting

- DO Monitoring: CPU, RAM, disk, network; aktifkan alert threshold sederhana.
- App logs: simpan via PM2/Journalctl; rotasi log.
- Healthchecks: gunakan layanan uptime (gratis/berbayar) untuk memantau endpoint health (mis. `/habits/catalog`).
- Performance: gunakan indeks Prisma sesuai query; pertimbangkan materialisasi ringkasan poin/streak.

—

Keamanan & Biaya

- Hindari NAT Gateway di awal (mahal). Gunakan Cloudflare/Let’s Encrypt untuk TLS.
- Batasi retensi data sementara (OTC, blacklist, email-claim code) dengan TTL.
- Simpan file/media di Appwrite Storage (privat) atau S3 (publik besar), bukan di Postgres.
- Tambah rate limit untuk endpoint sensitif (`@nestjs/throttler`).

—

Strategi Setelah Kredit Habis (2026)

- Tetap di DigitalOcean:
  - Perkiraan biaya/bulan (IDR):
    - Hemat: ~Rp 420–520 ribu (1 Droplet + DO PG + self-host Redis).
    - Nyaman: ~Rp 660–760 ribu (Managed Redis).
- Migrasi ke AWS (jika butuh RDS/Multi‑AZ/ekosistem AWS):
  - RDS PostgreSQL (Single‑AZ awal, Graviton t4g.small/medium), EC2 t4g (1–2 instance), ElastiCache kecil.
  - Siapkan IaC (Terraform), pipeline CI/CD, dan rencana cutover (dump/restore + window read‑only singkat).

—

Checklist Go‑Live Ringkas

- [ ] Appwrite: OAuth redirect, SMTP SES, API key Users/Account.
- [ ] DO: Droplet, firewall, Nginx+TLS, Managed PG, Redis.
- [ ] Backend: `.env` lengkap, migrate deploy, seed, start PM2.
- [ ] Backup S3 harian, uji restore.
- [ ] Monitoring + alert dasar, healthcheck uptime.
- [ ] Rate limit endpoint sensitif, TTL data sementara.

—

Catatan

- Biaya Appwrite Pro tidak dihitung di sini (sudah berlangganan).
- Angka biaya AWS/DO indikatif (tergantung region dan penggunaan); evaluasi ulang tiap kuartal.

—

Opsi Deploy dengan Docker Compose (API + Redis)

Struktur berkas di repo:

- `Dockerfile` — build image NestJS
- `docker/entrypoint.sh` — jalankan migrasi Prisma lalu start app
- `docker-compose.prod.yml` — jalankan API + Redis dalam satu host

Contoh `docker-compose.prod.yml`:

```
version: '3.8'
services:
  api:
    build: .
    container_name: liveit-api
    env_file:
      - .env
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    ports:
      - '3000:3000'
    depends_on:
      - redis
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: liveit-redis
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - redis-data:/data
    restart: unless-stopped

volumes:
  redis-data:
```

Langkah menjalankan (Docker):

1) Pastikan `.env` berisi `DATABASE_URL`, `APPWRITE_*`, `JWT_KEY`. Set `REDIS_HOST=redis` agar API mengakses service Redis di Compose.
2) Build & start:

```
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

3) Nginx reverse proxy arahkan domain ke `http://127.0.0.1:3000`.

Catatan:

- Rate-limit global sudah diaktifkan. Pada setup satu container, penyimpanan in-memory sudah cukup; Redis tersedia dan dapat digunakan sebagai shared storage saat scale-out (adapter Throttler‑Redis akan ditambahkan saat dibutuhkan).
- `docker/entrypoint.sh` otomatis menjalankan `npx prisma migrate deploy` sebelum start aplikasi.
- Jika menggunakan DO Managed Redis, set `REDIS_HOST` dan `REDIS_PORT` sesuai host managed, dan Anda bisa menghapus service `redis` dari Compose.
