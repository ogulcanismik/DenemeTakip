import 'dart:async';
import 'dart:developer' as developer;

import 'package:deneme_takip/ads/ad_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preloads and presents interstitial ads before the Analiz tab opens.
class AdService {
  AdService({
    required this.isSupporter,
    this.prefs,
  });

  static const _lastShownKey = 'last_ad_shown_timestamp';
  static const _frequencyCap = Duration(hours: 12);
  static const _maxBackoff = Duration(minutes: 5);

  final bool Function() isSupporter;
  SharedPreferences? prefs;

  InterstitialAd? _interstitialAd;
  var _loading = false;
  var _initialized = false;
  Duration _backoff = const Duration(seconds: 2);
  Timer? _retryTimer;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      prefs ??= await SharedPreferences.getInstance();
      await MobileAds.instance.initialize();
      preloadInterstitialAd();
    } on Object catch (error, stack) {
      developer.log(
        'AdMob initialize failed: $error',
        name: 'AdService',
        error: error,
        stackTrace: stack,
      );
    }
  }

  void preloadInterstitialAd() {
    if (kIsWeb) return;
    if (_loading || _interstitialAd != null) return;
    if (isSupporter()) return;

    _loading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _interstitialAd = ad;
          _backoff = const Duration(seconds: 2);
          _retryTimer?.cancel();
          _retryTimer = null;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          _interstitialAd = null;
          developer.log(
            'Interstitial load failed: ${error.message}',
            name: 'AdService',
          );
          _scheduleRetry();
        },
      ),
    );
  }

  Future<bool> canShowAd() async {
    if (kIsWeb) return false;
    if (isSupporter()) return false;
    if (_interstitialAd == null) return false;

    final store = prefs ??= await SharedPreferences.getInstance();
    final lastMs = store.getInt(_lastShownKey);
    if (lastMs == null) return true;

    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastMs),
    );
    return elapsed >= _frequencyCap;
  }

  /// Shows a preloaded interstitial when allowed; never hangs the caller.
  ///
  /// Invokes [onDismissed] when the ad is closed, fails to show, or is skipped.
  /// Returns whether an interstitial was actually presented.
  Future<bool> showInterstitialWithFallback({
    required void Function(bool adWasShown) onDismissed,
  }) async {
    try {
      final allowed = await canShowAd();
      final ad = _interstitialAd;
      if (!allowed || ad == null) {
        onDismissed(false);
        return false;
      }

      final completer = Completer<bool>();
      var finished = false;

      void finish(bool shown) {
        if (finished) return;
        finished = true;
        onDismissed(shown);
        if (!completer.isCompleted) completer.complete(shown);
        preloadInterstitialAd();
      }

      _interstitialAd = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) async {
          try {
            final store = prefs ??= await SharedPreferences.getInstance();
            await store.setInt(
              _lastShownKey,
              DateTime.now().millisecondsSinceEpoch,
            );
          } on Object catch (error) {
            developer.log(
              'Failed to persist ad timestamp: $error',
              name: 'AdService',
            );
          }
        },
        onAdDismissedFullScreenContent: (dismissed) {
          dismissed.dispose();
          finish(true);
        },
        onAdFailedToShowFullScreenContent: (failed, error) {
          failed.dispose();
          developer.log(
            'Interstitial show failed: ${error.message}',
            name: 'AdService',
          );
          finish(false);
        },
      );

      try {
        await ad.show();
      } on Object catch (error) {
        ad.dispose();
        developer.log(
          'Interstitial show threw: $error',
          name: 'AdService',
        );
        finish(false);
      }

      return await completer.future;
    } on Object catch (error, stack) {
      developer.log(
        'showInterstitialWithFallback error: $error',
        name: 'AdService',
        error: error,
        stackTrace: stack,
      );
      onDismissed(false);
      return false;
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  void _scheduleRetry() {
    if (isSupporter()) return;
    _retryTimer?.cancel();
    final delay = _backoff;
    _backoff = Duration(
      milliseconds: (_backoff.inMilliseconds * 2).clamp(
        const Duration(seconds: 2).inMilliseconds,
        _maxBackoff.inMilliseconds,
      ),
    );
    _retryTimer = Timer(delay, preloadInterstitialAd);
  }
}
