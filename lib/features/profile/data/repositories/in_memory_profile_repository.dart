import 'dart:async';
import '../../domain/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

class InMemoryProfileRepository implements ProfileRepository {
  ProfileModel _profile = ProfileModel(
    id: '1',
    username: 'pip_user',
    email: 'pip@example.com',
    displayName: 'Pip Pengguna',
    avatarUrl: null,
    totalZoePoints: 480,
    currentLevel: 3,
    joinedAt: DateTime(2024, 1, 15),
  );

  @override
  Future<ProfileModel> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 220));
    return _profile;
  }

  @override
  Future<ProfileModel> updateDisplayName(String displayName) async {
    await Future.delayed(const Duration(milliseconds: 220));
    _profile = _profile.copyWith(displayName: displayName);
    return _profile;
  }

  @override
  Future<ProfileModel> uploadAvatar({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 220));
    _profile = _profile.copyWith(
      profileImageId: 'mock-file-id',
      avatarUrl: 'https://example.com/avatar/$fileName',
    );
    return _profile;
  }

  @override
  Future<ProfileModel> updateAvatar(String profileImageId) async {
    await Future.delayed(const Duration(milliseconds: 220));
    _profile = _profile.copyWith(profileImageId: profileImageId);
    return _profile;
  }

  @override
  Future<ProfileModel> removeAvatar() async {
    await Future.delayed(const Duration(milliseconds: 220));
    _profile = _profile.copyWith(profileImageId: null, avatarUrl: null);
    return _profile;
  }

  @override
  Future<ProfileModel> updateTimezone(String timezone) async {
    await Future.delayed(const Duration(milliseconds: 220));
    _profile = _profile.copyWith(timezone: timezone);
    return _profile;
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 220));
    // Simulasi hapus akun
  }
}
