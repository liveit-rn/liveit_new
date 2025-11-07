import 'package:equatable/equatable.dart';
import 'user.dart';

/// Authentication response containing user data and JWT token
class AuthResponse extends Equatable {
  final User user;
  final String accessToken;
  final int expiresIn;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.expiresIn,
  });

  @override
  List<Object> get props => [user, accessToken, expiresIn];
}
