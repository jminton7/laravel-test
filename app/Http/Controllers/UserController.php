<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\User; // Assuming you want to use the User model for demonstration

class UserController extends Controller
{
    public function index()
    {
        return User::query()->get();
    }

    public function store(Request $request)
    {
        User::create([
            'name' => "ghello",
            'email' =>"ghello",
            'password' => "ghello",
        ]);

        return response()->json([
            'message' => 'User created successfully.',
        ], 201);
    }
}
