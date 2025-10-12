# 🔐 Dokumentasi Fitur Auth — LIVEIT

## 🎯 Tujuan

- Registrasi/Login user via email & password (Appwrite sebagai IdP).
- Dukungan OAuth (Google, Apple, dsb.).
- Backend NestJS sebagai **gateway** → FE tidak pernah kontak Appwrite langsung.
- PostgreSQL menyimpan **shadow user table** untuk anti lock-in.
- Mendukung hard-force onboarding username (dibahas di schema profiles).

---

## 🗂 Alur Arsitektur

1. **FE (React Native)** memanggil endpoint ke **NestJS**.
2. **NestJS AuthController** validasi DTO.
3. **AuthService** → Appwrite (Account/Session API).
4. Sukses → sinkron ke PostgreSQL `User`.
5. NestJS → terbitkan **JWT internal** (untuk FE).
6. Response → FE.

---

## 🛠 Endpoint API

### 1. `POST /auth/register`

**Deskripsi:** Buat akun baru (Appwrite + sinkronisasi PG). Username tidak diminta saat register; akan diklaim pada onboarding.

**Request Body**

```json
{
  "email": "user@example.com",
  "password": "MySecurePassw0rd!",
  "name": "John Doe" // opsional
}
```

**Response (201)**

```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "my_username",
    "createdAt": "2025-09-13T08:00:00.000Z",
    "updatedAt": "2025-09-13T08:00:00.000Z"
  },
  "access_token": "jwt_token_here",
  "expires_in": 86400
}
```

---

### Alur Register + Claim Username (Email/Password)

- FE menampilkan form register: email, password, (opsional) name.
- FE mengirim `POST /auth/register`.
- BE:
  - Membuat user di Appwrite: field `name` diisi dari input `name` (jika ada).
  - Menulis mirror ke PostgreSQL `Profiles` dengan `needsUsername=true` (karena belum klaim username).
  - Menerbitkan JWT (auto login) dan mengembalikan `AuthResponseDto`.
- FE mengarahkan user ke layar onboarding “Claim Username”.
- FE memanggil `GET /auth/username/check?username=...` untuk memastikan ketersediaan.
- FE mengirim `POST /auth/claim-username` dengan body `{ username }` (Butuh Bearer token) → BE set `username`, `usernameLower`, `needsUsername=false` dan memperbarui `name` di Appwrite.

Catatan:

- Appwrite tidak memiliki field `username` unik — uniqueness diberlakukan di Postgres via `Profiles.usernameLower`.

---

### 2. `POST /auth/login`

**Deskripsi:** Login dengan email & password (Appwrite session).

**Request Body**

```json
{
  "email": "user@example.com",
  "password": "MySecurePassw0rd!"
}
```

**Response (200)**

```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "my_username",
    "createdAt": "2025-09-13T08:00:00.000Z",
    "updatedAt": "2025-09-13T08:00:00.000Z"
  },
  "access_token": "jwt_token_here",
  "expires_in": 86400
}
```

---

### 3. `GET /auth/profile`

**Deskripsi:** Mendapatkan data user saat ini.

**Header**

```
Authorization: Bearer <access_token>
```

