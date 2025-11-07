import '../repositories/auth_repository.dart';

class CheckUsernameAvailabilityUseCase {
  final AuthRepository repository;

  CheckUsernameAvailabilityUseCase(this.repository);

  Future<bool> call(String username) async {
    if (username.isEmpty) return false;
    if (username.length < 3) return false;
    if (username.length > 20) return false;
    if (!_isValidUsername(username)) return false;

    return await repository.checkUsernameAvailability(username);
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }
}
