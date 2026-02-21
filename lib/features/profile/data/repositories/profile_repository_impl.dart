import '../../domain/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Profile repository implementation with real API.
/// WHY: Implements profile repository contract with actual API calls.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({required ProfileRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<ProfileModel> fetchProfile() async {
    return await _remoteDataSource.getProfile();
  }

  @override
  Future<ProfileModel> updateDisplayName(String displayName) async {
    return await _remoteDataSource.updateDisplayName(displayName);
  }

  @override
  Future<ProfileModel> uploadAvatar({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    return await _remoteDataSource.uploadAndUpdateAvatar(
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }

  @override
  Future<ProfileModel> updateAvatar(String profileImageId) async {
    return await _remoteDataSource.updateAvatar(profileImageId);
  }

  @override
  Future<ProfileModel> removeAvatar() async {
    return await _remoteDataSource.removeAvatar();
  }

  @override
  Future<ProfileModel> updateTimezone(String timezone) async {
    return await _remoteDataSource.updateTimezone(timezone);
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteDataSource.deleteProfile();
  }
}
