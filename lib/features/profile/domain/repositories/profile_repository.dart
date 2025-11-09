import '../models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> fetchProfile();
  Future<void> updateDisplayName(String displayName);
  Future<void> updateAvatar(String avatarUrl);
  Future<void> deleteAccount();
}
