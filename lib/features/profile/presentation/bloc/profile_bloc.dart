import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> _onProfileRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _repository.fetchProfile();
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
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
