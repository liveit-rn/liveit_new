import 'package:flutter_test/flutter_test.dart';
import 'package:liveit_new/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should handle null needsUsername in JSON response', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'username': null,
        'name': null,
        'needsUsername': null, // This should be handled gracefully
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-01T00:00:00.000Z',
      };

      // Act & Assert - Should not throw
      final userModel = UserModel.fromJson(json);

      // Verify needsUsername defaults to true when null
      expect(userModel.needsUsername, true);
    });

    test('should preserve needsUsername when provided in JSON response', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'username': 'testuser',
        'name': 'Test User',
        'needsUsername': false,
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-01T00:00:00.000Z',
      };

      // Act
      final userModel = UserModel.fromJson(json);

      // Assert
      expect(userModel.needsUsername, false);
    });

    test('should handle true needsUsername correctly', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'username': null,
        'name': null,
        'needsUsername': true,
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-01T00:00:00.000Z',
      };

      // Act
      final userModel = UserModel.fromJson(json);

      // Assert
      expect(userModel.needsUsername, true);
    });
  });
}
