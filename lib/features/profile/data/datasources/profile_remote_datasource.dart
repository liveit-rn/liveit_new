import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/profile_model.dart';

/// Profile API remote data source.
/// WHY: Handles all profile-related API calls.
class ProfileRemoteDataSource {
  final DioClient _dioClient;

  ProfileRemoteDataSource({required DioClient dioClient})
    : _dioClient = dioClient;

  /// Get current user profile
  Future<ProfileModel> getProfile() async {
    try {
      final response = await _dioClient.get('/profiles/me');

      if (response.statusCode == 200 && response.data != null) {
        return ProfileModel.fromJson(response.data['data']);
      }

      throw ApiException.unknown(message: 'Gagal mengambil data profil');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException.unknown(
        message: 'Gagal mengambil data profil: ${e.message}',
      );
    }
  }

  /// Update profile display name
  Future<ProfileModel> updateDisplayName(String displayName) async {
    try {
      final response = await _dioClient.put(
        '/profiles/me',
        data: {'displayName': displayName},
      );

      if (response.statusCode == 200 && response.data != null) {
        return ProfileModel.fromJson(response.data['data']);
      }

      throw ApiException.unknown(message: 'Gagal mengupdate nama');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException.unknown(
        message: 'Gagal mengupdate nama: ${e.message}',
      );
    }
  }

  /// Update profile avatar
  Future<ProfileModel> updateAvatar(String avatarUrl) async {
    try {
      final response = await _dioClient.put(
        '/profiles/me',
        data: {'avatarUrl': avatarUrl},
      );

      if (response.statusCode == 200 && response.data != null) {
        return ProfileModel.fromJson(response.data['data']);
      }

      throw ApiException.unknown(message: 'Gagal mengupdate foto profil');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException.unknown(
        message: 'Gagal mengupdate foto profil: ${e.message}',
      );
    }
  }

  /// Update profile timezone (silent sync)
  Future<ProfileModel> updateTimezone(String timezone) async {
    try {
      final response = await _dioClient.put(
        '/profiles/me',
        data: {'timezone': timezone},
      );

      if (response.statusCode == 200 && response.data != null) {
        return ProfileModel.fromJson(response.data['data']);
      }

      throw ApiException.unknown(message: 'Gagal mengupdate timezone');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException.unknown(
        message: 'Gagal mengupdate timezone: ${e.message}',
      );
    }
  }

  /// Delete profile (soft delete)
  Future<void> deleteProfile() async {
    try {
      final response = await _dioClient.delete('/profiles/me');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException.unknown(message: 'Gagal menghapus profil');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException.unknown(
        message: 'Gagal menghapus profil: ${e.message}',
      );
    }
  }
}
