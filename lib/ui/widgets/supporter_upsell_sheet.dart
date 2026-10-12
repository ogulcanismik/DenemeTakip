import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';

/// Calm indie-dev note after an interstitial. Purchase CTA is a placeholder
/// until Play Billing is wired.
Future<void> showSupporterUpsellSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SupporterUpsellSheet(),
  );
}

class _SupporterUpsellSheet extends StatelessWidget {
  const _SupporterUpsellSheet();

  @override
  Widget build(BuildContext context) {
    // Always the calm dark note from the monetisation prompt, independent of
    // the active app theme mode.
    const colors = AppColors.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Reklamsız Çalışmak İster Misin?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Denemelerine odaklanırken araya reklam girmesini istemiyorsan '
                'tek seferlik 50 ₺ katkıyla hem reklamsız deneyime geçebilir '
                'hem de uygulamanın gelişimine destek olabilirsin.',
                style: TextStyle(
                  color: colors.textMuted,
                  height: 1.45,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {
                  // TODO: Wire Play Billing one-time 50 ₺ purchase, then
                  // settingsProvider.setSupporter(true).
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  Navigator.of(context).pop();
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Satın alma yakında. Şimdilik teşekkürler!',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.indigo,
                  foregroundColor: colors.text,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('50 ₺ ile Reklamları Kaldır'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: colors.textMuted,
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('Şimdilik Geç'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
