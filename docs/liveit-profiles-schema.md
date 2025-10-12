# 📑 Profiles Schema — LIVEIT (Final, sesuai implementasi)

## 🎯 Tujuan

- FE **tidak pernah** kontak Appwrite langsung; semua lewat **Backend NestJS** (proxy).
- Hard-force onboarding: user **wajib** klaim username setelah registrasi.
- Penyimpanan gambar **private** di Appwrite; BE men-proxy ke FE.
- Anti lock-in: mudah migrasi storage/IdP di masa depan.

---

## 🗂 Appwrite Database

- **Database**: `liveitDB`
- **Collection**: `profiles`
- **Buckets (Storage)**:
  - `avatars` (private read)
  - `covers` (private read)

### Fields

| Field               | Type          | Required | Unique | Notes                                                                                  |
| ------------------- | ------------- | -------: | :----: | -------------------------------------------------------------------------------------- |
| `userId`            | String        |       ✅ |   ✅   | Appwrite Auth User ID (1:1). Dok ID bisa = `userId` (disarankan).                      |
| `email`             | String        |       ✅ |   ✅   | Sinkron dengan Auth & PG.                                                              |
| `username`          | String        |       ❌ |   ✅   | **Nullable** sampai diklaim di onboarding. Regex: `^[A-Za-z0-9_]{3,30}$`.              |
| `usernameLower`     | String        |       ❌ |   ✅   | **Nullable**; simpan `lower(username)` untuk uniqueness **case-insensitive** & search. |
| `needsUsername`     | Boolean       |       ✅ |   ❌   | Default `true` saat register; set `false` setelah klaim username.                      |
| `name`              | String (≤50)  |       ❌ |   ❌   | Display name (bukan unik).                                                             |
| `bio`               | String (≤160) |       ❌ |   ❌   | Bio singkat.                                                                           |
| `profileImageId`    | String        |       ❌ |   ❌   | **fileId** dari bucket `avatars` (private).                                            |
| `coverImageId`      | String        |       ❌ |   ❌   | **fileId** dari bucket `covers` (private).                                             |
| `birthDate`         | Datetime      |       ❌ |   ❌   | Opsional.                                                                              |
| `location`          | String        |       ❌ |   ❌   | Opsional.                                                                              |
| `privacy`           | Enum          |       ❌ |   ❌   | `public` \| `private` (opsional; untuk akun privat ala IG).                            |
| `usernameChangedAt` | Datetime      |       ❌ |   ❌   | Tanggal terakhir ganti username (opsional; throttle rename).                           |
| `phoneNumber`       | String        |       ❌ |   ❌   | E.164 (opsional; recovery/2FA).                                                        |
| `phoneVerified`     | Boolean       |       ❌ |   ❌   | Default `false` (opsional).                                                            |
| `language`          | String        |       ❌ |   ❌   | Mis. `id-ID`, `en-US` (opsional).                                                      |
| `timezone`          | String        |       ❌ |   ❌   | Mis. `Asia/Jakarta` (opsional).                                                        |
| `tosAcceptedAt`     | Datetime      |       ❌ |   ❌   | Consent (opsional).                                                                    |
| `marketingConsent`  | Boolean       |       ❌ |   ❌   | Default `false` (opsional).                                                            |
| `analyticsConsent`  | Boolean       |       ❌ |   ❌   | Default `true` (opsional).                                                             |
| `links`             | Array<String> |       ❌ |   ❌   | URL eksternal di bio (opsional).                                                       |
| `deletedAt`         | Datetime      |       ❌ |   ❌   | Soft delete (opsional).                                                                |
| `$createdAt`        | Datetime      |       ✅ |   –    | Otomatis Appwrite.                                                                     |
| `$updatedAt`        | Datetime      |       ✅ |   –    | Otomatis Appwrite.                                                                     |

### Indexes & Validasi

- **Unique**: `userId`, `email`, `usernameLower`  
  (Appwrite mengizinkan banyak `NULL` pada unique → aman untuk fase pra-klaim).
- **Regex** `username`: `^[A-Za-z0-9_]{3,30}$`
- **Case-insensitive uniqueness**: validasi menggunakan `usernameLower`.

---

## 🗄 PostgreSQL (Prisma) — Shadow/Mirror Minimal

```prisma
model User {
  id             String   @id @default(uuid())
  appwriteUserId String   @unique
  email          String   @unique

  // Klaim di onboarding (nullable sampai selesai)
  username       String?  @unique
  usernameLower  String?  @unique
  needsUsername  Boolean  @default(true)

  // Mirror ringan (opsional tapi direkomendasikan untuk read cepat)
  name           String?
  bio            String?
  profileImageId String?
  coverImageId   String?
  birthDate      DateTime?
  location       String?

  // Lainnya (opsional)
  privacy        String?    // "public" | "private"
  usernameChangedAt DateTime?
  phoneNumber    String?
  phoneVerified  Boolean? @default(false)
  language       String?
  timezone       String?
  tosAcceptedAt  DateTime?
  marketingConsent Boolean? @default(false)
  analyticsConsent Boolean? @default(true)
  links          String?    // bisa JSON text/array jika perlu
  deletedAt      DateTime?

  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt
}
```
