import '../models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> fetchProfile();
  Future<void> updateDisplayName(String displayName);
  Future<void> updateAvatar(String avatarUrl);
  Future<void> updateTimezone(String timezone);
  Future<void> deleteAccount();
}
