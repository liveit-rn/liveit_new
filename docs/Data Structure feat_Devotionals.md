# **Struktur Data Appwrite: Koleksi devotionals**

Dokumen ini menjelaskan struktur atribut untuk koleksi devotionals dalam database Appwrite (liveitDB) untuk fitur Renungan Harian pada proyek LIVEIT.  
**Nama Koleksi:** devotionals

| Nama Field (Atribut) | Tipe Data Appwrite | Ukuran (jika perlu) | Wajib Diisi | Array | Deskripsi |
| :---- | :---- | :---- | :---- | :---- | :---- |
| title | String | 255 | Ya | Tidak | Judul utama renungan harian. |
| slug | String | 255 | Ya | Tidak | Versi judul yang ramah URL (unik, contoh: kasih-yang-mengubah-dunia). Harus unik untuk setiap entri. |
| snippet | String | 500 | Ya | Tidak | Ringkasan atau kutipan pendek untuk ditampilkan di kartu pratinjau atau daftar. |
| content | String | 100000 | Ya | Tidak | Isi lengkap renungan. Disarankan menggunakan format **Markdown** untuk mendukung rich text. |
| featured\_image\_id | String | 255 | Ya | Tidak | **ID File** dari gambar unggulan yang diunggah ke Appwrite Storage (misalnya, bucket "devotional\_images"). |
| publication\_date | Datetime | \- | Ya | Tidak | Tanggal dan waktu renungan dijadwalkan untuk dipublikasikan atau tanggal aktual publikasi. Digunakan untuk pengurutan. |
| status | String | 50 | Ya | Tidak | Status alur kerja renungan. Nilai yang mungkin:draft: Konten sedang ditulis/disimpan sebagai draf oleh penulis.pending\_review: Konten telah dikirim oleh penulis dan menunggu review dari tim kurasi.revision\_needed: Tim kurasi telah mereview dan meminta revisi dari penulis.published: Konten telah disetujui dan dipublikasikan, terlihat oleh publik.archived: Konten sudah tidak relevan untuk ditampilkan publik tapi masih disimpan. |
| author\_profile\_id | String | 255 (standar ID) | Ya | Tidak | **ID Dokumen** dari koleksi profiles yang merepresentasikan penulis renungan ini. Menciptakan relasi ke koleksi profiles. |
| likes\_count | Integer | \- | Tidak | Tidak | Jumlah 'like' yang diterima renungan ini. Default ke 0\. |
| views\_count | Integer | \- | Tidak | Tidak | (Opsional) Jumlah berapa kali renungan ini telah dilihat. Default ke 0\. |
| estimated\_read\_time | Integer | \- | Tidak | Tidak | (Opsional) Estimasi waktu baca renungan dalam satuan menit. Bisa dihitung otomatis dari content atau diisi manual. Default ke 0\. |
| last\_updated\_by | String | 255 (standar ID) | Tidak | Tidak | (Opsional) ID profil pengguna (dari tim internal) yang terakhir melakukan pembaruan pada dokumen ini. Berguna untuk audit. |
| scheduled\_publish\_at | Datetime | \- | Tidak | Tidak | (Opsional) Jika ingin menjadwalkan publikasi di masa depan. Jika diisi, status bisa tetap pending\_review atau approved sampai waktu ini tercapai. |

## **Catatan Tambahan:**

* **Indeks Database:** Pertimbangkan untuk menambahkan indeks pada field yang sering digunakan untuk query, seperti slug, status, publication\_date, dan author\_profile\_id untuk meningkatkan performa.  
* **Permissions (Izin Akses):**  
  * **Baca (read):**  
    * Untuk renungan dengan status: "published", izin baca harus diberikan kepada role:all (Any/Publik).  
    * Untuk renungan dengan status lain (draft, pending\_review, revision\_needed, archived), izin baca sebaiknya dibatasi hanya untuk author\_profile\_id yang bersangkutan dan tim kurasi/admin.  
  * **Tulis (create, update, delete):**  
    * Izin create diberikan kepada anggota tim internal yang berperan sebagai penulis.  
    * Izin update dan delete diberikan kepada author\_profile\_id yang bersangkutan (untuk tulisannya sendiri) dan tim kurasi/admin. Tim kurasi/admin juga memiliki hak untuk mengubah status.  
* **Relasi:**  
  * author\_profile\_id berelasi dengan $id dari dokumen di koleksi profiles.  
  * featured\_image\_id berelasi dengan $id dari file di Appwrite Storage.  
* **Workflow Status:** Alur perubahan status akan dikelola melalui logika di backend aplikasi Anda (misalnya, melalui Cloud Functions di Appwrite atau API di Next.js) yang dipicu oleh aksi pengguna di dasbor internal.

Dokumen ini dapat diupdate seiring dengan perkembangan kebutuhan fitur.