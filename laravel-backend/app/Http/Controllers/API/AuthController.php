<?php

namespace App\Http\Controllers\API;

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required',
            'password' => 'required',
        ]);

        $user = User::where('username', $request->username)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Username atau password salah'
            ], 401);
        }

        $tokenResult = $user->createToken('flutter-token');
        $plainToken = $tokenResult->plainTextToken;

        $tokenModel = PersonalAccessToken::findToken($plainToken);
        if (config('sanctum.expiration')) {
            $tokenModel->expires_at = now()->addMinutes(config('sanctum.expiration'));
            $tokenModel->save();
        }

        return response()->json([
            'token' => $plainToken,
            'user' => $user
        ]);
    }
}
