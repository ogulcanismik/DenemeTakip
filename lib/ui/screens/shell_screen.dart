import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/screens/analysis_screen.dart';
import 'package:deneme_takip/ui/screens/dashboard_screen.dart';
import 'package:deneme_takip/ui/screens/entry_screen.dart';
import 'package:deneme_takip/ui/screens/exam_list_settings_screen.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:deneme_takip/ui/widgets/supporter_upsell_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  /// 0 Özet, 1 Analiz, 2 Deneme Gir
  int _tab = 2;
  int _formToken = 0;
  DateTime? _lastBackAt;
  var _openingAnaliz = false;

  /// Analiz is the only ad moment: show the interstitial (and the supporter
  /// note if one played) before switching to that tab. Other tabs switch
  /// immediately. A failed or capped ad still opens Analiz.
  Future<void> _selectTab(int index) async {
    if (_openingAnaliz || index == _tab) return;
    if (index != 1) {
      setState(() => _tab = index);
      return;
    }

    _openingAnaliz = true;
    try {
      var adWasShown = false;
      try {
        await ref.read(adServiceProvider).showInterstitialWithFallback(
          onDismissed: (shown) => adWasShown = shown,
        );
      } on Object {
        adWasShown = false;
      }
      if (!mounted) return;

      if (adWasShown && !ref.read(settingsProvider).isSupporter) {
        await showSupporterUpsellSheet(context);
        if (!mounted) return;
      }

      setState(() => _tab = 1);
    } finally {
      _openingAnaliz = false;
    }
  }

  /// Root-shell back: switch to Özet first; on Özet require a quick double-back
  /// to leave the app. Nested routes above the shell still pop normally.
  void _handleRootBack() {
    if (_tab != 0) {
      setState(() => _tab = 0);
      return;
    }

    final now = DateTime.now();
    final last = _lastBackAt;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }

    _lastBackAt = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Çıkmak için tekrar geri'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(activeExamProvider);
    if (exam == null) return const SizedBox.shrink();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
        _handleRootBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Deneme Takip'),
          actions: [
            const _ExamSwitcher(),
            IconButton(
              tooltip: 'Ayarlar',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const ExamListSettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          sizing: StackFit.expand,
          children: [
            DashboardScreen(onEnterDeneme: () => setState(() => _tab = 2)),
            const AnalysisScreen(),
            EntryScreen(
              key: ValueKey('${exam.id}:$_formToken'),
              exam: exam,
              onSaved: () => setState(() {
                _tab = 0;
                _formToken += 1;
              }),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            _selectTab(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Özet',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analiz',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(Icons.edit_note),
              label: 'Deneme Gir',
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamSwitcher extends ConsumerWidget {
  const _ExamSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeExamProvider);
    final enabled = ref.watch(enabledExamsProvider);
    if (active == null || enabled.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Sınav değiştir',
      initialValue: active.id,
      color: AppColors.of(context).surfaceHigh,
      onSelected: (id) => ref.read(settingsProvider.notifier).setActiveExam(id),
      itemBuilder: (context) {
        return [
          for (final exam in enabled)
            PopupMenuItem<String>(
              value: exam.id,
              child: Text(
                exam.name,
                style: GoogleFonts.nunito(
                  color: AppColors.of(context).text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                active.name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}
