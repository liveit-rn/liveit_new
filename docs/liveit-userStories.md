User Stories - LIVEIT Minimum Viable Product (MVP)
Dokumen ini berisi User Stories yang mendefinisikan fungsionalitas inti untuk rilis pertama aplikasi LIVEIT. Cerita-cerita ini berfokus pada kebutuhan pengguna utama dan mencerminkan filosofi proyek yang mendukung pertumbuhan spiritual melalui konsistensi dan refleksi.
Epic: Onboarding & Manajemen Akun
Tujuan: Memungkinkan pengguna untuk bergabung dengan platform dan memiliki identitas yang aman untuk menyimpan progres mereka.

1. Pendaftaran Akun
   Sebagai seorang pengguna baru, saya ingin bisa mendaftar akun menggunakan email, name, dan kata sandi, supaya progres dan pencapaian saya dapat disimpan dengan aman.
   Kriteria Penerimaan:
   Terdapat form pendaftaran untuk email, nama, dan kata sandi.
   Sistem memvalidasi format email.
   Setelah pendaftaran berhasil, pengguna secara otomatis masuk ke halaman claim-username untuk klaim username(seperti di instagram/twitter), disini juga lakukan pengecekan apakah username yang saya input tersedia atau tidak, jika tidak tersedia/username nya sudah dipakai oleh user lain maka tombol next tidak dapat ditekan, jika tersedia baru bisa lanjut ke halaman berikutnya.
   Sistem memberikan pesan error jika email sudah terdaftar.
2. Login Pengguna
   Sebagai seorang pengguna yang telah terdaftar, saya ingin bisa masuk (login) ke akun saya, supaya saya dapat melanjutkan perjalanan dan melihat progres saya sebelumnya.
   Kriteria Penerimaan:
   Terdapat form login untuk email dan kata sandi.
   Setelah login berhasil, pengguna diarahkan ke halaman utama (Daftar Habit Harian).
   Sistem memberikan pesan error jika email atau kata sandi salah.
   Epic: Manajemen Habit (Core Loop)
   Tujuan: Menyediakan fungsionalitas inti bagi pengguna untuk memilih, melacak, dan menyelesaikan kebiasaan rohani harian mereka.
3. Menambahkan Habit
   Sebagai seorang pengguna, saya ingin bisa memilih dan menambahkan habit dari daftar yang telah disediakan (misal: 'Saat Teduh', 'Baca Alkitab', 'Berdoa Syafaat'), supaya saya bisa mulai membangun disiplin rohani saya.
   Kriteria Penerimaan:
   Aplikasi menyediakan daftar habit yang sudah dikurasi dan dikategorikan.
   Pengguna dapat memilih satu atau lebih habit untuk ditambahkan ke daftar harian mereka.
   Habit yang dipilih akan muncul di halaman utama.
4. Melihat Daftar Habit Harian
   Sebagai seorang pengguna, saya ingin melihat semua habit aktif saya dalam sebuah daftar di halaman utama, supaya saya tahu apa saja yang perlu saya kerjakan hari ini.
   Kriteria Penerimaan:
   Halaman utama menampilkan daftar habit yang harus diselesaikan untuk hari itu.
   Setiap item habit memiliki kotak centang (checkbox) yang belum terisi.
5. Check-in Habit
   Sebagai seorang pengguna, saya ingin bisa menandai (check-in) sebuah habit sebagai 'selesai' untuk hari ini, supaya saya dapat mencatat kemajuan saya dan merasakan pencapaian.
   Kriteria Penerimaan:
   Saat kotak centang ditekan, habit tersebut secara visual ditandai sebagai selesai (misal: teks dicoret, warna berubah).
   Tindakan check-in memicu penambahan "Zoe Points".
   Status check-in direset setiap hari.
   Epic: Sistem Gamifikasi & Progres
   Tujuan: Memberikan motivasi dan cerminan visual dari pertumbuhan pengguna melalui poin, tingkatan, dan pencapaian yang suportif.
6. Mendapatkan Poin & Naik Tingkat
   Sebagai seorang pengguna, saya ingin mendapatkan "Zoe Points" untuk setiap check-in dan pencapaian lainnya, supaya saya bisa melihat "Tingkatan Perjalanan" saya meningkat seiring waktu.
   Kriteria Penerimaan:
   Pengguna menerima +10 ZP untuk setiap check-in.
   Pengguna menerima bonus +20 ZP saat semua habit harian selesai.
   Jumlah total ZP pengguna terlihat di UI.
   Saat ZP mencapai ambang batas, "Tingkatan Perjalanan" pengguna (misal: dari 'Langkah Pertama' ke 'Membangun Irama') diperbarui secara otomatis.
   Sebuah notifikasi sederhana muncul saat pengguna naik tingkat.
7. Mendapatkan Badge & Momen Refleksi
   Sebagai seorang pengguna, saya ingin menerima badge saat mencapai tonggak sejarah tertentu (misal: check-in pertama, streak 7 hari), supaya saya merasa didukung dan termotivasi untuk berefleksi.
   Kriteria Penerimaan:
   Badge "First Step" diberikan setelah check-in pertama kali.
   Badge "First Week Warrior" diberikan setelah 7 hari beruntun melakukan check-in.
   Badge "Comeback Kid" diberikan saat pengguna check-in kembali setelah melewatkan satu hari atau lebih.
   Saat badge diterima, sebuah pesan yang berisi "Momen Refleksi" akan muncul.
   Epic: Profil Pengguna
   Tujuan: Memberikan satu tempat bagi pengguna untuk melihat rangkuman perjalanan, pencapaian, dan pertumbuhan mereka.
