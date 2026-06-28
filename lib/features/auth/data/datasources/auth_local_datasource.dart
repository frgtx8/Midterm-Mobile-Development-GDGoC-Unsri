import '../../../../core/network/local_database_helper.dart';
import '../models/user_model.dart';

class AuthLocalDataSource {
  final LocalDatabaseHelper dbHelper;

  AuthLocalDataSource({required this.dbHelper});

  /// Register a local user.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await dbHelper.database;

    // Check if email exists
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      throw Exception('Email sudah terdaftar secara lokal.');
    }

    final id = '${DateTime.now().microsecondsSinceEpoch}';
    final userMap = {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'created_at': DateTime.now().toIso8601String(),
    };

    await db.insert('users', userMap);

    // Seed default categories for this local user
    await dbHelper.seedDefaultCategories(db, id);

    return UserModel.fromJson(userMap);
  }

  /// Login a local user.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isEmpty) {
      throw Exception('Email atau password salah.');
    }

    return UserModel.fromJson(maps.first);
  }
}
