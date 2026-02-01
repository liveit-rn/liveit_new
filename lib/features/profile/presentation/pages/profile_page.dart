import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/models/profile_model.dart';
import '../../presentation/bloc/profile_bloc.dart';
import '../../presentation/bloc/profile_state.dart';
import '../../presentation/bloc/profile_event.dart';

/// Profile Page with modern iOS glass-morphism aesthetic (2026 style).
/// WHY: Redesigned to match LIVEIT "Grounded Growth" brand with frosted glass
/// effects, layered depth, and spiritual warmth. Integrates both AuthBloc
/// (for auth state) and ProfileBloc (for gamification stats).
@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger profile fetch when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileBloc>().add(const ProfileRequested());
    });

    return const _ProfileView();
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return const _LoadingView();
          }

          if (authState is! AuthAuthenticated) {
            return const _UnauthenticatedView();
          }

          final user = authState.user;

          return BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, profileState) {
              // Use profile data if available, fallback to auth user data
              final profile = profileState.profile;
              final isLoading = profileState.status == ProfileStatus.loading;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Glass Header with Gradient
                  SliverToBoxAdapter(
                    child: _GlassHeader(
                      user: user,
                      profile: profile,
                      isLoading: isLoading,
                    ),
                  ),

                  // Stats Section
                  SliverToBoxAdapter(
                    child: _StatsSection(
                      profile: profile,
                      isLoading: isLoading,
                    ),
                  ),

                  // Menu Section
                  SliverToBoxAdapter(
                    child: _GlassMenuSection(
                      profile: profile,
                    ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Loading view with shimmer effect
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// View for unauthenticated users
class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Anda Belum Login',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login untuk melihat profil Anda',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.router.pushPath('/'),
              icon: const Icon(Icons.login),
              label: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass-morphism header with gradient background
class _GlassHeader extends StatelessWidget {
  final dynamic user;
  final ProfileModel? profile;
  final bool isLoading;

  const _GlassHeader({
    required this.user,
    this.profile,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get display info with fallbacks
    final displayName = profile?.displayName ??
        user.name ??
        user.username ??
        user.email.split('@').first;
    final username = profile?.username ?? user.username ?? 'user';
    final email = profile?.email ?? user.email;
    final joinedDate = profile?.joinedAt ?? user.createdAt;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.secondary.withValues(alpha: 0.1),
            colorScheme.tertiary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                children: [
                  // Profile Avatar with glass ring
                  _AvatarWithRing(
                    avatarUrl: profile?.avatarUrl,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 20),

                  // Display Name
                  Text(
                    displayName.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.3,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // Username
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '@$username',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Member since badge
                  _MemberSinceBadge(joinedAt: joinedDate),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar with frosted glass ring effect
class _AvatarWithRing extends StatelessWidget {
  final String? avatarUrl;
  final bool isLoading;

  const _AvatarWithRing({
    this.avatarUrl,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.6),
            colorScheme.secondary.withValues(alpha: 0.4),
            colorScheme.tertiary.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface.withValues(alpha: 0.9),
        ),
        child: CircleAvatar(
          radius: 56,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Icon(
                  Icons.person,
                  size: 48,
                  color: colorScheme.primary,
                )
              : null,
        ),
      ),
    );
  }
}

/// Member since badge with glass effect
class _MemberSinceBadge extends StatelessWidget {
  final DateTime joinedAt;

  const _MemberSinceBadge({required this.joinedAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final memberDuration = _calculateMemberDuration(joinedAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Bergabung $memberDuration',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateMemberDuration(DateTime joinedAt) {
    final now = DateTime.now();
    final difference = now.difference(joinedAt);

    if (difference.inDays < 30) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan yang lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun yang lalu';
    }
  }
}

/// Stats section with glass-morphism cards
class _StatsSection extends StatelessWidget {
  final ProfileModel? profile;
  final bool isLoading;

  const _StatsSection({
    this.profile,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final zoePoints = profile?.totalZoePoints ?? 0;
    final level = profile?.currentLevel ?? 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Statistik Perjalanan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _GlassStatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Zoe Points',
                  value: zoePoints.toString(),
                  color: colorScheme.tertiary,
                  subtitle: 'Semangat!',
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassStatCard(
                  icon: Icons.military_tech_rounded,
                  label: 'Level',
                  value: level.toString(),
                  color: colorScheme.primary,
                  subtitle: _getLevelName(level),
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Langkah Pertama';
      case 2:
        return 'Membangun Irama';
      case 3:
        return 'Konsisten';
      case 4:
        return 'Pemimpin Rohani';
      case 5:
        return 'Teladan Iman';
      default:
        return 'Level $level';
    }
  }
}

/// Individual glass stat card
class _GlassStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String subtitle;
  final bool isLoading;

  const _GlassStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withValues(alpha: 0.8),
            colorScheme.surface.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon with glass background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),

          // Value
          isLoading
              ? Container(
                  width: 40,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
          const SizedBox(height: 4),

          // Label
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass-morphism menu section
class _GlassMenuSection extends StatelessWidget {
  final ProfileModel? profile;

  const _GlassMenuSection({this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                _GlassMenuItem(
                  icon: Icons.edit_rounded,
                  title: 'Edit Profil',
                  subtitle: 'Ubah nama, foto, dan informasi',
                  onTap: () {
                    // TODO: Navigate to edit profile
                    _showComingSoonSnackbar(context, 'Edit Profil');
                  },
                ),
                _MenuDivider(),
                _GlassMenuItem(
                  icon: Icons.badge_rounded,
                  title: 'Badge & Pencapaian',
                  subtitle: 'Lihat semua badge yang dikumpulkan',
                  onTap: () {
                    // TODO: Navigate to badges
                    _showComingSoonSnackbar(context, 'Badge & Pencapaian');
                  },
                ),
                _MenuDivider(),
                _GlassMenuItem(
                  icon: Icons.history_rounded,
                  title: 'Riwayat Aktivitas',
                  subtitle: 'Catatan perjalanan rohanimu',
                  onTap: () {
                    // TODO: Navigate to activity history
                    _showComingSoonSnackbar(context, 'Riwayat Aktivitas');
                  },
                ),
                _MenuDivider(),
                _GlassMenuItem(
                  icon: Icons.settings_rounded,
                  title: 'Pengaturan',
                  subtitle: 'Privasi dan notifikasi',
                  onTap: () {
                    // TODO: Navigate to settings
                    _showComingSoonSnackbar(context, 'Pengaturan');
                  },
                ),
                _MenuDivider(),
                _LogoutMenuItem(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonSnackbar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera hadir!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Glass menu item with hover effect
class _GlassMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GlassMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: colorScheme.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Divider for menu items
class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}

/// Logout menu item with distinct styling
class _LogoutMenuItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        splashColor: colorScheme.error.withValues(alpha: 0.08),
        highlightColor: colorScheme.error.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container with error color
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logout',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Keluar dari akun',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Logout',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Yakin ingin keluar dari LIVEIT?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthLogoutRequested());
              context.router.pushPath('/');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Berhasil logout'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
