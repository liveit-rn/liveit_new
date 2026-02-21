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

  Map<String, dynamic> _extractPayload(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw ApiException.unknown(message: 'Format respons tidak valid');
    }

    final nestedData = responseData['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }

    return responseData;
  }

  Map<String, dynamic> _normalizeAvatarUrl(
    Map<String, dynamic> payload,
    String baseUrl,
  ) {
    final avatarUrl = payload['avatarUrl'];
    if (avatarUrl is! String || !avatarUrl.startsWith('/')) {
      return payload;
    }

    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return {...payload, 'avatarUrl': '$normalizedBaseUrl$avatarUrl'};
  }

  String _extractFileId(Map<String, dynamic> payload) {
    final fileId = payload['fileId'];
    if (fileId is String && fileId.isNotEmpty) {
      return fileId;
    }

    throw ApiException.unknown(
      message: 'Upload avatar gagal: fileId tidak valid',
    );
  }

  /// Get current user profile
  Future<ProfileModel> getProfile() async {
    try {
      final response = await _dioClient.get('/profiles/me');

      if (response.statusCode == 200 && response.data != null) {
        final payload = _normalizeAvatarUrl(
          _extractPayload(response.data),
          response.requestOptions.baseUrl,
        );
        return ProfileModel.fromJson(payload);
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
        data: {'name': displayName},
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = _normalizeAvatarUrl(
          _extractPayload(response.data),
          response.requestOptions.baseUrl,
        );
        return ProfileModel.fromJson(payload);
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

  /// Update profile avatar using profileImageId from upload endpoint
  Future<ProfileModel> updateAvatar(String profileImageId) async {
    try {
      final response = await _dioClient.put(
        '/profiles/me',
        data: {'profileImageId': profileImageId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = _normalizeAvatarUrl(
          _extractPayload(response.data),
          response.requestOptions.baseUrl,
        );
        return ProfileModel.fromJson(payload);
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

  /// Upload avatar file to backend, then persist profileImageId to profile
  Future<ProfileModel> uploadAndUpdateAvatar({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final uploadResponse = await _dioClient.post(
        '/profiles/upload/avatar',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (uploadResponse.statusCode != 201 &&
          uploadResponse.statusCode != 200) {
        throw ApiException.unknown(message: 'Gagal upload foto profil');
      }

      final uploadPayload = _extractPayload(uploadResponse.data);
      final fileId = _extractFileId(uploadPayload);
      return await updateAvatar(fileId);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException.unknown(
        message: 'Gagal upload foto profil: ${e.message}',
      );
    }
  }

  /// Remove profile avatar by setting profileImageId to null
  Future<ProfileModel> removeAvatar() async {
    try {
      final response = await _dioClient.put(
        '/profiles/me',
        data: {'profileImageId': null},
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = _normalizeAvatarUrl(
          _extractPayload(response.data),
          response.requestOptions.baseUrl,
        );
        return ProfileModel.fromJson(payload);
      }

      throw ApiException.unknown(message: 'Gagal menghapus foto profil');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException.unknown(
        message: 'Gagal menghapus foto profil: ${e.message}',
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
        final payload = _normalizeAvatarUrl(
          _extractPayload(response.data),
          response.requestOptions.baseUrl,
        );
        return ProfileModel.fromJson(payload);
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