**Response (200)**

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "username": "my_username",
  "createdAt": "2025-09-13T08:00:00.000Z",
  "updatedAt": "2025-09-13T08:00:00.000Z"
}
```

---

### 4. `PUT /auth/profile` (Dipindahkan)

Endpoint update profile dipindahkan ke fitur Profiles (akan diimplementasikan terpisah). Endpoint ini tidak lagi tersedia di fitur Auth.

---

### 5. `POST /auth/logout`

**Deskripsi:** Logout → token diblacklist.

**Header**

```
Authorization: Bearer <access_token>
```

**Response (200)**

```json
{
  "success": true
}
```

---

### 6. `GET /auth/google/start`

**Deskripsi:** Redirect ke Google OAuth.

Tidak ada response JSON karena langsung redirect.

---

### 7. `GET /auth/google/callback`

**Deskripsi:** Callback dari Google OAuth → backend membuat One-Time Code (OTC), simpan sementara, lalu redirect ke FE dengan `?code=<otc>`.

**Response (302 Redirect)**

Redirect ke: `FRONTEND_URL/auth/callback?code=<otc>`

---

### 8. `GET /auth/google/failure`

**Deskripsi:** Redirect jika OAuth gagal.

**Response (302 Redirect)**
Ke halaman error di FE.

---

## 🧩 Komponen Teknis

### DTO

- **RegisterDto**: `email`, `username`, `password`
- **LoginDto**: `email`, `password`
- **UpdateProfileDto**: `username` (regex), `password` (strong policy)

### AuthResponseDto

```ts
export interface AuthResponseDto {
  user: {
    id: string;
    email: string;
    username: string | null;
    createdAt: Date;
    updatedAt: Date;
  };
  access_token: string;
  expires_in: number;
}
```

### Guard

- **JwtAuthGuard** → validasi Bearer token, inject payload ke `req.user`.

### Service

- `register` → buat user di Appwrite, insert ke PG, issue JWT.
- `signin` → Appwrite session, fetch PG, issue JWT.
- `updateProfile` → update PG + sync ke Appwrite.
- `logout` → blacklist token.
- `handleGoogleOAuthCallback` → OAuth → sinkronisasi user.

### Module

- `AuthModule` dengan `JwtModule` (secret, expiry 1d, issuer `liveit-server`, audience `liveit-client`).

### Dependencies

- `@nestjs/jwt`, `@nestjs/passport`, `passport-jwt`
- Install: `npm i @nestjs/passport passport-jwt`

---

## ✅ User Stories (MVP)

1. User bisa registrasi akun dengan email & password.
2. User bisa login dengan akun tersebut.
3. User bisa melihat profilnya sendiri.
4. User bisa update username & password.
5. User bisa logout.
6. User bisa login dengan Google (OAuth).

---

## 🔐 Security

- Password hanya di Appwrite (tidak disimpan di PG).
- JWT internal expire **1 hari**.
- Logout blacklist token server-side.
- Input tervalidasi dengan `class-validator`.

---

## 🚀 Next Steps

- Tambah **refresh token** untuk sesi panjang.
- Tambah Apple Sign-In & Facebook OAuth.
- Rate-limit untuk login/register.
- Retry sync ke Appwrite via job worker.

### 9. `POST /auth/oauth/exchange`

**Deskripsi:** Tukar OTC menjadi token JWT + data user. Hanya bisa dipakai sekali dan berlaku singkat.

**Request Body**

```json
{ "code": "<otc-from-callback>" }
```

**Response (200)**

```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "google_user123",
    "createdAt": "2025-09-13T08:00:00.000Z",
    "updatedAt": "2025-09-13T08:00:00.000Z"
  },
  "access_token": "jwt_token_here",
  "expires_in": 86400
}
```

### 11. `POST /auth/password/forgot`

**Deskripsi:** Kirim email pemulihan kata sandi. Selalu mengembalikan success (tidak membocorkan apakah email terdaftar).

**Request Body**

```json
{ "email": "user@example.com" }
```

**Response (200)**

```json
{ "success": true }
```

---

### 12. `POST /auth/password/reset`

**Deskripsi:** Setel ulang kata sandi menggunakan `userId` dan `secret` yang diperoleh dari tautan email Appwrite.

**Request Body**

```json
{
  "userId": "appwrite-user-id",
  "secret": "recovery-secret",
  "password": "NewPassw0rd!"
}
```

**Response (200)**

```json
{ "success": true }
```

### 10. `GET /auth/username/check?username=...`

**Deskripsi:** Cek ketersediaan username (case-insensitive).

**Response (200)**

```json
{ "available": true }
```

---

### 6b. `GET /auth/oauth/:provider/start`

**Deskripsi:** Redirect ke OAuth provider (google | facebook | apple) menggunakan satu endpoint generik.

---

### 7b. `GET /auth/oauth/:provider/callback`

**Deskripsi:** Callback dari provider OAuth → backend membuat OTC lalu redirect ke FE `?code=<otc>`.

---

### Catatan Email pada OAuth

- Beberapa provider (mis. Facebook dengan privacy setting tertentu, Apple dengan email privat) mungkin tidak memberikan email.
- Backend akan tetap membuat akun dengan email placeholder format `noemail+<appwriteUserId>@placeholder.local` dan menandai user untuk melengkapi profil (kebutuhan klaim email dapat diimplementasikan di fitur Profiles).
- Linking by email hanya dilakukan jika provider memang mengembalikan email.

### 11. `POST /auth/claim-username`

**Deskripsi:** Klaim username setelah register (Butuh Bearer token). Mengatur `username`, `usernameLower` (unik), `needsUsername=false` dan sinkron `name` di Appwrite.

**Request Body**

```json
{ "username": "my_username" }
```

**Response (200)**

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "username": "my_username",
  "needsUsername": false,
  "updatedAt": "2025-09-13T09:10:00.000Z"
}
```

