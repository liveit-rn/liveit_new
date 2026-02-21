import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthResponse> call({
    required String email,
    required String password,
  }) async {
    // Basic email validation
    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }

    // Basic validation
    if (password.isEmpty) {
      throw Exception('Password is required');
    }

    return await repository.login(email: email, password: password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
