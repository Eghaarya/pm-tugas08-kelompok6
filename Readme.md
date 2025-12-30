# API Documentation

## Setup & Installation

### 1. Flutter Frontend
```bash
cd flutter_frontend
flutter pub get
flutter run
```

### 2. Laravel Backend
```bash
cd laravel_backend
composer install
ngrok http 8000
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

### 4. Get All Transactions
**GET** `/transactions` 🔒

Response:
```json
[
  {
    "id": 1,
    "date": "2024-12-29",
    "total": 150000,
    "items": [...]
  }
]
```

---

### 5. Create Transaction
**POST** `/transactions` 🔒

Request:
```json
{
  "date": "2024-12-29",
  "total": 150000,
  "items": [
    {
      "name": "Product A",
      "price": 50000,
      "quantity": 2
    }
  ]
}
```

Response:
```json
{
  "message": "Transaction saved",
  "data": {...}
}
```

---

### 6. Update Transaction
**PUT** `/transactions/{id}` 🔒

Request:
```json
{
  "date": "2024-12-29",
  "total": 200000,
  "items": [...]
}
```

Response:
```json
{
  "message": "Transaction updated",
  "data": {...}
}
```

---

### 7. Delete Transaction
**DELETE** `/transactions/{id}` 🔒

Response:
```json
{
  "message": "Transaction deleted"
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