import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liveit_new/features/home/data/repositories/in_memory_home_repository.dart';
import 'package:liveit_new/features/home/presentation/bloc/home_bloc.dart';
import 'package:liveit_new/features/home/presentation/models/home_ui_state.dart';
import 'package:liveit_new/features/home/presentation/widget/daily_summary_card.dart';
import 'package:liveit_new/features/home/presentation/widget/devotional_card.dart';
import 'package:liveit_new/features/home/presentation/widget/empty_state_card.dart';
import 'package:liveit_new/features/home/presentation/widget/gamification_highlight_card.dart';
import 'package:liveit_new/features/home/presentation/widget/habit_groups_section.dart';
import 'package:liveit_new/features/home/presentation/widget/status_banners.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => HomeBloc(InMemoryHomeRepository())..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  Future<void> _onRefresh(BuildContext context) async {
    final HomeBloc bloc = context.read<HomeBloc>()
      ..add(const HomeRefreshed());

    await bloc.stream.firstWhere(
      (HomeState state) => state.status != HomeStatus.loading,
    );
  }

  String _buildGreeting(HomeUiState state) {
    final int hour = TimeOfDay.now().hour;
    final String period;
    if (hour < 12) {
      period = 'pagi';
    } else if (hour < 17) {
      period = 'siang';
    } else {
      period = 'malam';
    }

    return 'Selamat $period, ${state.userFirstName}';
  }

  List<Widget> _buildSections(BuildContext context, HomeState state) {
    final List<Widget> sections = <Widget>[];
    final HomeBloc bloc = context.read<HomeBloc>();
    final HomeUiState uiState = state.uiState;

    final Widget statusBanner = HomeStatusBanners(
      isOffline: uiState.isOffline,
      hasError: uiState.hasError,
      onRetry: () => bloc.add(const HomeRetryRequested()),
    );

    if (uiState.isOffline || uiState.hasError) {
      sections.add(statusBanner);
      sections.add(const SizedBox(height: 16));
    }

    sections
      ..add(
        DailySummaryCard(
          greeting: _buildGreeting(uiState),
          completedCount: uiState.completedCount,
          totalCount: uiState.totalHabitCount,
          completionRate: uiState.completionRate,
          allDone: uiState.allHabitsDone,
          onAddHabit: uiState.hasAnyHabit
              ? null
              : () => bloc.add(
                    const PlaceholderActionRequested(
                      'Navigasi katalog habit akan segera tersedia.',
                    ),
                  ),
        ),
      )
      ..add(const SizedBox(height: 24));

    if (uiState.hasAnyHabit) {
      sections
        ..add(
          HabitGroupsSection(
            pendingHabits: uiState.pendingHabits,
            completedHabits: uiState.completedHabits,
            onCheckIn: (HabitItem habit) => bloc.add(
              HabitCheckInRequested(habit.id),
            ),
            onUndo: (HabitItem habit) => bloc.add(
              HabitUndoRequested(habit.id),
            ),
          ),
        )
        ..add(const SizedBox(height: 24));
    } else {
      sections
        ..add(
          HabitEmptyStateCard(
            recommendations: uiState.recommendations,
            onAddHabit: () => bloc.add(
              const PlaceholderActionRequested(
                'Buka katalog habit akan dihadirkan di rilis berikutnya.',
              ),
            ),
          ),
        )
        ..add(const SizedBox(height: 24));
    }

    sections
      ..add(
        DevotionalCard(
          devotional: uiState.devotional,
          onRead: () => bloc.add(
            const PlaceholderActionRequested(
              'Navigasi ke detail renungan dalam pengembangan.',
            ),
          ),
          onCreateHabit: () => bloc.add(
            const DevotionalHabitCreateRequested(),
          ),
        ),
      )
      ..add(const SizedBox(height: 24))
      ..add(
        GamificationHighlightCard(
          data: uiState.gamification,
          onViewProfile: () => bloc.add(
            const PlaceholderActionRequested(
              'Profil lengkap akan dibuka di rilis berikutnya.',
            ),
          ),
        ),
      )
      ..add(const SizedBox(height: 48));

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (HomeState previous, HomeState current) =>
          previous.successMessage != current.successMessage ||
          previous.errorMessage != current.errorMessage,
      listener: (BuildContext context, HomeState state) {
        if (!state.hasFeedback) {
          return;
        }

        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();

        final String message = state.successMessage ?? state.errorMessage ?? '';
        final bool isError = state.errorMessage != null;

        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        );

        context.read<HomeBloc>().add(const HomeMessageCleared());
      },
      builder: (BuildContext context, HomeState state) {
        final List<Widget> sections = _buildSections(context, state);

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) => sections[index],
                        childCount: sections.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
