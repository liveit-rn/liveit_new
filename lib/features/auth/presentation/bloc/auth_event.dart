import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String? name;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {}

class UsernameAvailabilityCheckRequested extends AuthEvent {
  final String username;

  const UsernameAvailabilityCheckRequested(this.username);

  @override
  List<Object> get props => [username];
}

class UsernameClaimRequested extends AuthEvent {
  final String username;

  const UsernameClaimRequested(this.username);

  @override
  List<Object> get props => [username];
}
