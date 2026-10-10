import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';

/// Calm Duolingo-style popup when a save beats (or ties) form net.
///
/// No action buttons — dismiss via barrier tap or system back only.
/// Never blocks Özet navigation after a successful save.
Future<void> celebrateFormBeat(
  BuildContext context, {
  required int streak,
}) async {
  if (streak < 1) return;
  try {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _FormBeatDialog(streak: streak),
    );
  } on Object {
    // Never block Özet navigation after a successful save.
  }
}

class _FormBeatDialog extends StatelessWidget {
  const _FormBeatDialog({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.indigo.withValues(alpha: isDark ? 0.35 : 0.22),
                    colors.emerald.withValues(alpha: isDark ? 0.12 : 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 40,
                color: colors.indigo,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Netlerini Yükselttin!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$streak',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.emerald,
                fontWeight: FontWeight.w700,
                fontSize: 48,
                height: 1.0,
                letterSpacing: -1,
              ).data,
            ),
            const SizedBox(height: 6),
            Text(
              'form serisi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
