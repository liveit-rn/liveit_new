import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class UsernameCheckLoading extends AuthState {}

class UsernameAvailable extends AuthState {
  final String username;

  const UsernameAvailable(this.username);

  @override
  List<Object> get props => [username];
}

class UsernameUnavailable extends AuthState {
  final String username;

  const UsernameUnavailable(this.username);

  @override
  List<Object> get props => [username];
}

class UsernameClaimLoading extends AuthState {}

class UsernameClaimSuccess extends AuthState {
  final User user;

  const UsernameClaimSuccess(this.user);

  @override
  List<Object> get props => [user];
}