## OAuth OTC Flow

- OTC: kode sekali pakai yang dihasilkan backend setelah OAuth sukses di Appwrite. Disimpan di cache (Redis) untuk waktu singkat. TTL dapat diatur via env `OTC_TTL_SECONDS` (default 60 detik; rekomendasi 120-300 detik untuk mobile).
- Alur:
  1. FE panggil `GET /auth/google/start` → redirect ke Google (via Appwrite)
  2. Appwrite redirect balik ke `GET /auth/google/callback?userId=...&secret=...`
  3. Backend buat sesi Appwrite, sinkron user → buat OTC → redirect ke FE dengan `?code=<otc>`
  4. FE kirim `POST /auth/oauth/exchange` dengan body `{ code }` → BE balikan JWT + data user

---

## Terminologi Utama

- TTL: Lama waktu data hidup di cache sebelum otomatis kadaluarsa. Di proyek ini:
  - OTC disimpan di Redis sesuai `OTC_TTL_SECONDS` (default 60 detik; bisa disesuaikan 120-300 detik untuk mobile).
  - Blacklist token logout disimpan hingga sisa masa berlaku token (dibatasi maksimal 86400 detik/1 hari).
- OTC: One-Time Code (kode sekali pakai) yang dikeluarkan backend untuk menukar hasil OAuth menjadi JWT internal. Menghindari menaruh token sensitif di URL.
- OTC Flow: Rangkaian langkah OAuth yang menggunakan OTC (lihat bagian di atas) alih-alih langsung mengembalikan JWT pada callback.

---

## Rate Limiting (Konsep)

- Apa: Pembatasan jumlah permintaan (request) per identitas (IP/user/key) dalam jendela waktu tertentu.
- Kenapa: Mencegah brute-force/credential stuffing, penyalahgunaan endpoint (login/register/username-check), dan menjaga stabilitas layanan.
- Penerapan tipikal di NestJS: gunakan `@nestjs/throttler` (global atau per-route guard), misalnya 5 permintaan/menit untuk login/register, 30 permintaan/menit untuk username-check, dan 5 permintaan/menit untuk `oauth/exchange`.
- Catatan: Tidak mengubah perilaku fungsional; hanya menolak request berlebih dengan error 429 (Too Many Requests).

---

## JWT Issuer/Audience dan Strategy/Guard

- Issuer (`iss`): Penerbit token (contoh: `liveit-server`). Membantu memastikan token memang dibuat oleh sistem kita.
- Audience (`aud`): Pihak/klien yang berhak memakai token (contoh: `liveit-client`). Mengurangi risiko token reuse lintas klien.
- Rekomendasi: Sertakan `issuer` dan `audience` saat menandatangani token dan verifikasi. Di implementasi terbaru, token disign dengan `issuer: liveit-server` dan `audience: liveit-client`, dan diverifikasi oleh JwtStrategy.
- JwtStrategy vs Guard:
  - JwtStrategy (Passport): Tempat standar untuk memverifikasi token, memeriksa `iss/aud/exp`, dan mengekstrak payload.
  - Guard: Gerbang akses di tiap route. Guard dapat memakai strategy (`AuthGuard('jwt')`) atau melakukan verifikasi manual.
  - Pola rekomendasi: Gunakan JwtStrategy untuk verifikasi dan decoding payload; Guard melapis pengecekan tambahan seperti blacklist Redis sebelum memberi akses.

### Implementasi Saat Ini

- Ditambahkan `JwtStrategy` di `src/auth/strategies/jwt.strategy.ts` berbasis `passport-jwt`.
- `JwtAuthGuard` kini mendelegasikan verifikasi JWT ke Passport (strategy), dan hanya menambahkan cek blacklist Redis.
- `AuthModule` mendaftarkan `PassportModule`, `JwtModule`, `JwtStrategy`, dan `JwtAuthGuard`.

---

## Alur Guard di Proyek Ini

- Rute yang dilindungi memakai `@UseGuards(JwtAuthGuard)`.
- Guard mengekstrak Bearer token dari header Authorization.
- Guard mengecek Redis: apakah token diblacklist (logout)? Jika ya → 401.
- Guard memverifikasi token dengan secret JWT; jika valid → `req.user` diisi payload; jika tidak → 401.
- Controller kemudian dapat memakai `req.user.sub` untuk identitas user (mis. get/update profile).
