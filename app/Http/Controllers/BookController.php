<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Inertia\Inertia;

class BookController extends Controller
{
    public function index()
    {
        // Logic to retrieve and display books
        return Inertia::render('Books/index', []);
    }
}
