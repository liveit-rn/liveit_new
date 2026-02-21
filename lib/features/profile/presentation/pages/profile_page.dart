import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/models/profile_model.dart';
import '../../presentation/bloc/profile_bloc.dart';
import '../../presentation/bloc/profile_state.dart';
import '../../presentation/bloc/profile_event.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileBloc>().add(const ProfileRequested());
    });
    return const _ProfileView();
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with TickerProviderStateMixin {
  late final AnimationController _glassController;
  late final AnimationController _statsController;

  void _showAvatarPickerError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _dispatchAvatarUpload({
    required List<int> fileBytes,
    required String fileName,
  }) {
    if (!mounted) return;
    context.read<ProfileBloc>().add(
      ProfileAvatarUploadRequested(fileBytes: fileBytes, fileName: fileName),
    );
  }

  Future<bool> _pickWithFilePickerFallback() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return false;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return false;

      _dispatchAvatarUpload(
        fileBytes: bytes,
        fileName: file.name.isEmpty ? 'avatar.jpg' : file.name,
      );
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final fileBytes = await pickedFile.readAsBytes();

      _dispatchAvatarUpload(
        fileBytes: fileBytes,
        fileName: pickedFile.name.isEmpty ? 'avatar.jpg' : pickedFile.name,
      );
    } on MissingPluginException {
      final handled = await _pickWithFilePickerFallback();
      if (!handled) {
        _showAvatarPickerError(
          'Fitur pilih foto belum aktif. Coba full restart aplikasi.',
        );
      }
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('denied') || code.contains('permission')) {
        _showAvatarPickerError(
          'Akses galeri ditolak. Izinkan akses foto di pengaturan perangkat.',
        );
        return;
      }

      if (code.contains('channel-error')) {
        final handled = await _pickWithFilePickerFallback();
        if (handled) return;
      }

      _showAvatarPickerError('Gagal memilih foto profil (${e.code})');
    } catch (_) {
      _showAvatarPickerError('Gagal memilih foto profil');
    }
  }

  void _removeAvatar() {
    if (!mounted) return;
    context.read<ProfileBloc>().add(const ProfileAvatarRemoveRequested());
  }

  @override
  void initState() {
    super.initState();
    _glassController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _glassController.dispose();
    _statsController.dispose();
    super.dispose();
  }

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

          return BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, profileState) {
              if (profileState.status == ProfileStatus.failure &&
                  profileState.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(profileState.errorMessage!)),
                );
              }
            },
            builder: (context, profileState) {
              final profile = profileState.profile;
              final isLoading = profileState.status == ProfileStatus.loading;

              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _glassController.forward();
                  _statsController.forward();
                }
              });

              return _ModernGlassScaffold(
                user: user,
                profile: profile,
                isLoading: isLoading,
                glassController: _glassController,
                statsController: _statsController,
                onAvatarChangeRequested: _pickAndUploadAvatar,
                onAvatarRemoveRequested: _removeAvatar,
              );
            },
          );
        },
      ),
    );
  }
}

class _ModernGlassScaffold extends StatelessWidget {
  final dynamic user;
  final ProfileModel? profile;
  final bool isLoading;
  final AnimationController glassController;
  final AnimationController statsController;
  final VoidCallback onAvatarChangeRequested;
  final VoidCallback onAvatarRemoveRequested;

  const _ModernGlassScaffold({
    required this.user,
    required this.profile,
    required this.isLoading,
    required this.glassController,
    required this.statsController,
    required this.onAvatarChangeRequested,
    required this.onAvatarRemoveRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.background,
            colorScheme.tertiary.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            slivers: [
              _GlassHeader(
                user: user,
                profile: profile,
                isLoading: isLoading,
                controller: glassController,
                onAvatarChangeRequested: onAvatarChangeRequested,
                onAvatarRemoveRequested: onAvatarRemoveRequested,
              ),
              _GamificationSection(
                profile: profile,
                isLoading: isLoading,
                controller: statsController,
              ),
              _StatsGrid(
                profile: profile,
                isLoading: isLoading,
                controller: statsController,
              ),
              _GlassMenuSection(profile: profile, controller: glassController),
              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          _GlassBlurOverlay(controller: glassController),
        ],
      ),
    );
  }
}

class _GlassBlurOverlay extends StatelessWidget {
  final AnimationController controller;

