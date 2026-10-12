import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimal first-run welcome shown once before exam onboarding.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _continue(WidgetRef ref) async {
    await ref.read(settingsProvider.notifier).markWelcomeSeen();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: AppFrame(
          maxWidth: 480,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Text(
                  'Deneme Takip',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Denemelerini sakin bir yerde tut.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: colors.textMuted,
                    height: 1.45,
                  ),
                ),
                const Spacer(flex: 3),
                FilledButton(
                  onPressed: () => _continue(ref),
                  child: const Text('Başla'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
