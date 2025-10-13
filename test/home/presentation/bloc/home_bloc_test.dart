import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveit_new/features/home/data/repositories/in_memory_home_repository.dart';
import 'package:liveit_new/features/home/presentation/bloc/home_bloc.dart';
import 'package:liveit_new/features/home/presentation/models/home_ui_state.dart';

void main() {
  group('HomeBloc', () {
    late HomeUiState sample;

    setUp(() {
      sample = HomeUiState.sample();
    });

    test('initial state uses sample snapshot', () {
      final HomeBloc bloc = HomeBloc(InMemoryHomeRepository(seed: sample));
      expect(bloc.state.status, HomeStatus.initial);
      expect(bloc.state.uiState.totalHabitCount, sample.totalHabitCount);
      bloc.close();
    });

    blocTest<HomeBloc, HomeState>(
      'emits loading then success snapshot when started',
      build: () => HomeBloc(InMemoryHomeRepository(seed: sample)),
      act: (HomeBloc bloc) => bloc.add(const HomeStarted()),
      wait: const Duration(milliseconds: 250),
      expect: () => <dynamic>[
        isA<HomeState>()
            .having((HomeState s) => s.status, 'status', HomeStatus.loading)
            .having((HomeState s) => s.errorMessage, 'error', isNull),
        isA<HomeState>()
            .having((HomeState s) => s.status, 'status', HomeStatus.success)
            .having(
              (HomeState s) => s.uiState.totalHabitCount,
              'total habits',
              sample.totalHabitCount,
            )
            .having((HomeState s) => s.errorMessage, 'error', isNull),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'moves habit to completed and raises success feedback on check-in',
      build: () => HomeBloc(InMemoryHomeRepository(seed: sample)),
      seed: () => HomeState(status: HomeStatus.success, uiState: sample),
      act: (HomeBloc bloc) => bloc.add(const HabitCheckInRequested('habit-scripture')),
      wait: const Duration(milliseconds: 250),
      expect: () => <dynamic>[
        isA<HomeState>().having((HomeState s) => s.status, 'status', HomeStatus.mutating),
        isA<HomeState>()
            .having((HomeState s) => s.status, 'status', HomeStatus.success)
            .having(
              (HomeState s) => s.uiState.completedHabits.first.id,
              'first completed id',
              'habit-scripture',
            )
            .having(
              (HomeState s) => s.successMessage,
              'success message',
              'Mantap! Baca Mazmur 23 selesai. +10 Zoe Points',
            ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'adds new habit to pending list when creating from devotional',
      build: () => HomeBloc(InMemoryHomeRepository(seed: sample)),
      seed: () => HomeState(status: HomeStatus.success, uiState: sample),
      act: (HomeBloc bloc) => bloc.add(const DevotionalHabitCreateRequested()),
      wait: const Duration(milliseconds: 250),
      expect: () => <dynamic>[
        isA<HomeState>().having((HomeState s) => s.status, 'status', HomeStatus.mutating),
        isA<HomeState>()
            .having((HomeState s) => s.status, 'status', HomeStatus.success)
            .having(
              (HomeState s) => s.uiState.pendingHabits.first.name,
              'new habit title',
              sample.devotional?.title,
            )
            .having(
              (HomeState s) => s.successMessage,
              'success message',
              'Habit baru dari renungan siap dikerjakan.',
            ),
      ],
    );
  });
}
