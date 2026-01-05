# API Documentation

## Setup & Installation

### 1. Flutter Frontend
```bash
cd flutter_frontend
flutter pub get
flutter run
```

### 2. Laravel Backend (API SANCTUM)
```bash
cd laravel_backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve
```

---

## contoh Base URL (ngrok)
```
http://https://macrocytic-izayah-unpummeled.ngrok-free.dev/api
```

## Authentication
Gunakan Bearer Token di header setiap request (kecuali login):
```
Authorization: Bearer {your-token}
```

---


## Endpoints

### 1. Login
**POST** `/login`

Request:
```json
{
  "username": "string",
  "password": "string"
}
```

Response:
```json
{
  "token": "1|abc...",
  "user": {...}
}
```

---

### 2. Check Token / User Info
**GET** `/me` 🔒

Response:
```json
{
  "status": "authenticated",
  "user": {
    "id": 1,
    "username": "johndoe"
  }
}
```

---

### 3. Logout
**POST** `/logout` 🔒

Response:
```json
{
  "status": "logged_out",
  "message": "Logout berhasil"
}
```

---

### 4. Backup Transaction
**POST** `/backup` 🔒

Request:
```json
{
  "transactions": [
    {
      "date": "2026-01-04",
      "total": 15000,
      "items": [
        {
          "product_id": 1,
          "name": "Kopi",
          "qty": 1,
          "price": 15000
        }
      ]
    }
  ]
}
```

Response:
```json
{
  "message": "Backup to database was successful",
}
```

---

## Status Codes
- **200** OK
- **201** Created
- **401** Unauthorized
- **404** Not Found
- **422** Validation Error

🔒 = Requires Authentication