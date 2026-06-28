import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit managing authentication state.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  /// Check if user is already logged in (auto-login).
  Future<void> checkAuth() async {
    emit(AuthLoading());
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (isAuth) {
        final user = await authRepository.getCachedUser();
        if (user != null) {
          emit(Authenticated(user: user));
          return;
        }
      }
      emit(Unauthenticated());
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  /// Register a new user.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      emit(Authenticated(user: user));
    } on Failure catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(
        email: email,
        password: password,
      );
      emit(Authenticated(user: user));
    } on Failure catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Logout.
  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
    } catch (_) {
      // Always go to unauthenticated even if logout API fails
    }
    emit(Unauthenticated());
  }
}
