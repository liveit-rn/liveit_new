import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AuthResponse> call({
    required String email,
    required String password,
    String? name,
  }) async {
    // Basic email validation
    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }

    // Basic password validation
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }

    return await repository.register(
      email: email,
      password: password,
      name: name,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
