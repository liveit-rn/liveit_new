import '../entities/auth_response.dart';
import '../entities/user.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Register a new user with email and password
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? name,
  });

  /// Login user with email and password
  Future<AuthResponse> login({required String email, required String password});

  /// Check if username is available
  Future<bool> checkUsernameAvailability(String username);

  /// Claim username for authenticated user
  Future<User> claimUsername(String username);

  /// Get current user profile
  Future<User> getCurrentUser();

  /// Logout current user
  Future<void> logout();

  /// Get stored access token
  Future<String?> getAccessToken();

  /// Store access token securely
  Future<void> storeAccessToken(String token);

  /// Remove stored access token
  Future<void> removeAccessToken();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
