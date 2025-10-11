# LIVEIT Profiles Feature

## Tujuan

- Pengelolaan profil pengguna (non-kredensial) terpisah dari fitur Auth.
- Mendukung onboarding bertahap: klaim username (di Auth) dan klaim email (di Profiles) untuk pengguna OAuth yang tidak mendapat email dari provider.
- Menyediakan halaman profil publik dengan menghormati privasi.

---

## Endpoint

### 1. GET `/profiles/me`

- Deskripsi: Mengambil profil user yang sedang login.
- Auth: Bearer JWT (JwtAuthGuard)
- Response: Objek `Profiles` dari DB (mirror), termasuk field seperti `name`, `bio`, `privacy`, `links`, dsb.

### 2. PUT `/profiles/me`

- Deskripsi: Update field profil (non-kredensial).
- Auth: Bearer JWT
- Body (parsial):
  - `name`, `bio`, `birthDate (ISO)`, `location`, `privacy ('public'|'private')`,
  - `phoneNumber (E.164)`, `language`, `timezone`,
  - `marketingConsent`, `analyticsConsent`,
  - `links` (string[] URL)
- Catatan: `birthDate` akan di-parse ke Date, `links` disimpan sebagai JSON string di DB.

### 3. POST `/profiles/email/claim/start`

- Deskripsi: Memulai proses klaim email (untuk user yang memakai email placeholder).
- Auth: Bearer JWT
- Body: `{ email: string }` (valid `IsEmail`)
- Response: `{ code: string }` (kode sekali pakai, TTL default 900 detik via `EMAIL_CLAIM_TTL_SECONDS`).
- Catatan: Di produksi, kode ini sebaiknya dikirim via email; saat ini dikembalikan untuk kemudahan testing.

### 4. POST `/profiles/email/claim/confirm`

- Deskripsi: Menyelesaikan proses klaim email menggunakan `code`.
- Auth: Bearer JWT
- Body: `{ code: string }`
- Perilaku:
  - Validasi kode (ada dan milik user ini).
  - Re-check uniqueness email.
  - Update email di Appwrite (server SDK) dan di DB.
  - Hapus kode dari cache.
- Response: `{ success: true }`

### 5. GET `/profiles/u/:username`

- Deskripsi: Mendapatkan profil publik berdasarkan username. Tidak memerlukan login.
- Perilaku: Jika profil tidak ditemukan atau `privacy === 'private'`, balas 404.
- Response: Data disanitasi: `{ id, username, name, bio, links[], createdAt }`.

---

## Flow Klaim Email (Ringkas)

1) FE (user login) memanggil `POST /profiles/email/claim/start` dengan email baru.
2) BE membuat kode klaim sekali pakai (TTL `EMAIL_CLAIM_TTL_SECONDS`, default 900s) dan menyimpan payload `{ userId, email }` ke Redis.
3) FE memanggil `POST /profiles/email/claim/confirm { code }`.
4) BE memverifikasi kode, cek unik email, update email di Appwrite (Users.updateEmail) dan DB, lalu menghapus kode.

Motivasi: Beberapa OAuth provider tidak memberi email; saat onboarding dibuatkan email placeholder `noemail+<appwriteUserId>@placeholder.local`. Klaim email memungkinkan user mengganti placeholder menjadi email asli.

---

## Keamanan & Privasi

- Endpoint publik hanya mengembalikan subset data dan menghormati `privacy`.
- Kode klaim email disimpan singkat di Redis dan satu kali pakai.
- Uniqueness email diperiksa ganda untuk mencegah race condition.

---

## Konfigurasi

- `EMAIL_CLAIM_TTL_SECONDS` (default 900): Masa berlaku kode klaim email.
- `OTC_TTL_SECONDS` digunakan oleh fitur Auth (OAuth OTC), disebut di dokumen auth.

---

## Catatan Implementasi

- Update profil hanya untuk field non-kredensial; username tetap dikelola di Auth (`POST /auth/claim-username`).
- `links` disimpan sebagai JSON string di DB; FE bertanggung jawab untuk parse saat konsumsi.

