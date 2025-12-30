<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\TransactionController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {

    // ✅ CEK TOKEN / STATUS LOGIN
    Route::get('/me', function (Request $request) {
        return response()->json([
            'status' => 'authenticated',
            'user' => [
                'id'       => $request->user()->id,
                'username' => $request->user()->username,
            ]
        ]);
    });

    // 🔐 LOGOUT (HAPUS TOKEN)
    Route::post('/logout', function (Request $request) {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status'  => 'logged_out',
            'message' => 'Logout berhasil'
        ]);
    });

    // 📊 TRANSAKSI ROUTES
    Route::get('/transactions', [TransactionController::class, 'index']);
    Route::post('/transactions', [TransactionController::class, 'store']);
    Route::put('/transactions/{id}', [TransactionController::class, 'update']);
    Route::delete('/transactions/{id}', [TransactionController::class, 'destroy']);
});
