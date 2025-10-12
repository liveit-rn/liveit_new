# LIVEIT Blueprint

##

**Nama Project:** LIVEIT

**Tagline:** “Don’t just believe it, Live it.”

**Deskripsi:** LIVEIT adalah aplikasi mobile yang membantu umat Kristiani membangun kebiasaan rohani nyata melalui habit tracker action-oriented, gamifikasi bermakna, dan konten inspiratif berbasis Alkitab, serta komunitas yang aman dan saling menguatkan.

---

Visi & Misi

**Visi:**

Menjadi pendamping digital terpercaya yang membantu generasi muda Kristiani menjembatani kesenjangan antara pengetahuan spiritual dan implementasi praktis dalam kehidupan sehari-hari.

Misi:

Memudahkan pembentukan kebiasaan rohani yang sesuai dengan cara hidup Yesus melalui teknologi modern, desain menarik, dan konten alkitabiah yang relevan untuk generasi saat ini.

---

## **Target Market & Persona**

- **Usia:** 18–35 tahun (fokus utama)
- **Demografi:** Umat Kristiani dari berbagai denominasi, digital native, tech-savvy, ingin pertumbuhan iman praktis
- **Persona:** Mahasiswa, profesional muda, aktivis gereja yang ingin konsisten membangun habit rohani dan butuh komunitas pendukung

---

## **Analisis Masalah & Solusi**

**Masalah:**

- Sulit mengaplikasikan iman dalam kehidupan sehari-hari
- Kurang motivasi & akuntabilitas
- Praktik rohani terasa wajib, bukan gaya hidup
- Kesenjangan nilai Kristiani vs standar dunia

**Solusi LIVEIT:**

- Habit tracker action-oriented
- Gamifikasi bermakna (zoe points, badge, streak)
- Konten harian aplikatif & inspiratif
- Komunitas kecil yang aman & saling menguatkan

---

## **Fitur MVP**

### **1. Manajemen Akun**

- Registrasi/login (email, sosial media)
- Profil user & pengaturan preferensi

### **2. Habit Tracker**

- Tambah/edit/arsip habit rohani (kurasi tim + custom oleh user)
- Custom habit: aktif langsung untuk user; discoverability awal terbatas (tidak muncul di Explore/Pencarian 24–48 jam atau sampai lulus pemeriksaan otomatis).
- Moderasi pasca‑publikasi: admin dapat batasi jangkauan (limit reach), set private, arsip, dan kirim pesan pembinaan; tersedia pelaporan komunitas.
- Guardrails input: panduan penulisan, deteksi kata berisiko (untuk prioritas review), tanpa menghambat kreativitas pengguna.
- Check‑in harian (idempotent), undo hari berjalan, streak ramah manusia, “all‑done today”.
- Progress dashboard & statistik (tren sederhana, tidak ada leaderboard).
- Kategori tidak kaku di UI; gunakan tag/pilar internal untuk kurasi dan rekomendasi.
- Timezone‑aware day boundary (tahap berikut), awalnya UTC.
- Integritas data: satu `UserHabit` aktif per (user, habit) ditegakkan di DB (partial unique index) untuk cegah duplikasi saat race.
- Integrasi Devotional: tombol “Buat habit dari renungan” (one‑click template aman).

### **3. Renungan Harian (Daily Devotional)**

- Renungan kurasi tim/editor, diterbitkan harian (jadwal otomatis via Appwrite Functions/Scheduler).
- Backend bertindak sebagai facade API; konten dapat disimpan di Appwrite Databases (editorial workflow) dengan akses terproteksi.
- Aksi tindak lanjut: “Buat habit dari renungan” (sugesti micro‑habit aman, one‑click add ke Habit Tracker).
- Membaca renungan pribadi opsional (private); tanpa komentar publik untuk menghindari perdebatan; like sederhana (admin‑visible) jika diperlukan.
- Pre‑launch media: kanal sosial diisi 2–4 minggu sebelum peluncuran untuk membangun awareness dan konsistensi konten.

### **4. Gamifikasi**

- Zoe points: +10/check-in, +20/semua habit selesai, +50/7 hari streak, +100/30 hari streak
- Level:
  - Level 1: 0–99
  - Level 2: 100–249
  - Level 3: 250–499
  - dst. (lihat detail leveling)
- Badge/Achievement:
  - First Step (check-in pertama)
  - First Week Warrior (7 hari streak)
  - Faithful Follower (30 hari streak)
  - Consistency Champion (100 check-in)
  - Category Explorer (3 kategori habit)
  - Daily Completer (semua habit selesai 1 hari)
  - Comeback Kid (kembali setelah streak putus)

### **5. Notifikasi**

- Reminder habit & motivasi harian

