part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure, mutating }

class HomeState extends Equatable {
  const HomeState({
    required this.status,
    required this.uiState,
    this.successMessage,
    this.errorMessage,
  });

  factory HomeState.initial() => HomeState(
        status: HomeStatus.initial,
        uiState: HomeUiState.sample(),
      );

  final HomeStatus status;
  final HomeUiState uiState;
  final String? successMessage;
  final String? errorMessage;

  bool get hasFeedback => successMessage != null || errorMessage != null;

  static const Object _sentinel = Object();

  HomeState copyWith({
    HomeStatus? status,
    HomeUiState? uiState,
    Object? successMessage = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return HomeState(
      status: status ?? this.status,
      uiState: uiState ?? this.uiState,
      successMessage: successMessage == _sentinel
          ? this.successMessage
          : successMessage as String?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        uiState,
        successMessage,
        errorMessage,
      ];
}
