# 💰 MyDompet — Personal Finance Tracker

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44.4-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Node.js-Express-339933?logo=node.js" alt="Node.js">
  <img src="https://img.shields.io/badge/Database-SQLite-003B57?logo=sqlite" alt="SQLite">
  <img src="https://img.shields.io/badge/Auth-JWT-000000?logo=jsonwebtokens" alt="JWT">
</p>

**MyDompet** adalah aplikasi mobile pencatat keuangan pribadi fullstack yang membantu pengguna mengelola pemasukan dan pengeluaran secara efisien. Proyek ini dibangun sebagai tugas **Midterm Mobile Development - GDGoC Unsri**.

Aplikasi ini menggunakan **Clean Architecture** pada sisi mobile dengan dukungan **Dual Storage Mode** (bisa berjalan offline sepenuhnya menggunakan database SQLite lokal pada HP, atau online terhubung ke REST API server Express).

---

## 📋 Daftar Isi

- [Fitur Utama](#-fitur-utama)
- [Arsitektur & State Management](#-arsitektur--state-management)
- [Tech Stack](#-tech-stack)
- [Cara Menjalankan](#-cara-menjalankan)
- [Struktur Folder](#-struktur-folder)
- [API Documentation](#-api-documentation)
- [Dependencies](#-dependencies)

---

## ✨ Fitur Utama

### 1. Dual Mode (Online & Lokal/Offline)
*   **Mode Online (Server):** Data disimpan pada server Express & database SQLite laptop via koneksi internet/ngrok. Mendukung otentikasi JWT Bearer, token refresh otomatis via Dio interceptor, dan penanganan auto-login.
*   **Mode Lokal (Offline):** Aplikasi berjalan offline tanpa koneksi internet dengan menyimpan data akun pengguna, kategori, dan transaksi langsung ke database **SQLite lokal (`sqflite`)** pada HP Anda. Mode ini dapat dialihkan secara instan melalui switch di halaman Login.

### 2. Autentikasi Keamanan
*   Register & Login (Online via JWT / Offline via SQLite lokal).
*   Token disimpan aman di `Flutter Secure Storage`.
*   Auto-login cerdas ketika aplikasi pertama kali dibuka.
*   Pembersihan data sesi lokal saat Logout.

### 3. Pencatatan Transaksi Finansial
*   Pencatatan Pemasukan & Pengeluaran secara *real-time*.
*   Form input interaktif dilengkapi **Pembatas Ribuan Rupiah Otomatis** (titik ribuan saat mengetik).
*   Category picker berbasis jenis transaksi (makanan, transportasi, gaji, dll) dengan dukungan custom categories.
*   Filter transaksi berdasarkan tipe, kategori, dan rentang tanggal.
*   Fitur edit dan hapus transaksi.

### 4. Dashboard Visual & Ringkasan
*   Informasi total saldo, pemasukan, dan pengeluaran dengan desain *Summary Card* artistik berhias bulatan gradien premium.
*   Visualisasi **Pie Chart** interaktif untuk breakdown pengeluaran per kategori.
*   Grafik **Bar Chart** perbandingan pemasukan vs pengeluaran bulanan.
*   Daftar transaksi terbaru di beranda aplikasi.

### 5. UI/UX Premium & Performa
*   Dukungan penuh **Dark Mode** & **Light Mode** secara mulus.
*   Animasi transisi mikro (fade, slide, scale) untuk efek premium.
*   *Shimmer loading skeleton effect* saat memuat data.
*   Floating Action Button (FAB) melayang di kanan bawah agar tidak menghalangi bilah menu navigasi (*floating bottom navbar*).
*   Google Fonts (Inter) & Material Design 3.

---

## 🏗 Arsitektur & State Management

### Arsitektur Mobile (Clean Architecture)
Aplikasi memisahkan kode menjadi 3 layer utama yang mengikuti prinsip SOLID:
1.  **Presentation Layer:** Menampung widget UI, halaman, styling theme, dan BLoC/Cubit.
2.  **Domain Layer:** Berisi entitas bisnis murni (`User`, `Transaction`, `Category`) dan definisi kontrak *Repository* abstrak. Bebas dari library eksternal.
3.  **Data Layer:** Menampung implementasi data sumber (*remote datasource* dengan Dio dan *local datasource* dengan SQLite) serta model JSON parser.

```
┌──────────────────────────────────────────────────┐
│                Presentation Layer                │
│         Pages, Widgets, Cubits (BLoC)            │
├──────────────────────────────────────────────────┤
│                  Domain Layer                    │
│        Entities, Repositories (abstract)         │
├──────────────────────────────────────────────────┤
│                   Data Layer                     │
│     Models, Repositories (impl), Data Sources    │
├──────────────────────────────────────────────────┤
│                   External                       │
│     Dio (HTTP), Secure Storage, Local SQLite     │
└──────────────────────────────────────────────────┘
```

*   **State Management:** `flutter_bloc` (Cubit pattern) untuk logika bisnis yang efisien, teruji, dan minim re-render.
*   **Dependency Injection:** `get_it` sebagai service locator untuk wiring dependensi secara terpusat.

---

## 🛠 Tech Stack

| Komponen | Teknologi | Versi |
|----------|-----------|-------|
| Mobile Framework | Flutter | 3.44.4 |
| Bahasa Pemrograman | Dart | 3.12.2 |
| State Management | flutter_bloc | ^9.1.0 |
| Local Database (HP) | SQLite (`sqflite` & `path`) | ^2.4.1 |
| Local Secure Storage | flutter_secure_storage | ^9.2.4 |
| HTTP Client | Dio | ^5.8.0+1 |
| DI Container | get_it | ^8.0.3 |
| Backend Runtime | Node.js | 18+ |
| Backend Framework | Express | ^4.21.2 |
| Backend Database | SQLite (`better-sqlite3`) | ^11.9.1 |
| Authentication | JWT (`jsonwebtoken`) | ^9.0.2 |

---

## 🚀 Cara Menjalankan

### Prasyarat
*   Flutter SDK >= 3.44.4 dan Dart SDK >= 3.12.2.
*   Node.js >= 18.x dan npm >= 9.x.

### Langkah 1: Clone Repository
```bash
git clone https://github.com/frgtx8/Midterm-Mobile-Development-GDGoC-Unsri.git
cd Midterm-Mobile-Development-GDGoC-Unsri/mydompet
```

### Langkah 2: Jalankan Server Backend (Online Mode)
*Jika Anda hanya ingin menggunakan **Mode Lokal/Offline**, langkah ini bisa dilewati.*
```bash
cd backend
cp .env.example .env    # Konfigurasi JWT & Port
npm install             # Unduh dependensi backend
npm start               # Jalankan backend di port 3000
```
Server backend akan aktif di `http://localhost:3000`. Cek status: `http://localhost:3000/api/health`

### Langkah 3: Jalankan Aplikasi Flutter
1.  Kembali ke root project: `cd ..`
2.  Pasang dependensi Flutter: `flutter pub get`
3.  Konfigurasi `.env` Flutter untuk Base URL Server (misal diarahkan ke url ngrok Anda atau IP lokal komputer):
    ```env
    BASE_URL=https://pardon-craftsman-decorator.ngrok-free.dev/api
    ```
4.  Jalankan aplikasi di emulator atau HP Anda:
    ```bash
    flutter run
    ```
5.  **Beralih Mode:** Di halaman Login, pilih tab **Mode Lokal** jika ingin menjalankan offline tanpa server, atau pilih **Mode Online** untuk menghubungkan ke REST API server backend.

---

## 📁 Struktur Folder

```
mydompet/
├── backend/                          # Backend Node.js
│   ├── src/
│   │   ├── server.js                 # Entry point Express
│   │   ├── database.js               # SQLite setup & seeding
│   │   ├── middleware/auth.js        # JWT verify middleware
│   │   └── routes/
│   │       ├── auth.js               # API auth endpoints
│   │       ├── transactions.js       # API transaction CRUD
│   │       └── categories.js         # API category CRUD
│   ├── .env.example
│   └── package.json
│
├── lib/                              # Frontend Flutter Source
│   ├── main.dart                     # Main entrypoint
│   ├── app.dart                      # MaterialApp, routing, theme
│   ├── injection_container.dart      # GetIt dependencies wiring
│   │
│   ├── core/
│   │   ├── constants/constants.dart  # API URLs, storage keys
│   │   ├── errors/                   # Custom Exception & Failures
│   │   ├── network/
│   │   │   ├── dio_client.dart       # Dio client
│   │   │   ├── auth_interceptor.dart # JWT Auto-refresh interceptor
│   │   │   └── local_database_helper.dart # SQLite local DB helper
│   │   ├── theme/app_theme.dart      # Custom Light/Dark theme
│   │   └── utils/utils.dart          # Currency & date formatters
│   │
│   └── features/
│       ├── auth/                     # Fitur Autentikasi
│       │   ├── data/
│       │   │   ├── datasources/      # Remote & Local Auth Datasource
│       │   │   ├── models/           # UserModel
│       │   │   └── repositories/     # AuthRepositoryImpl
│       │   ├── domain/               # Entities & Abstract Repos
│       │   └── presentation/         # AuthCubit & LoginPage/RegisterPage
│       │
│       ├── transaction/              # Fitur Transaksi & Grafik
│       │   ├── data/
│       │   │   ├── datasources/      # Remote & Local Transaction Datasource
│       │   │   ├── models/           # TransactionModel, CategoryModel
│       │   │   └── repositories/     # TransactionRepositoryImpl
│       │   ├── domain/               # Entities & Abstract Repos
│       │   └── presentation/         # TransactionCubit & Dashboard/Form UI
│       │
│       └── settings/                 # Fitur Pengaturan
│           └── presentation/         # ThemeCubit & SettingsPage
│
├── .env                              # Environment variables
├── pubspec.yaml                      # Flutter dependencies
└── README.md                         # Dokumentasi proyek
```

---

## 📡 API Documentation

Base URL Backend: `http://localhost:3000/api`

### 1. Autentikasi

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/auth/register` | ❌ | Pendaftaran akun baru |
| POST | `/auth/login` | ❌ | Masuk akun, dapatkan access & refresh token |
| POST | `/auth/refresh` | ❌ | Memperbarui access token kadaluwarsa |
| POST | `/auth/logout` | ✅ | Keluar akun, invalidate refresh token |
| GET | `/auth/profile` | ✅ | Mengambil detail profil pengguna |

### 2. Transaksi Keuangan

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/transactions` | ✅ | Ambil daftar transaksi (filter & paginasi) |
| POST | `/transactions` | ✅ | Tambah transaksi baru |
| GET | `/transactions/summary` | ✅ | Ambil ringkasan pemasukan, pengeluaran & grafik |
| PUT | `/transactions/:id` | ✅ | Update data transaksi |
| DELETE | `/transactions/:id` | ✅ | Hapus transaksi |

---

## 📦 Dependencies Utama (Flutter)

*   **flutter_bloc (^9.1.0):** State management berbasis event/Cubit.
*   **dio (^5.8.0+1):** HTTP client untuk pemanggilan API dengan interceptor.
*   **sqflite (^2.4.1):** Database SQLite lokal ponsel.
*   **path (^1.9.0):** Helper manipulasi path database lokal.
*   **flutter_secure_storage (^9.2.4):** Penyimpanan enkripsi kredensial token JWT.
*   **shared_preferences (^2.5.3):** Penyimpanan preferensi tema & konfigurasi offline.
*   **fl_chart (^0.70.2):** Visualisasi grafik pie & bar chart yang interaktif.
*   **google_fonts (^6.2.1):** Integrasi font Inter yang elegan.
*   **flutter_dotenv (^5.2.1):** Load file `.env` untuk environment variables.

---

## 👤 Author

Dibuat dengan penuh ❤️ oleh **Fadhil Rahman** untuk **Midterm Mobile Development — GDGoC Unsri 2026**
*   **GitHub Repositori:** [frgtx8/Midterm-Mobile-Development-GDGoC-Unsri](https://github.com/frgtx8/Midterm-Mobile-Development-GDGoC-Unsri.git)