  const _GlassBlurOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Container();
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            Theme.of(context).colorScheme.background,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat profil...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.background,
          ],
        ),
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.15),
                        colorScheme.tertiary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Selamat Datang di LIVEIT',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Login untuk memulai perjalanan rohanimu',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                _ModernButton(
                  onPressed: () => context.router.pushPath('/'),
                  label: 'Masuk',
                  icon: Icons.login_rounded,
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final bool isPrimary;

  const _ModernButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: (isPrimary ? colorScheme.primary : colorScheme.tertiary)
            .withValues(alpha: 0.15),
        highlightColor: (isPrimary ? colorScheme.primary : colorScheme.tertiary)
            .withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPrimary
                  ? [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.85),
                    ]
                  : [
                      colorScheme.tertiary,
                      colorScheme.tertiary.withValues(alpha: 0.85),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isPrimary ? colorScheme.primary : colorScheme.tertiary)
                    .withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassHeader extends StatelessWidget {
  final dynamic user;
  final ProfileModel? profile;
  final bool isLoading;
  final AnimationController controller;
  final VoidCallback onAvatarChangeRequested;
  final VoidCallback onAvatarRemoveRequested;

  const _GlassHeader({
    required this.user,
    required this.profile,
    required this.isLoading,
    required this.controller,
    required this.onAvatarChangeRequested,
    required this.onAvatarRemoveRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayName =
        profile?.displayName ??
        user.name ??
        user.username ??
        user.email.split('@').first;
    final username = profile?.username ?? user.username ?? 'user';
    final email = profile?.email ?? user.email;
    final joinedDate = profile?.joinedAt ?? user.createdAt;

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Column(
          children: [
            const SizedBox(height: 60),
            _AvatarGlass(
              avatarUrl: profile?.avatarUrl,
              isLoading: isLoading,
              onChangeRequested: onAvatarChangeRequested,
              onRemoveRequested: onAvatarRemoveRequested,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    displayName.toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.12),
                          colorScheme.primary.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '@$username',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _MemberSinceBadge(joinedAt: joinedDate),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AvatarGlass extends StatelessWidget {
  final String? avatarUrl;
  final bool isLoading;
  final VoidCallback onChangeRequested;
  final VoidCallback onRemoveRequested;

  const _AvatarGlass({
    this.avatarUrl,
    required this.isLoading,
    required this.onChangeRequested,
    required this.onRemoveRequested,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showAvatarPreview(context);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Container(
              key: ValueKey(avatarUrl ?? 'default'),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.tertiary.withValues(alpha: 0.5),
                    colorScheme.secondary.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.85),
                    ),
                    child: avatarUrl != null
                        ? Image.network(
                            avatarUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stack) =>
                                _AvatarPlaceholder(colorScheme: colorScheme),
                          )
                        : _AvatarPlaceholder(colorScheme: colorScheme),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarPreview(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Avatar preview',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AvatarPreviewOverlay(
          avatarUrl: avatarUrl,
          onChangeRequested: onChangeRequested,
          onRemoveRequested: onRemoveRequested,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _AvatarPreviewOverlay extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onChangeRequested;
  final VoidCallback onRemoveRequested;

  const _AvatarPreviewOverlay({
    required this.avatarUrl,
    required this.onChangeRequested,
    required this.onRemoveRequested,
  });

  Future<void> _openAvatarActions(BuildContext context) async {
    HapticFeedback.selectionClick();
    final colorScheme = Theme.of(context).colorScheme;

    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text('Ganti foto profile'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AvatarAction.change),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Hapus foto profile',
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: avatarUrl == null
                    ? null
                    : () =>
                          Navigator.of(sheetContext).pop(_AvatarAction.remove),
              ),
            ],
          ),
        );
      },
    );

    if (action == null || !context.mounted) return;

    Navigator.of(context).pop();

    if (action == _AvatarAction.change) {
      onChangeRequested();
      return;
    }

    if (action == _AvatarAction.remove) {
      onRemoveRequested();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DraggableAvatarPreview(
      avatarUrl: avatarUrl,
      onClose: () => Navigator.of(context).pop(),
      onOpenActions: () => _openAvatarActions(context),
    );
  }
}

class _DraggableAvatarPreview extends StatefulWidget {
  final String? avatarUrl;
  final VoidCallback onClose;
  final VoidCallback onOpenActions;

  const _DraggableAvatarPreview({
    required this.avatarUrl,
    required this.onClose,
    required this.onOpenActions,
  });

  @override
  State<_DraggableAvatarPreview> createState() =>
      _DraggableAvatarPreviewState();
}

class _DraggableAvatarPreviewState extends State<_DraggableAvatarPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;

  Offset _dragOffset = Offset.zero;
  double _dragScale = 1;
  double _dragRotation = 0;
  bool _isDismissAnimating = false;

  Animation<Offset>? _offsetAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _rotationAnimation;

  double get _overlayAlpha {
    final distance = _dragOffset.distance;
    return (0.45 - (distance / 900)).clamp(0.16, 0.45);
  }

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(vsync: this)
      ..addListener(_handleMotionTick)
      ..addStatusListener(_handleMotionStatus);
  }

  @override
  void dispose() {
    _motionController
      ..removeListener(_handleMotionTick)
      ..removeStatusListener(_handleMotionStatus)
      ..dispose();
    super.dispose();
  }

  void _handleMotionTick() {
    final offset = _offsetAnimation;
    final scale = _scaleAnimation;
    final rotation = _rotationAnimation;

    if (offset == null || scale == null || rotation == null) return;

    setState(() {
      _dragOffset = offset.value;
      _dragScale = scale.value;
      _dragRotation = rotation.value;
    });
  }

  void _handleMotionStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isDismissAnimating && mounted) {
      widget.onClose();
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_isDismissAnimating) return;
    _motionController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDismissAnimating) return;

    final nextOffset = _dragOffset + details.delta;
    final distance = nextOffset.distance;

    setState(() {
      _dragOffset = nextOffset;
      _dragScale = (1 - (distance / 1100)).clamp(0.86, 1.0);
      _dragRotation = (nextOffset.dx / 600).clamp(-0.12, 0.12);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDismissAnimating) return;

    final speed = details.velocity.pixelsPerSecond.distance;
    final distance = _dragOffset.distance;
    final shouldDismiss = speed > 1100 || distance > 140;

    if (shouldDismiss) {
      HapticFeedback.lightImpact();
      _animateDismiss(details.velocity.pixelsPerSecond);
      return;
    }

    _animateBackToCenter();
  }

  void _animateBackToCenter() {
    _isDismissAnimating = false;
    _runMotionAnimation(
      targetOffset: Offset.zero,
      targetScale: 1,
      targetRotation: 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
    );
  }

  void _animateDismiss(Offset velocity) {
    _isDismissAnimating = true;

    final screen = MediaQuery.of(context).size;
    final velocityDistance = velocity.distance;

    Offset direction;
    if (velocityDistance > 20) {
      direction = Offset(
        velocity.dx / velocityDistance,
        velocity.dy / velocityDistance,
      );
    } else if (_dragOffset.distance > 0) {
      direction = Offset(
        _dragOffset.dx / _dragOffset.distance,
        _dragOffset.dy / _dragOffset.distance,
      );
    } else {
      direction = const Offset(0, 1);
    }

    final travelDistance = screen.longestSide * 0.9;
    final targetOffset = _dragOffset + (direction * travelDistance);

    _runMotionAnimation(
      targetOffset: targetOffset,
      targetScale: (_dragScale - 0.18).clamp(0.72, 0.9),
      targetRotation: _dragRotation + (direction.dx * 0.25),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInCubic,
    );
  }

  void _runMotionAnimation({
    required Offset targetOffset,
    required double targetScale,
    required double targetRotation,
    required Duration duration,
    required Curve curve,
  }) {
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: _motionController, curve: curve));

    _scaleAnimation = Tween<double>(
      begin: _dragScale,
      end: targetScale,
    ).animate(CurvedAnimation(parent: _motionController, curve: curve));

    _rotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(parent: _motionController, curve: curve));

    _motionController
      ..duration = duration
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewSize = (MediaQuery.of(context).size.width * 0.72).clamp(
      220.0,
      340.0,
    );

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClose,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withValues(alpha: _overlayAlpha),
                ),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: _dragRotation,
                  child: Transform.scale(
                    scale: _dragScale,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: widget.onOpenActions,
                          child: Container(
                            width: previewSize,
                            height: previewSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.22,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.avatarUrl != null
                                  ? Image.network(
                                      widget.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: colorScheme.surface,
                                              child: _AvatarPlaceholder(
                                                colorScheme: colorScheme,
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      color: colorScheme.surface,
                                      child: _AvatarPlaceholder(
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onOpenActions,
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.outline.withValues(
                                      alpha: 0.22,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AvatarAction { change, remove }

class _AvatarPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;

  const _AvatarPlaceholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 52,
        color: colorScheme.primary.withValues(alpha: 0.7),
      ),
    );
  }
}

class _MemberSinceBadge extends StatelessWidget {
  final DateTime joinedAt;

  const _MemberSinceBadge({required this.joinedAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final memberDuration = _calculateMemberDuration(joinedAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
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
      return '${difference.inDays} hari';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun';
    }
  }
}

class _GamificationSection extends StatelessWidget {
  final ProfileModel? profile;
  final bool isLoading;
  final AnimationController controller;

  const _GamificationSection({
    required this.profile,
    required this.isLoading,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.tertiary.withValues(alpha: 0.2),
                          colorScheme.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: colorScheme.tertiary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perjalanan Rohanimu',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Lacak progres dan raih pencapaian',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final ProfileModel? profile;
  final bool isLoading;
  final AnimationController controller;

  const _StatsGrid({
    required this.profile,
    required this.isLoading,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final zoePoints = profile?.totalZoePoints ?? 0;
    final level = profile?.currentLevel ?? 1;
    final streak = profile?.currentStreak ?? 0;
    const badges = 3;

    final stats = [
      _StatItem(
        icon: Icons.local_fire_department_rounded,
        label: 'Zoe Points',
        value: _formatNumber(zoePoints),
        color: colorScheme.tertiary,
        subtitle: 'Semangat!',
      ),
      _StatItem(
        icon: Icons.military_tech_rounded,
        label: 'Level',
        value: level.toString(),
        color: colorScheme.primary,
        subtitle: _getLevelName(level),
      ),
      _StatItem(
        icon: Icons.trending_up_rounded,
        label: 'Streak',
        value: '$streak',
        color: const Color(0xFFFFB74D),
        subtitle: 'hari berturut',
      ),
      _StatItem(
        icon: Icons.workspace_premium_rounded,
        label: 'Badge',
        value: badges.toString(),
        color: const Color(0xFFA78BFA),
        subtitle: 'diperoleh',
      ),
    ];

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats.map((stat) {
                  return SizedBox(
                    width: itemWidth,
                    child: _GlassStatCard(stat: stat, isLoading: isLoading),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
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

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String subtitle;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });
}

class _GlassStatCard extends StatelessWidget {
  final _StatItem stat;
  final bool isLoading;

  const _GlassStatCard({required this.stat, required this.isLoading});

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
            colorScheme.surface.withValues(alpha: 0.85),
            colorScheme.surface.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stat.color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: stat.color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      stat.color.withValues(alpha: 0.2),
                      stat.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stat.icon, color: stat.color, size: 22),
              ),
              const Spacer(),
              if (!isLoading)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 16),
          isLoading
              ? Container(
                  width: 60,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              : Text(
                  stat.value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: stat.color,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: stat.color.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassMenuSection extends StatelessWidget {
  final ProfileModel? profile;
  final AnimationController controller;

  const _GlassMenuSection({required this.profile, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final menuItems = [
      _MenuItem(
        icon: Icons.edit_rounded,
        title: 'Edit Profil',
        subtitle: 'Ubah data personal',
        onTap: () => _showComingSoon(context, 'Edit Profil'),
      ),
      _MenuItem(
        icon: Icons.badge_rounded,
        title: 'Badge & Pencapaian',
        subtitle: 'Lihat koleksi badge',
        onTap: () => _showComingSoon(context, 'Badge & Pencapaian'),
      ),
      _MenuItem(
        icon: Icons.history_rounded,
        title: 'Riwayat Aktivitas',
        subtitle: 'Catatan perjalanan',
        onTap: () => _showComingSoon(context, 'Riwayat Aktivitas'),
      ),
      _MenuItem(
        icon: Icons.notifications_rounded,
        title: 'Notifikasi',
        subtitle: 'Pengaturan notifikasi',
        onTap: () => _showComingSoon(context, 'Notifikasi'),
      ),
      _MenuItem(
        icon: Icons.security_rounded,
        title: 'Privasi & Keamanan',
        subtitle: 'Pengaturan privasi',
        onTap: () => _showComingSoon(context, 'Privasi & Keamanan'),
      ),
    ];

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.7),
                      colorScheme.surface.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Column(
                      children: menuItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Column(
                          children: [
                            _GlassMenuItem(item: item),
                            if (index < menuItems.length - 1)
                              Divider(
                                height: 1,
                                indent: 72,
                                endIndent: 16,
                                color: colorScheme.outline.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _LogoutButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text('$feature segera hadir!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.95),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _GlassMenuItem extends StatelessWidget {
  final _MenuItem item;

  const _GlassMenuItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: colorScheme.primary.withValues(alpha: 0.06),
        highlightColor: colorScheme.primary.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.4),
                      colorScheme.primaryContainer.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, size: 22, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.error.withValues(alpha: 0.08),
        highlightColor: colorScheme.error.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.error.withValues(alpha: 0.08),
                colorScheme.error.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Keluar',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          size: 32,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Keluar dari LIVEIT?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kamu bisa login kembali kapan saja',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: _ModernButton(
                              onPressed: () => Navigator.pop(ctx),
                              label: 'Batal',
                              icon: Icons.close_rounded,
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  context.read<AuthBloc>().add(
                                    AuthLogoutRequested(),
                                  );
                                  context.router.pushPath('/');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text('Berhasil logout'),
                                        ],
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                splashColor: colorScheme.error.withValues(
                                  alpha: 0.2,
                                ),
                                highlightColor: colorScheme.error.withValues(
                                  alpha: 0.1,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Keluar',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
