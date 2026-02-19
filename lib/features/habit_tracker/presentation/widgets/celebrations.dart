import 'dart:math';
import 'package:flutter/material.dart';

/// ConfettiOverlay - Shows celebratory confetti animation.
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool showConfetti;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.showConfetti = false,
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_ConfettiParticle>? _particles;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isAnimating = false);
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showConfetti && !oldWidget.showConfetti && !_isAnimating) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _particles = List.generate(
      50,
      (_) => _ConfettiParticle.random(),
    );
    setState(() => _isAnimating = true);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isAnimating && _particles != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles!,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final int shape;

  _ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });

  factory _ConfettiParticle.random() {
    final random = Random();
    final colors = [
      const Color(0xFF2F5D62),
      const Color(0xFF68B0AB),
      const Color(0xFFC3B49A),
      const Color(0xFFFF7B54),
      const Color(0xFFF9A826),
      const Color(0xFF6366F1),
      const Color(0xFF22C55E),
      const Color(0xFFEC4899),
    ];

    return _ConfettiParticle(
      startX: random.nextDouble(),
      startY: -0.1 - random.nextDouble() * 0.3,
      velocityX: (random.nextDouble() - 0.5) * 0.4,
      velocityY: 0.3 + random.nextDouble() * 0.5,
      color: colors[random.nextInt(colors.length)],
      size: 6 + random.nextDouble() * 8,
      rotation: random.nextDouble() * pi * 2,
      rotationSpeed: (random.nextDouble() - 0.5) * 10,
      shape: random.nextInt(3),
    );
  }

  Offset getPosition(double progress, Size size) {
    final gravity = 0.5 * progress * progress;
    return Offset(
      (startX + velocityX * progress) * size.width,
      (startY + velocityY * progress + gravity) * size.height,
    );
  }

  double getRotation(double progress) {
    return rotation + rotationSpeed * progress;
  }

  double getOpacity(double progress) {
    if (progress < 0.2) return progress / 0.2;
    if (progress > 0.7) return 1 - (progress - 0.7) / 0.3;
    return 1;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final position = particle.getPosition(progress, size);
      final rotation = particle.getRotation(progress);
      final opacity = particle.getOpacity(progress);

      if (position.dy > size.height || opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);

      if (particle.shape == 0) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size,
          ),
          paint,
        );
      } else if (particle.shape == 1) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        final path = Path();
        final half = particle.size / 2;
        path.moveTo(0, -half);
        path.lineTo(half, half);
        path.lineTo(-half, half);
        path.close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class StreakCelebration extends StatelessWidget {
  final int streak;
  final String habitName;
  final VoidCallback onDismiss;

  const StreakCelebration({
    super.key,
    required this.streak,
    required this.habitName,
    required this.onDismiss,
  });

  String get _milestoneEmoji {
    if (streak >= 100) return '👑';
    if (streak >= 30) return '🔥';
    if (streak >= 7) return '⚡';
    return '✨';
  }

  String get _milestoneTitle {
    if (streak >= 100) return 'LEGENDA!';
    if (streak >= 30) return 'LUAR BIASA!';
    if (streak >= 7) return 'HEBAT!';
    return 'BAGUS!';
  }

  String get _milestoneMessage {
    if (streak >= 100) {
      return 'Kamu sudah konsisten $streak hari berturut-turut! Ini pencapaian luar biasa!';
    }
    if (streak >= 30) {
      return '$streak hari streak! Konsistensi adalah kunci pertumbuhan.';
    }
    if (streak >= 7) {
      return 'Seminggu penuh! Kamu membangun kebiasaan yang kuat.';
    }
    return 'Terus pertahankan momentum!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorScheme.tertiary.withOpacity(0.3),
                    colorScheme.tertiary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _milestoneEmoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _milestoneTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.tertiary.withOpacity(0.15),
                    colorScheme.primary.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '$streak Hari Streak',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _milestoneMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              habitName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onDismiss,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }
}

class AllDoneCelebration extends StatelessWidget {
  final int totalHabits;
  final VoidCallback onDismiss;

  const AllDoneCelebration({
    super.key,
    required this.totalHabits,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.2),
                    colorScheme.primaryContainer.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🎉',
                  style: TextStyle(fontSize: 56),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SELESAI!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$totalHabits/$totalHabits Habit',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kamu sudah menyelesaikan semua habit hari ini!\nIstirahat yang cukup dan sampai jumpa besok.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onDismiss,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Terima Kasih'),
            ),
          ],
        ),
      ),
    );
  }
}

class ZoePointsPopup extends StatefulWidget {
  final int points;
  final String reason;
  final VoidCallback? onComplete;

  const ZoePointsPopup({
    super.key,
    required this.points,
    required this.reason,
    this.onComplete,
  });

  @override
  State<ZoePointsPopup> createState() => _ZoePointsPopupState();
}

class _ZoePointsPopupState extends State<ZoePointsPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, -0.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.tertiary,
                      colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.tertiary.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.points} Zoe',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
