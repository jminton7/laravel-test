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

    public function store(Request $request)
    {
        // Logic to store a new book
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'author' => 'required|string|max:255',
            'published_at' => 'required|date',
        ]);

        // Assuming you have a Book model
        // Book::create($validated);

        return redirect()->route('books.index')->with('success', 'Book created successfully.');
    }
}
