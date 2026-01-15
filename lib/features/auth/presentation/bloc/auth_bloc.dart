import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../domain/usecases/check_username_availability_usecase.dart';
import '../../domain/usecases/claim_username_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckUsernameAvailabilityUseCase checkUsernameAvailabilityUseCase;
  final ClaimUsernameUseCase claimUsernameUseCase;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final Logger logger = Logger();

  AuthBloc({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.checkUsernameAvailabilityUseCase,
    required this.claimUsernameUseCase,
    required this.authRepository,
    required this.profileRepository,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<UsernameAvailabilityCheckRequested>(
      _onUsernameAvailabilityCheckRequested,
    );
    on<UsernameClaimRequested>(_onUsernameClaimRequested);
  }

  /// Get device timezone in IANA format
  String _getDeviceTimezone() {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    switch (hours) {
      case 7:
        return 'Asia/Jakarta';
      case 8:
        return 'Asia/Makassar';
      case 9:
        return 'Asia/Jayapura';
      default:
        return hours >= 0 ? 'Etc/GMT-$hours' : 'Etc/GMT+${hours.abs()}';
    }
  }

  /// Silent timezone sync - ensures profile has timezone before proceeding
  Future<void> _ensureTimezoneSync() async {
    try {
      final profile = await profileRepository.fetchProfile();
      if (profile.timezone == null || profile.timezone!.isEmpty) {
        final deviceTimezone = _getDeviceTimezone();
        await profileRepository.updateTimezone(deviceTimezone);
        debugPrint('[AuthBloc] Timezone synced: $deviceTimezone');
      }
    } catch (e) {
      // Silent fail - don't block auth flow
      debugPrint('[AuthBloc] Timezone sync failed (silent): $e');
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      logger.i('🔍 AuthCheck: Starting authentication check...');
      emit(AuthLoading());

      final isAuthenticated = await authRepository.isAuthenticated();
      logger.i('🔍 AuthCheck: isAuthenticated = $isAuthenticated');

      if (isAuthenticated) {
        logger.i('🔍 AuthCheck: Fetching current user from backend...');
        final user = await authRepository.getCurrentUser();
        logger.i('🔍 AuthCheck: User fetched successfully');
        logger.i('   - ID: ${user.id}');
        logger.i('   - Email: ${user.email}');
        logger.i('   - Username: ${user.username}');
        logger.i('   - Name: ${user.name}');
        logger.i('   - NeedsUsername: ${user.needsUsername}');

        // Ensure timezone is synced before proceeding
        await _ensureTimezoneSync();

        emit(AuthAuthenticated(user));
      } else {
        logger.w('🔍 AuthCheck: User not authenticated');
        emit(AuthUnauthenticated());
      }
    } catch (e, stackTrace) {
      logger.e(
        '🔍 AuthCheck: Error during auth check',
        error: e,
        stackTrace: stackTrace,
      );
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      logger.i('🔐 Register request started for email: ${event.email}');
      emit(AuthLoading());

      logger.d('📤 Calling register use case...');
      final authResponse = await registerUseCase.call(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      logger.i('✅ Register successful! User ID: ${authResponse.user.id}');
      logger.d('📋 User data: ${authResponse.user.toString()}');

      // Ensure timezone is synced before proceeding
      await _ensureTimezoneSync();

      emit(AuthAuthenticated(authResponse.user));
    } catch (e, stackTrace) {
      logger.e('❌ Register failed', error: e, stackTrace: stackTrace);
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      logger.i('🔐 Login request started for email: ${event.email}');
      emit(AuthLoading());

      logger.d('📤 Calling login use case...');
      final authResponse = await loginUseCase.call(
        email: event.email,
        password: event.password,
      );

      logger.i('✅ Login successful! User ID: ${authResponse.user.id}');
      logger.d('📋 User data: ${authResponse.user.toString()}');

      // Ensure timezone is synced before proceeding
      await _ensureTimezoneSync();

      emit(AuthAuthenticated(authResponse.user));
    } catch (e, stackTrace) {
      logger.e('❌ Login failed', error: e, stackTrace: stackTrace);
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      await logoutUseCase.call();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails, consider user unauthenticated
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onUsernameAvailabilityCheckRequested(
    UsernameAvailabilityCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(UsernameCheckLoading());

      final isAvailable = await checkUsernameAvailabilityUseCase.call(
        event.username,
      );

      if (isAvailable) {
        emit(UsernameAvailable(event.username));
      } else {
        emit(UsernameUnavailable(event.username));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onUsernameClaimRequested(
    UsernameClaimRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(UsernameClaimLoading());

      final user = await claimUsernameUseCase.call(event.username);

      emit(UsernameClaimSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
