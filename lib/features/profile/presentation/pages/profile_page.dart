import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileView();
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          print('📱 ProfilePage: AuthState = ${authState.runtimeType}');

          if (authState is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authState is! AuthAuthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Anda belum login'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.router.pushPath('/'),
                    child: const Text('Login'),
                  ),
                ],
              ),
            );
          }

          final user = authState.user;
          print('👤 Profile User: ${user.username} - ${user.name}');

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProfileHeader(user: user),
                  const SizedBox(height: 24),
                  _StatsCard(),
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
  final dynamic user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get display name: priority is name -> username -> email
    final displayName =
        user.name ?? user.username ?? user.email.split('@').first;
    final username = user.username ?? 'user';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular profile photo - slightly smaller for better balance
            CircleAvatar(
              radius: 48, // Reduced from 56 for better proportion
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 48,
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
                    displayName.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, // Increased from bold
                      fontSize: 20,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Username - Larger and more prominent
                  Text(
                    '@$username',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600, // Increased from w500
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Email
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ), // Better contrast
                      fontSize: 13,
                    ),
                    maxLines: 1,
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
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1, // Subtle shadow for depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.local_fire_department_outlined,
              label: 'Zoe Points',
              value: '480', // TODO: Get from backend
              color: theme.colorScheme.tertiary,
              showTooltip: true,
            ),
            _StatItem(
              icon: Icons.military_tech_outlined,
              label: 'Level',
              value: '3', // TODO: Get from backend
              color: theme.colorScheme.primary,
            ),
            _StatItem(
              icon: Icons.calendar_today_outlined,
              label: 'Bergabung',
              value: '1bln', // TODO: Get from user.createdAt
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
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
        Icon(icon, color: color, size: 24), // Consistent icon size
        const SizedBox(height: 10),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800, // Bolder for emphasis
            fontSize: 28, // Larger for better hierarchy
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 12,
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
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(
              Icons.edit_outlined,
              size: 22,
              color: colorScheme.onSurface,
            ),
            title: Text(
              'Edit Profil',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            splashColor: colorScheme.primary.withValues(alpha: 0.08),
            onTap: () {
              // TODO: Navigate to edit profile
            },
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(
              Icons.badge_outlined,
              size: 22,
              color: colorScheme.onSurface,
            ),
            title: Text(
              'Badge & Pencapaian',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            splashColor: colorScheme.primary.withValues(alpha: 0.08),
            onTap: () {
              // TODO: Navigate to badges
            },
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(
              Icons.history_outlined,
              size: 22,
              color: colorScheme.onSurface,
            ),
            title: Text(
              'Riwayat Aktivitas',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            splashColor: colorScheme.primary.withValues(alpha: 0.08),
            onTap: () {
              // TODO: Navigate to activity history
            },
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          // Logout with subtle background
          Container(
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Icon(Icons.logout, size: 22, color: colorScheme.error),
              title: Text(
                'Logout',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              splashColor: colorScheme.error.withValues(alpha: 0.12),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
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
              print('🚪 Logout: User confirmed logout');
              // Close dialog first
              Navigator.pop(ctx);

              // Trigger logout
              context.read<AuthBloc>().add(AuthLogoutRequested());

              // Navigate to login page
              context.router.pushPath('/');

              // Show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Berhasil logout'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
