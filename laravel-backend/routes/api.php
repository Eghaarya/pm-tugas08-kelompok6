<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\BackupController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {

    // 🔍 CEK LOGIN
    Route::get('/me', function (Request $request) {
        return response()->json([
            'status' => 'authenticated',
            'user' => [
                'id'       => $request->user()->id,
                'username' => $request->user()->username,
            ]
        ]);
    });

    // 🔐 LOGOUT
    Route::post('/logout', function (Request $request) {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status'  => 'logged_out',
            'message' => 'Logout berhasil'
        ]);
    });

    // ☁️ BACKUP KE DATABASE
    Route::post('/backup', [BackupController::class, 'store']);
});
