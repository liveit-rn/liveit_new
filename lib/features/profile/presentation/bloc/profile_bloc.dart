import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileState()) {
    on<ProfileRequested>(_onProfileRequested);
    on<ProfileDisplayNameChanged>(_onDisplayNameChanged);
    on<ProfileAvatarChanged>(_onAvatarChanged);
    on<ProfileDeleteRequested>(_onDeleteRequested);
  }

  /// Get device timezone in IANA format (e.g., "Asia/Jakarta")
  String _getDeviceTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;

    // Map common UTC offsets to IANA timezone names
    // This is a simplified mapping for Indonesian timezones
    final hours = offset.inHours;
    switch (hours) {
      case 7:
        return 'Asia/Jakarta'; // WIB
      case 8:
        return 'Asia/Makassar'; // WITA
      case 9:
        return 'Asia/Jayapura'; // WIT
      default:
        // Fallback: use Etc/GMT format for other offsets
        if (hours >= 0) {
          return 'Etc/GMT-$hours';
        } else {
          return 'Etc/GMT+${hours.abs()}';
        }
    }
  }

  /// Silent timezone sync - runs in background without affecting UI state
  Future<void> _syncTimezoneIfNeeded(String? currentTimezone) async {
    if (currentTimezone != null && currentTimezone.isNotEmpty) return;

    try {
      final deviceTimezone = _getDeviceTimezone();
      await _repository.updateTimezone(deviceTimezone);
      debugPrint('[ProfileBloc] Silent timezone sync: $deviceTimezone');
    } catch (e) {
      // Silent fail - don't affect user experience
      debugPrint('[ProfileBloc] Timezone sync failed (silent): $e');
    }
  }

  Future<void> _onProfileRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _repository.fetchProfile();
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));

      // Silent timezone sync in background (fire-and-forget)
      _syncTimezoneIfNeeded(profile.timezone);
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDisplayNameChanged(
    ProfileDisplayNameChanged event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _repository.updateDisplayName(event.displayName);
      final updatedProfile = state.profile?.copyWith(
        displayName: event.displayName,
      );
      emit(state.copyWith(profile: updatedProfile));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAvatarChanged(
    ProfileAvatarChanged event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _repository.updateAvatar(event.avatarUrl);
      final updatedProfile = state.profile?.copyWith(
        avatarUrl: event.avatarUrl,
      );
      emit(state.copyWith(profile: updatedProfile));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    ProfileDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _repository.deleteAccount();
      // Navigate ke login atau tampilkan konfirmasi
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
