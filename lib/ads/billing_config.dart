/// Play Billing product IDs for DenemeTakip.
///
/// TODO(production): Create a matching one-time **non-consumable** in-app
/// product in Google Play Console with this exact Product ID, then leave the
/// constant as-is (or rename both sides together). Do not invent live
/// license/API keys here — Play Billing uses the signed Play Store build.
class BillingConfig {
  const BillingConfig._();

  /// One-time “Destekçi” / remove-ads unlock.
  ///
  /// Play Console → Monetize → In-app products → Create product:
  /// - Product ID: `destekci_reklamsiz`
  /// - Type: Non-consumable (managed product / one-time)
  /// - Suggested price: 50 ₺ (set in Console; UI copy mentions 50 ₺)
  static const String supporterProductId = 'destekci_reklamsiz';
}
