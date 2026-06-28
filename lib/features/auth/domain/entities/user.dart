import 'package:equatable/equatable.dart';

/// User entity in the domain layer.
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, email, createdAt];
}
