import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../domain/usecases/check_username_availability_usecase.dart';
import '../../domain/usecases/claim_username_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckUsernameAvailabilityUseCase checkUsernameAvailabilityUseCase;
  final ClaimUsernameUseCase claimUsernameUseCase;
  final AuthRepository authRepository;
  final Logger logger = Logger();

  AuthBloc({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.checkUsernameAvailabilityUseCase,
    required this.claimUsernameUseCase,
    required this.authRepository,
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

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final isAuthenticated = await authRepository.isAuthenticated();
      if (isAuthenticated) {
        final user = await authRepository.getCurrentUser();
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
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
