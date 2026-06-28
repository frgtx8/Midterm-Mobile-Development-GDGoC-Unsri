import 'package:equatable/equatable.dart';

/// Base failure class for domain layer error handling.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server-side failures (API errors).
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Network failures (no internet).
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection. Please check your network.'});
}

/// Authentication failures.
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

/// Cache / local storage failures.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Failed to access local storage.'});
}

/// Validation failures.
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Generic unexpected failure.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'An unexpected error occurred.'});
}
