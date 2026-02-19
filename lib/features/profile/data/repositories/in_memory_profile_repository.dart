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
  Future<void> updateDisplayName(String displayName) async {
    await Future.delayed(const Duration(milliseconds: 220));
    _profile = _profile.copyWith(displayName: displayName);
  }

  @override
  Future<void> updateAvatar(String avatarUrl) async {
    await Future.delayed(const Duration(milliseconds: 220));
    _profile = _profile.copyWith(avatarUrl: avatarUrl);
  }

  @override
  Future<void> updateTimezone(String timezone) async {
    await Future.delayed(const Duration(milliseconds: 220));
    _profile = _profile.copyWith(timezone: timezone);
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 220));
    // Simulasi hapus akun
  }
}
