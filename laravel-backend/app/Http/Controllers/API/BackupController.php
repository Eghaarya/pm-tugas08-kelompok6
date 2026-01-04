<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

class BackupController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'transactions' => 'required|array',
        ]);

        foreach ($validated['transactions'] as $trx) {

            $date = $trx['date']
                ?? $trx['transaction_date']
                ?? $trx['created_at']
                ?? now()->toDateString();

            Transaction::create([
                'date'  => substr($date, 0, 10), // YYYY-MM-DD
                'total' => $trx['total'] ?? $trx['total_price'] ?? 0,
                'items' => $trx['items'] ?? [],
            ]);
        }


        return response()->json([
            'message' => 'Backup to database was successful'
        ], 200);
    }
}
