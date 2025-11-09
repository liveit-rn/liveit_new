import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/in_memory_profile_repository.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProfileBloc(repository: InMemoryProfileRepository())
            ..add(const ProfileRequested()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray/beige background
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ProfileStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }

          if (state.profile == null) {
            return const Center(child: Text('Tidak ada data profil'));
          }

          final profile = state.profile!;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 24),
                  _StatsCard(profile: profile),
                  const SizedBox(height: 16),
                  _MenuSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large circular profile photo on the left
            CircleAvatar(
              radius: 56, // Larger size for prominence
              backgroundColor: colorScheme.primaryContainer,
              child: profile.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        profile.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 112,
                        height: 112,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 56,
                      color: colorScheme.onPrimaryContainer,
                    ),
            ),
            const SizedBox(width: 20),
            // Text information on the right (stacked vertically)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Name - Large and Bold
                  Text(
                    (profile.displayName ?? profile.username).toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Username - Smaller
                  Text(
                    '@${profile.username}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bio - Short description
                  Text(
                    'Ini adalah bio singkat saya...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final dynamic profile;

  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.local_fire_department_outlined,
              label: 'Zoe Points',
              value: profile.totalZoePoints.toString(),
              color: theme.colorScheme.tertiary,
              showTooltip: true,
            ),
            _StatItem(
              icon: Icons.military_tech_outlined,
              label: 'Level',
              value: profile.currentLevel.toString(),
              color: theme.colorScheme.primary,
            ),
            _StatItem(
              icon: Icons.calendar_today_outlined,
              label: 'Bergabung',
              value: _formatJoinDate(profile.joinedAt),
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff < 30) return '${diff}h';
    if (diff < 365) return '${diff ~/ 30}bln';
    return '${diff ~/ 365}thn';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showTooltip;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showTooltip = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (showTooltip) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Zoe Points adalah poin yang kamu dapatkan dari menyelesaikan habit dan aktivitas spiritual',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                child: Icon(
                  Icons.help_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to edit profile
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Badge & Pencapaian'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to badges
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Riwayat Aktivitas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to activity history
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Trigger logout via AuthBloc
              Navigator.pop(ctx);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
