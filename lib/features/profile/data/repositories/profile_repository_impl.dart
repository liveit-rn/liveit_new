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
  Future<void> updateDisplayName(String displayName) async {
    await _remoteDataSource.updateDisplayName(displayName);
  }

  @override
  Future<void> updateAvatar(String avatarUrl) async {
    await _remoteDataSource.updateAvatar(avatarUrl);
  }

  @override
  Future<void> updateTimezone(String timezone) async {
    await _remoteDataSource.updateTimezone(timezone);
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteDataSource.deleteProfile();
  }
}
