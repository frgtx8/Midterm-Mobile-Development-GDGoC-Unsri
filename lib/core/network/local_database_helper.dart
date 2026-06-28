import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database helper for local SQLite on phone.
class LocalDatabaseHelper {
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._init();
  static Database? _database;

  LocalDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mydompet_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, filePath);

    return await openDatabase(
      pathString,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL,
        is_default INTEGER NOT NULL
      )
    ''');

    // Create Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        category_name TEXT,
        category_icon TEXT,
        category_color TEXT,
        created_at TEXT
      )
    ''');
  }

  String _generateId() {
    final rand = Random();
    final time = DateTime.now().microsecondsSinceEpoch;
    return '$time-${rand.nextInt(100000)}';
  }

  /// Seed default categories for offline mode.
  Future<void> seedDefaultCategories(Database db, String userId) async {
    final defaults = [
      // Expense categories
      { 'id': _generateId(), 'name': 'Makanan & Minuman', 'icon': 'restaurant', 'color': '#FF6B6B', 'type': 'expense', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Transportasi', 'icon': 'directions_car', 'color': '#4ECDC4', 'type': 'expense', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Belanja', 'icon': 'shopping_bag', 'color': '#FFE66D', 'type': 'expense', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Hiburan', 'icon': 'movie', 'color': '#A8E6CF', 'type': 'expense', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Tagihan', 'icon': 'receipt_long', 'color': '#FF8B94', 'type': 'expense', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Kesehatan', 'icon': 'local_hospital', 'color': '#95E1D3', 'type': 'expense', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Pendidikan', 'icon': 'school', 'color': '#F38181', 'type': 'expense', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Lainnya', 'icon': 'more_horiz', 'color': '#AA96DA', 'type': 'expense', 'is_default': 1 },
      // Income categories
      { 'id': _generateId(), 'name': 'Gaji', 'icon': 'account_balance_wallet', 'color': '#4CAF50', 'type': 'income', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Freelance', 'icon': 'laptop', 'color': '#2196F3', 'type': 'income', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Investasi', 'icon': 'trending_up', 'color': '#FF9800', 'type': 'income', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Hadiah', 'icon': 'card_giftcard', 'color': '#E91E63', 'type': 'income', 'is_default': 1 },
      { 'id': _generateId(), 'name': 'Lainnya', 'icon': 'more_horiz', 'color': '#9C27B0', 'type': 'income', 'is_default': 1 },
    ];

    final batch = db.batch();
    for (final cat in defaults) {
      batch.insert('categories', cat);
    }
    await batch.commit(noResult: true);
  }
}
