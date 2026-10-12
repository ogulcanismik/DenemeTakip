import 'package:deneme_takip/ads/billing_service.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calm indie-dev note after an interstitial. Purchase unlocks isSupporter.
Future<void> showSupporterUpsellSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SupporterUpsellSheet(),
  );
}

class _SupporterUpsellSheet extends ConsumerStatefulWidget {
  const _SupporterUpsellSheet();

  @override
  ConsumerState<_SupporterUpsellSheet> createState() =>
      _SupporterUpsellSheetState();
}

class _SupporterUpsellSheetState extends ConsumerState<_SupporterUpsellSheet> {
  var _busy = false;

  Future<void> _buy() async {
    if (_busy) return;
    setState(() => _busy = true);
    final billing = ref.read(billingServiceProvider);
    final result = await billing.purchaseSupporter();
    if (!mounted) return;
    setState(() => _busy = false);

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (result == BillingActionResult.success) {
      Navigator.of(context).pop();
      messenger?.showSnackBar(
        SnackBar(content: Text(result.messageTr)),
      );
      return;
    }
    if (result == BillingActionResult.cancelled) return;
    messenger?.showSnackBar(
      SnackBar(content: Text(result.messageTr)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always the calm dark note from the monetisation prompt, independent of
    // the active app theme mode.
    const colors = AppColors.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final price = ref.watch(billingServiceProvider).supporterPriceLabel;

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
                'tek seferlik $price katkıyla hem reklamsız deneyime geçebilir '
                'hem de uygulamanın gelişimine destek olabilirsin.',
                style: TextStyle(
                  color: colors.textMuted,
                  height: 1.45,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _busy ? null : _buy,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.indigo,
                  foregroundColor: colors.text,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(
                  _busy ? 'Satın alma açılıyor…' : '$price ile Reklamları Kaldır',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
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
