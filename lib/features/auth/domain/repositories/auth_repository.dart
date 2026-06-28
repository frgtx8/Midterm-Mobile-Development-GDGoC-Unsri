import '../entities/user.dart';

/// Abstract repository contract for authentication operations.
abstract class AuthRepository {
  /// Register a new user. Returns [User] on success.
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });

  /// Login with email and password. Returns [User] on success.
  Future<User> login({
    required String email,
    required String password,
  });

  /// Logout current user and clear stored tokens.
  Future<void> logout();

  /// Get the current user profile.
  Future<User> getProfile();

  /// Update user profile.
  Future<User> updateProfile({required String name});

  /// Check if user is authenticated (has valid tokens).
  Future<bool> isAuthenticated();

  /// Get locally stored user data for auto-login.
  Future<User?> getCachedUser();
}
