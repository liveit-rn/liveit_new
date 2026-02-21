import '../models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> fetchProfile();
  Future<ProfileModel> updateDisplayName(String displayName);
  Future<ProfileModel> uploadAvatar({
    required List<int> fileBytes,
    required String fileName,
  });
  Future<ProfileModel> updateAvatar(String profileImageId);
  Future<ProfileModel> removeAvatar();
  Future<ProfileModel> updateTimezone(String timezone);
  Future<void> deleteAccount();
}