---

## **Roadmap Fitur Lanjutan (Post-MVP)**

- Grup akuntabilitas kecil (chat template, encouragement)
- Prayer request board (tanpa komentar, hanya “Saya doakan”)
- Weekly challenge komunitas
- Konten library & challenge tematik
- Fitur donasi/support, event online, partnership gereja

---

## **Tech Stack & Arsitektur**

- **Mobile:** Flutter, BloC, Auto_route, dio,
- **Backend:** NestJS (Bertindak sebagai _proxy/facade_ untuk semua layanan, termasuk otentikasi. Mengelola logika bisnis inti dan database PostgreSQL).
- **Landing Page:** Next.js, Tailwind CSS
- **Layanan Pihak Ketiga:**
  - **Appwrite:** Digunakan sebagai _backend service_ untuk:
    - **Manajemen Otentikasi:** Menangani proses registrasi, login (email/sosial media), dan manajemen sesi. Dipanggil melalui backend NestJS (Pola Proksi).
    - **Manajemen Konten:** Menyimpan dan menyajikan konten seperti renungan harian dan daftar habit.
  - **Notion:** Digunakan untuk workflow editorial dan backup konten.
- **Database:** PostgreSQL (Dikelola oleh NestJS via Prisma, menyimpan data inti aplikasi seperti profil pengguna, progres habit, poin, dll).
- **DevOps:** GitHub, GitHub Actions, manual testing, backup data rutin.

### **Arsitektur Otentikasi (Pola Proksi)**

Untuk memastikan fleksibilitas dan mengurangi _vendor lock-in_, LIVEIT akan mengadopsi pola proksi untuk otentikasi:

1.  **Klien (Mobile/Web)** hanya berkomunikasi dengan **satu endpoint**, yaitu backend NestJS.
2.  **Backend NestJS** menyediakan endpoint seperti `/auth/register` dan `/auth/login`.
3.  Saat endpoint tersebut dipanggil, **Backend NestJS** akan meneruskan permintaan ke **Appwrite** menggunakan Appwrite Node.js SDK.
4.  Appwrite menangani logika otentikasi (validasi, hashing, dll.) dan mengembalikan hasilnya ke backend NestJS.
5.  Backend NestJS kemudian menyinkronkan data pengguna ke database **PostgreSQL** lokal (membuat/memperbarui "shadow user table") sebelum mengirimkan respons akhir (misalnya, token) kembali ke klien.

**Keuntungan Pola Ini:**

- **Abstraksi:** Klien tidak tahu tentang Appwrite, membuatnya mudah untuk diganti di masa depan.
- **Kontrol Terpusat:** Semua logika, validasi, dan keamanan tambahan dapat diimplementasikan di backend NestJS.
- **Future-Proof:** Memudahkan migrasi ke sistem otentikasi _in-house_ jika diperlukan, karena data pengguna sudah ada di PostgreSQL.

---

## **Model Data Kunci**

**User, Habit, UserHabit, ActionLog, Achievement, Devotional, Like**

---

## **Konten & Editorial**

- Konten renungan harian dikurasi terlebih dahulu
- Kalender konten 30 hari disiapkan sebelum launch
- Konten social media (IG/TikTok): inspirasi, tips, challenge, testimoni

---

## **Komunitas & Moderasi**

- Komunitas berbasis grup kecil, pesan encouragement template, tanpa komentar bebas
- Fitur report/mute user
- Guidelines & disclaimer jelas untuk menjaga kenyamanan dan menghindari konflik doktrin

---

## **Planning & Timeline (Estimasi Fleksibel)**

1. **Persiapan & Setup:** 1–2 minggu
   - Scope, repo, infrastruktur, desain dasar
2. **Pengembangan MVP:** 2–3 minggu
   - Auth, habit tracker, renungan, gamifikasi, notifikasi
3. **Konten & Kurasi:** 2 minggu (paralel)
   - 30 hari renungan, review devotional, konten social media
4. **Testing & Pre-Launch:** 1 minggu
   - Beta test, feedback, bugfix
5. **Launch:** 1 minggu

---

## **Tim & Resource**

- Kevin: Lead Fullstack-dev, PM
- Bagus: Fullstack dev

---

## **Strategi Positioning**

- Fokus pada actionable faith, gamifikasi spiritual, komunitas aman
- Konten relatable, inspiratif, dan membangun habit nyata

@This document contains confidential and proprietary information belonging to Alexandro Kevin. It is intended solely for the use of the individual or entity to whom it is addressed. Unauthorized copying, disclosure, or distribution of the material in this document is strictly forbidden. If you have received this document in error, please notify the owner immediately. © 2025 Alexandro Kevin. All Rights Reserved.
