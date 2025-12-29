<?php

namespace App\Http\Controllers\API;

use App\Models\Transaction;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class TransactionController extends Controller
{

    // Get all transactions
    public function index()
    {
        return response()->json(Transaction::latest()->get());
    }

    // Create new transaction
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

    // Update existing transaction
    public function update(Request $request, $id)
    {
        $transaction = Transaction::find($id);
        if (!$transaction) {
            return response()->json(['message' => 'Transaction not found'], 404);
        }

        $transaction->update($request->only(['date', 'total', 'items']));

        return response()->json([
            'message' => 'Transaction updated',
            'data'    => $transaction
        ]);
    }

    // Delete transaction
    public function destroy($id)
    {
        $transaction = Transaction::find($id);
        if (!$transaction) {
            return response()->json(['message' => 'Transaction not found'], 404);
        }

        $transaction->delete();

        return response()->json([
            'message' => 'Transaction deleted'
        ]);
    }
}
