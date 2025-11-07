import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class ClaimUsernameUseCase {
  final AuthRepository repository;

  ClaimUsernameUseCase(this.repository);

  Future<User> call(String username) async {
    // Username validation
    if (username.isEmpty) {
      throw Exception('Username is required');
    }

    if (username.length < 3) {
      throw Exception('Username must be at least 3 characters long');
    }

    if (username.length > 20) {
      throw Exception('Username must be no more than 20 characters long');
    }

    if (!_isValidUsername(username)) {
      throw Exception(
        'Username can only contain letters, numbers, and underscores',
      );
    }

    // Check availability
    final isAvailable = await repository.checkUsernameAvailability(username);
    if (!isAvailable) {
      throw Exception('Username is already taken');
    }

    return await repository.claimUsername(username);
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }
}
