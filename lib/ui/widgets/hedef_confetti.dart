import 'dart:async';
import 'dart:math' as math;

import 'package:deneme_takip/ui/theme.dart';
import 'package:deneme_takip/ui/widgets/hedef_edit_dialog.dart';
import 'package:flutter/material.dart';

/// Post-save celebration when a deneme hits the active hedef net.
///
/// Starts a calm full-viewport confetti burst and a dialog at the same time.
/// Primary action opens the same hedef editor as Özet; dismiss or edit both
/// return so the caller can continue to Özet. Save is already done — never
/// blocks navigation on confetti/dialog failures.
Future<void> celebrateHedefReached(
  BuildContext context, {
  required double currentHedef,
  required Future<void> Function(double next) onSaveTarget,
}) async {
  try {
    unawaited(playHedefConfetti(context));
    if (!context.mounted) return;

    final raise = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _HedefReachedDialog(),
    );
    if (!context.mounted) return;

    if (raise == true) {
      final next = await showEditHedefDialog(
        context,
        initial: currentHedef,
      );
      if (!context.mounted) return;
      if (next != null) {
        await onSaveTarget(next);
      }
    }
  } on Object {
    // Never block Özet navigation after a successful save.
  }
}

/// Short, non-blocking particle overlay (indigo / emerald / soft neutrals).
Future<void> playHedefConfetti(BuildContext context) async {
  try {
    // Navigator overlay (not root) so the celebration dialog paints above.
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: _HedefConfettiLayer(
            colors: colors,
            isDark: isDark,
            onFinished: () {
              try {
                entry.remove();
              } on Object {
                // Overlay already gone — fine.
              }
            },
          ),
        ),
      ),
    );
    overlay.insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 2600))
        .timeout(const Duration(milliseconds: 3200));
    try {
      entry.remove();
    } on Object {
      // Already removed by the layer.
    }
  } on Object {
    // Never block Özet navigation after a successful save.
  }
}

class _HedefReachedDialog extends StatelessWidget {
  const _HedefReachedDialog();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      title: Text(
        'Hedefine ulaştın!',
        style: TextStyle(
          color: colors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Tamam'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hedefi Yükselt'),
        ),
      ],
    );
  }
}

class _HedefConfettiLayer extends StatefulWidget {
  const _HedefConfettiLayer({
    required this.colors,
    required this.isDark,
    required this.onFinished,
  });

  final AppColors colors;
  final bool isDark;
  final VoidCallback onFinished;

  @override
  State<_HedefConfettiLayer> createState() => _HedefConfettiLayerState();
}

class _HedefConfettiLayerState extends State<_HedefConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _spawnParticles(widget.colors, widget.isDark);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            t: Curves.easeOutCubic.transform(_controller.value),
            fade: (1.0 - _controller.value * 0.92).clamp(0.0, 1.0),
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

List<_Particle> _spawnParticles(AppColors colors, bool isDark) {
  final rng = math.Random();
  final palette = <Color>[
    colors.indigo,
    colors.emerald,
    const Color(0xFFC4B5FD), // soft purple, matches section palette
    isDark ? const Color(0xFFFAF7F2) : const Color(0xFFF5F5F4),
    colors.textMuted.withValues(alpha: isDark ? 0.85 : 0.7),
  ];

  // Three wide burst origins so particles cover most of the viewport,
  // not a tiny center sparkle — still calm velocities / soft palette.
  const origins = <(double, double)>[
    (0.18, 0.32),
    (0.50, 0.26),
    (0.82, 0.32),
  ];

  return [
    for (var i = 0; i < 108; i++)
      () {
        final origin = origins[i % origins.length];
        final jitterX = (rng.nextDouble() - 0.5) * 0.14;
        final jitterY = (rng.nextDouble() - 0.5) * 0.10;
        return _Particle(
          originX: (origin.$1 + jitterX).clamp(0.05, 0.95),
          originY: (origin.$2 + jitterY).clamp(0.12, 0.48),
          vx: (rng.nextDouble() - 0.5) * 1.85,
          vy: -0.65 - rng.nextDouble() * 0.75,
          gravity: 1.05 + rng.nextDouble() * 0.55,
          size: 3.5 + rng.nextDouble() * 5.5,
          rotation: rng.nextDouble() * math.pi,
          spin: (rng.nextDouble() - 0.5) * 4.2,
          color: palette[rng.nextInt(palette.length)],
          rect: rng.nextBool(),
        );
      }(),
  ];
}

class _Particle {
  const _Particle({
    required this.originX,
    required this.originY,
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.size,
    required this.rotation,
    required this.spin,
    required this.color,
    required this.rect,
  });

  final double originX;
  final double originY;
  final double vx;
  final double vy;
  final double gravity;
  final double size;
  final double rotation;
  final double spin;
  final Color color;
  final bool rect;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.particles,
    required this.t,
    required this.fade,
  });

  final List<_Particle> particles;
  final double t;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..style = PaintingStyle.fill;
    final opacity = (fade * 1.05).clamp(0.0, 1.0);

    for (final p in particles) {
      final x = (p.originX + p.vx * t) * size.width;
      final y = (p.originY + p.vy * t + 0.5 * p.gravity * t * t) * size.height;
      if (y > size.height + 20 || x < -20 || x > size.width + 20) continue;

      paint.color = p.color.withValues(alpha: opacity * p.color.a);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.spin * t);
      if (p.rect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            const Radius.circular(1.2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.42, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.fade != fade;
  }
}
