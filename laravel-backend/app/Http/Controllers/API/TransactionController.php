<?php

namespace App\Http\Controllers\API;

use App\Models\Transaction;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class TransactionController extends Controller
{
    public function index()
    {
        return response()->json(
            Transaction::latest()->get()
        );
    }

    public function store(Request $request)
    {
        $request->validate([
            'date'  => 'required|date',
            'total' => 'required|integer',
            'items' => 'required|array',
        ]);

        $transaction = Transaction::create([
            'date'  => $request->date,
            'total' => $request->total,
            'items' => $request->items,
        ]);

        return response()->json([
            'message' => 'Transaction saved',
            'data'    => $transaction
        ], 201);
    }
}
