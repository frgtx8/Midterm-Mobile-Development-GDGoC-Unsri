# 💰 MyDompet — Personal Finance Tracker

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44.4-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Node.js-Express-339933?logo=node.js" alt="Node.js">
  <img src="https://img.shields.io/badge/Database-SQLite-003B57?logo=sqlite" alt="SQLite">
  <img src="https://img.shields.io/badge/Auth-JWT-000000?logo=jsonwebtokens" alt="JWT">
</p>

**MyDompet** adalah aplikasi mobile pencatat keuangan pribadi yang membantu pengguna mengelola pemasukan dan pengeluaran secara efisien. Dibangun dengan **Flutter** (frontend) dan **Node.js + Express** (backend) menggunakan **Clean Architecture**.

---

## 📋 Daftar Isi

- [Fitur](#-fitur)
- [Arsitektur](#-arsitektur)
- [Tech Stack](#-tech-stack)
- [Cara Menjalankan](#-cara-menjalankan)
- [Struktur Folder](#-struktur-folder)
- [API Documentation](#-api-documentation)
- [Dependencies](#-dependencies)

---

## ✨ Fitur

### Autentikasi
- ✅ Register & Login dengan email dan password
- ✅ JWT Access Token + Refresh Token
- ✅ Auto-login jika token masih valid
- ✅ Token auto-refresh via Dio Interceptor
- ✅ Logout dengan pembersihan data lokal
- ✅ Token disimpan aman di Flutter Secure Storage

### Pencatatan Keuangan
- ✅ Tambah transaksi (pemasukan / pengeluaran)
- ✅ Edit dan hapus transaksi
- ✅ Kategori transaksi (default + kustom)
- ✅ Filter transaksi berdasarkan tipe, kategori, dan tanggal
- ✅ Deskripsi dan tanggal untuk setiap transaksi

### Dashboard & Analisis
- ✅ Ringkasan saldo, total pemasukan, total pengeluaran
- ✅ Pie chart pengeluaran per kategori
- ✅ Bar chart tren pemasukan vs pengeluaran bulanan
- ✅ Transaksi terbaru di halaman beranda

### UI/UX
- ✅ Dark Mode & Light Mode
- ✅ Shimmer loading effect
- ✅ Micro-animations (fade, slide, scale, elastic)
- ✅ Custom snackbar informatif (sukses & error)
- ✅ Pull-to-refresh
- ✅ Responsive design
- ✅ Google Fonts (Inter)
- ✅ Material Design 3

### Error Handling
- ✅ Error handling matang di setiap layer
- ✅ Custom error page dengan tombol retry
- ✅ Snackbar informatif untuk setiap error
- ✅ Loading indicator di setiap operasi

---

## 🏗 Arsitektur

Aplikasi menggunakan **Clean Architecture** dengan pemisahan layer yang jelas:

```
┌──────────────────────────────────────────────────┐
│                Presentation Layer                │
│         Pages, Widgets, Cubits (BLoC)            │
├──────────────────────────────────────────────────┤
│                  Domain Layer                    │
│        Entities, Repositories (abstract),        │
│                  Use Cases                       │
├──────────────────────────────────────────────────┤
│                   Data Layer                     │
│     Models, Repositories (impl), Data Sources    │
├──────────────────────────────────────────────────┤
│                   External                       │
│       Dio (HTTP), Secure Storage, APIs           │
└──────────────────────────────────────────────────┘
```

### Diagram Komunikasi

```
Flutter App                          Backend (Express)
┌──────────┐    HTTP/REST API     ┌──────────────────┐
│  Cubit   │ ──── Dio ─────────► │  Express Routes  │
│ (State)  │ ◄── JSON ────────── │  (Controllers)   │
├──────────┤                     ├──────────────────┤
│Repository│     JWT Bearer      │  Auth Middleware  │
│  (impl)  │ ──── Token ───────► │  (JWT Verify)    │
├──────────┤                     ├──────────────────┤
│DataSource│                     │  SQLite Database  │
└──────────┘                     └──────────────────┘
```

**State Management**: `flutter_bloc` (Cubit pattern) — efisien dan minim re-render.

**Dependency Injection**: `get_it` — service locator untuk wiring semua dependency.

---

## 🛠 Tech Stack

| Layer | Teknologi | Versi |
|-------|-----------|-------|
| Mobile Framework | Flutter | 3.44.4 |
| Programming Language | Dart | 3.12.2 |
| State Management | flutter_bloc | ^9.1.0 |
| HTTP Client | Dio | ^5.8.0+1 |
| DI Container | get_it | ^8.0.3 |
| Secure Storage | flutter_secure_storage | ^9.2.4 |
| Backend Runtime | Node.js | 18+ |
| Backend Framework | Express | ^4.21.2 |
| Database | SQLite (better-sqlite3) | ^11.9.1 |
| Authentication | JWT (jsonwebtoken) | ^9.0.2 |
| Password Hashing | bcryptjs | ^3.0.2 |
| Charts | fl_chart | ^0.70.2 |
| Typography | Google Fonts (Inter) | ^6.2.1 |

---

## 🚀 Cara Menjalankan

### Prasyarat

- **Flutter SDK** >= 3.44.4
- **Dart** >= 3.12.2
- **Node.js** >= 18.x
- **npm** >= 9.x
- Android Emulator / iOS Simulator / Physical Device

### 1. Clone Repository

```bash
git clone https://github.com/[username]/Midterm-Mobile-Development-GDGoC-Unsri.git
cd Midterm-Mobile-Development-GDGoC-Unsri/mydompet
```

### 2. Jalankan Backend

```bash
cd backend
cp .env.example .env    # Salin config (edit jika perlu)
npm install             # Install dependencies
npm start               # Jalankan server di port 3000
```

Backend akan berjalan di `http://localhost:3000`. Cek health: `http://localhost:3000/api/health`

### 3. Jalankan Flutter App

```bash
cd ..                   # Kembali ke root project mydompet
flutter pub get         # Install dependencies
flutter run             # Jalankan di emulator/device
```

> **Note**: Jika menggunakan Android Emulator, `BASE_URL` di `.env` sudah dikonfigurasi menggunakan `10.0.2.2:3000` (alias localhost untuk emulator Android). Untuk device fisik, ganti dengan IP lokal komputer Anda.

### 4. Konfigurasi Environment

Flutter `.env`:
```
BASE_URL=http://10.0.2.2:3000/api
```

Backend `.env`:
```
PORT=3000
JWT_SECRET=your_secret_key
JWT_REFRESH_SECRET=your_refresh_secret_key
JWT_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d
```

---

## 📁 Struktur Folder

```
mydompet/
├── backend/                          # Backend Node.js
│   ├── src/
│   │   ├── server.js                 # Entry point Express
│   │   ├── database.js               # SQLite setup & seed
│   │   ├── middleware/
│   │   │   └── auth.js               # JWT verification middleware
│   │   └── routes/
│   │       ├── auth.js               # Auth endpoints
│   │       ├── transactions.js       # Transaction CRUD + summary
│   │       └── categories.js         # Category CRUD
│   ├── .env.example
│   └── package.json
│
├── lib/                              # Flutter source code
│   ├── main.dart                     # Entry point
│   ├── app.dart                      # MaterialApp, routing, theme
│   ├── injection_container.dart      # GetIt DI setup
│   │
│   ├── core/
│   │   ├── constants/constants.dart  # API URLs, storage keys
│   │   ├── errors/
│   │   │   ├── failures.dart         # Domain failure classes
│   │   │   └── exceptions.dart       # Data layer exceptions
│   │   ├── network/
│   │   │   ├── dio_client.dart       # Dio configuration
│   │   │   └── auth_interceptor.dart # JWT auto-refresh interceptor
│   │   ├── theme/app_theme.dart      # Light & Dark theme
│   │   └── utils/utils.dart          # Formatters & validators
│   │
│   └── features/
│       ├── auth/
│       │   ├── data/
│       │   │   ├── datasources/      # AuthRemoteDataSource
│       │   │   ├── models/           # UserModel
│       │   │   └── repositories/     # AuthRepositoryImpl
│       │   ├── domain/
│       │   │   ├── entities/         # User
│       │   │   └── repositories/     # AuthRepository (abstract)
│       │   └── presentation/
│       │       ├── cubit/            # AuthCubit, AuthState
│       │       └── pages/            # LoginPage, RegisterPage
│       │
│       ├── transaction/
│       │   ├── data/
│       │   │   ├── datasources/      # TransactionRemoteDataSource
│       │   │   ├── models/           # TransactionModel, CategoryModel
│       │   │   └── repositories/     # TransactionRepositoryImpl
│       │   ├── domain/
│       │   │   ├── entities/         # Transaction, Category, Summary
│       │   │   └── repositories/     # TransactionRepository (abstract)
│       │   └── presentation/
│       │       ├── cubit/            # TransactionCubit, FormCubit
│       │       ├── pages/            # HomePage, AddTransactionPage
│       │       └── widgets/          # SummaryCard, TransactionCard, Charts
│       │
│       └── settings/
│           └── presentation/
│               ├── cubit/            # ThemeCubit
│               └── pages/            # SettingsPage
│
├── .env                              # Environment config
├── .gitignore
├── pubspec.yaml
└── README.md
```

---

## 📡 API Documentation

Base URL: `http://localhost:3000/api`

### Health Check

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Server health check |

### Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/register` | ❌ | Register user baru |
| POST | `/auth/login` | ❌ | Login, dapatkan access + refresh token |
| POST | `/auth/refresh` | ❌ | Refresh access token |
| POST | `/auth/logout` | ✅ | Logout, invalidate refresh token |
| GET | `/auth/profile` | ✅ | Get profil user |
| PUT | `/auth/profile` | ✅ | Update profil user |

#### POST `/auth/register`
```json
// Request
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "123456"
}

// Response 201
{
  "success": true,
  "message": "Registration successful.",
  "data": {
    "user": { "id": "uuid", "name": "John Doe", "email": "john@example.com" },
    "accessToken": "eyJhb...",
    "refreshToken": "eyJhb..."
  }
}
```

#### POST `/auth/login`
```json
// Request
{
  "email": "john@example.com",
  "password": "123456"
}

// Response 200
{
  "success": true,
  "data": {
    "user": { "id": "uuid", "name": "John Doe", "email": "john@example.com" },
    "accessToken": "eyJhb...",
    "refreshToken": "eyJhb..."
  }
}
```

#### POST `/auth/refresh`
```json
// Request
{ "refreshToken": "eyJhb..." }

// Response 200
{
  "success": true,
  "data": { "accessToken": "new_eyJhb..." }
}
```

### Transactions

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/transactions` | ✅ | List transaksi (dengan filter & paginasi) |
| POST | `/transactions` | ✅ | Buat transaksi baru |
| GET | `/transactions/summary` | ✅ | Ringkasan keuangan + chart data |
| GET | `/transactions/:id` | ✅ | Detail transaksi |
| PUT | `/transactions/:id` | ✅ | Update transaksi |
| DELETE | `/transactions/:id` | ✅ | Hapus transaksi |

#### GET `/transactions` — Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `type` | string | `income` / `expense` |
| `category_id` | string | Filter by category UUID |
| `start_date` | string | ISO 8601 date |
| `end_date` | string | ISO 8601 date |
| `page` | int | Page number (default: 1) |
| `limit` | int | Items per page (default: 20) |
| `sort` | string | `date`, `amount`, `created_at` |
| `order` | string | `asc` / `desc` |

#### POST `/transactions`
```json
// Request
{
  "type": "expense",
  "amount": 50000,
  "description": "Makan siang",
  "category_id": "uuid",
  "date": "2024-06-27T12:00:00.000Z"
}
```

#### GET `/transactions/summary` — Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `month` | string | Month number (01-12) |
| `year` | string | Year (e.g., 2024) |

Response includes: `totalIncome`, `totalExpense`, `balance`, `expenseByCategory`, `incomeByCategory`, `monthlyTrend`.

### Categories

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/categories` | ✅ | List kategori (filter: `?type=income/expense`) |
| POST | `/categories` | ✅ | Buat kategori kustom |
| PUT | `/categories/:id` | ✅ | Update kategori |
| DELETE | `/categories/:id` | ✅ | Hapus kategori (non-default) |

---

## 📦 Dependencies

### Flutter (pubspec.yaml)

| Package | Versi | Kegunaan |
|---------|-------|----------|
| flutter_bloc | ^9.1.0 | State management (Cubit) |
| dio | ^5.8.0+1 | HTTP client |
| get_it | ^8.0.3 | Dependency injection |
| flutter_secure_storage | ^9.2.4 | Penyimpanan token aman |
| shared_preferences | ^2.5.3 | Penyimpanan preferensi (tema) |
| flutter_dotenv | ^5.2.1 | Environment variables |
| equatable | ^2.0.7 | Value equality untuk state |
| shimmer | ^3.0.0 | Loading skeleton effect |
| fl_chart | ^0.70.2 | Pie chart & bar chart |
| google_fonts | ^6.2.1 | Typography (Inter) |
| intl | ^0.20.2 | Formatting mata uang & tanggal |
| connectivity_plus | ^6.1.4 | Monitoring koneksi jaringan |

### Backend (package.json)

| Package | Versi | Kegunaan |
|---------|-------|----------|
| express | ^4.21.2 | Web framework |
| better-sqlite3 | ^11.9.1 | SQLite database |
| bcryptjs | ^3.0.2 | Password hashing |
| jsonwebtoken | ^9.0.2 | JWT token generation & verification |
| cors | ^2.8.5 | Cross-Origin Resource Sharing |
| helmet | ^8.1.0 | Security headers |
| morgan | ^1.10.0 | HTTP request logging |
| dotenv | ^16.5.0 | Environment variables |
| express-validator | ^7.2.1 | Input validation |
| uuid | ^11.1.0 | UUID generation |

---

## 👤 Author

Dibuat untuk **Midterm Mobile Development — GDGoC Unsri**

---
