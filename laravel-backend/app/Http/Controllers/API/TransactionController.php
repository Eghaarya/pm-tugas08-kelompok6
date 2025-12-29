<?php

namespace App\Http\Controllers\API;

use App\Models\Transaction;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class TransactionController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'date' => 'required|date',
            'total' => 'required|integer',
            'items' => 'required|array',
        ]);

        return Transaction::create([
            'date' => $request->date,
            'total' => $request->total,
            'items' => $request->items,
        ]);
    }
}
