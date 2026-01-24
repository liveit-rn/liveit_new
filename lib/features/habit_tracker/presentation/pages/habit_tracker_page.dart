import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liveit_new/core/router/app_router.dart';
import 'package:liveit_new/features/habit_tracker/domain/entities/user_habit.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_bloc.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_event.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_state.dart';
import 'package:liveit_new/features/home/presentation/widgets/habit_card.dart';

@RoutePage()
class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage> {
  @override
  void initState() {
    super.initState();
    context.read<HabitBloc>().add(HabitStarted());
  }

  void _showHabitOptions(UserHabit habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Habit'),
                onTap: () {
                  context.router.pop();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.archive_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Arsipkan',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  context.router.pop();
                  _confirmArchive(habit);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmArchive(UserHabit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arsipkan Habit?'),
        content: Text(
          'Apakah kamu ingin mengarsipkan "${habit.title ?? habit.habit?.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => context.router.pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              context.router.pop();
              context.read<HabitBloc>().add(
                HabitArchived(userHabitId: habit.id),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.router.push(const AddHabitRoute());
            },
          ),
        ],
      ),
      body: BlocBuilder<HabitBloc, HabitState>(
        builder: (context, state) {
          if (state is HabitLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HabitError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load habits',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      context.read<HabitBloc>().add(HabitStarted());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is HabitLoaded) {
            if (state.habits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No habits yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start building good habits today!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        context.router.push(const AddHabitRoute());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Habit'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HabitBloc>().add(HabitStarted());
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.habits.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final userHabit = state.habits[index];
                  return HabitCard(
                    userHabit: userHabit,
                    onToggle: () {
                      if (userHabit.checkedInToday) {
                        context.read<HabitBloc>().add(
                          HabitUndoCheckInRequested(
                            userHabitId: userHabit.id,
                            date: DateTime.now(),
                          ),
                        );
                      } else {
                        context.read<HabitBloc>().add(
                          HabitCheckInRequested(
                            userHabitId: userHabit.id,
                            date: DateTime.now(),
                          ),
                        );
                      }
                    },
                    onEdit: () {
                      _showHabitOptions(userHabit);
                    },
                    onArchive: () {
                      _showHabitOptions(userHabit);
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