8. Mengakses Halaman Profil
   Sebagai seorang pengguna, saya ingin bisa mengakses halaman profil saya, supaya saya dapat melihat semua rangkuman progres saya di satu tempat.
   Kriteria Penerimaan:
   Terdapat tombol atau tautan yang jelas untuk menuju ke halaman profil.
9. Melihat Rangkuman Progres
   Sebagai seorang pengguna, di halaman profil, saya ingin melihat total "Zoe Points", "Tingkatan Perjalanan" saat ini, dan semua badge yang telah saya kumpulkan, supaya saya bisa melihat sejauh mana saya telah bertumbuh.
   Kriteria Penerimaan:
   Halaman profil dengan jelas menampilkan nama pengguna.
   Menampilkan total ZP saat ini.
   Menampilkan ikon dan nama "Tingkatan Perjalanan" saat ini.
   Menampilkan galeri visual dari semua badge yang telah berhasil didapatkan.

   Epic: Social / Federated Login
   Tujuan: Memudahkan pengguna mendaftar / masuk cepat tanpa harus membuat password manual.
   10. Mengatur Privasi Profil
       Sebagai seorang pengguna, saya ingin bisa mengatur apakah profil saya bersifat publik atau privat, supaya saya bisa mengontrol siapa yang bisa melihat informasi saya.
       Kriteria Penerimaan:
       Di halaman profil atau pengaturan, terdapat opsi toggle atau dropdown untuk memilih "Public" atau "Private".
       Jika "Public", profil dapat diakses oleh siapa saja melalui URL `/profiles/u/:username`.
       Jika "Private", profil tidak dapat diakses oleh orang lain; hanya pemilik yang bisa melihatnya.
       Perubahan privasi disimpan secara real-time dan berlaku segera.
       Pengguna mendapat konfirmasi saat mengubah pengaturan privasi.

10. Melihat Profil Publik Orang Lain
    Sebagai seorang pengguna, saya ingin bisa melihat profil publik pengguna lain, supaya saya bisa terinspirasi oleh perjalanan mereka.
    Kriteria Penerimaan:
    Saat mengakses `/profiles/u/:username` dari profil publik, menampilkan data seperti username, name, bio, links, dan createdAt.
    Jika profil privat, menampilkan pesan "Profil ini bersifat privat" atau 404.
    Tidak memerlukan login untuk melihat profil publik.
    UI menunjukkan indikator jika profil privat.

11. Login dengan Google
    Sebagai pengguna baru atau lama, saya ingin bisa masuk menggunakan akun Google saya, supaya proses onboarding cepat dan aman.
    Kriteria Penerimaan:
    - Terdapat tombol "Lanjutkan dengan Google".
    - Setelah ditekan, muncul layar consent Google (native/webview).
    - Jika sukses dan akun baru: sistem membuat profil dan mengarahkan ke halaman claim-username bila belum ada username.
    - Jika email sudah terdaftar: sistem melakukan linking dan login tanpa duplikasi akun.
    - Token internal (JWT) dibuat dan dikirim ke app.
    - Jika pengguna membatalkan, muncul pesan non-intrusif dan tetap di layar login.
    - Error dari provider ditangani (network, revoked, expired).

12. Login dengan Meta (Facebook)
    Sebagai pengguna, saya ingin bisa login dengan akun Facebook saya, supaya punya alternatif selain email.
    Kriteria Penerimaan:
    - Tombol "Lanjutkan dengan Facebook".
    - Flow OAuth berhasil mengembalikan identitas (id, email optional, name).
    - Jika email tidak diberikan (privacy setting), sistem tetap membuat akun sementara dan menandai perlu verifikasi email nanti.
    - Mapping / linking akun jika sudah ada email yang sama.
    - Username claim flow dijalankan jika belum ada.
    - JWT internal diberikan.
    - Error (cancel, permission denied) ditangani dengan pesan jelas.

13. Login dengan Apple
    Sebagai pengguna perangkat Apple, saya ingin bisa login menggunakan Apple ID, supaya lebih privat dan mudah.
    Kriteria Penerimaan:
    - Tombol "Lanjutkan dengan Apple" ditampilkan pada iOS (opsional di platform lain).
    - Mendukung email privat (relay). Jika Apple memberi email relay, sistem tetap menyimpannya.
    - Name hanya tersedia pada first authorization; jika hilang, sistem minta user melengkapi atau lanjut ke claim-username.
    - Linking akun jika email (relay atau nyata) cocok dengan akun sebelumnya.
    - JWT internal dibuat.
    - Revoke / cancel ditangani dengan pesan ramah.
    - Data minimal disimpan (prinsip privacy).

Catatan Teknis Umum Federated Login:

- Semua provider menghasilkan satu titik masuk backend: /auth/oauth/:provider (atau mekanisme OTC seperti yang sudah ada).
- Pastikan idempotensi: beberapa klik tidak membuat multi akun.
- Logging keamanan: simpan provider, timestamp, userId.
- Rate limiting untuk percobaan login berulang.
