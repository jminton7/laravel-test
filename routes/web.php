<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;
use App\Http\Controllers\BookController;
use App\Http\Controllers\UserController;

Route::get('/', function () {
    return Inertia::render('welcome');
})->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', function () {
        return Inertia::render('dashboard');
    })->name('dashboard');
    Route::get('/books', [BookController::class, 'index'])->name('books.index');
    Route::get('/users', [UserController::class, 'index'])->name('users.index');
    Route::post('/books', [BookController::class, 'store'])->name('books.store');
    Route::post('/users', [UserController::class, 'store'])->name('users.store');
});

require __DIR__.'/settings.php';
require __DIR__.'/auth.php';
