import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/screens/onboarding_screen.dart';
import 'package:deneme_takip/ui/screens/shell_screen.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DenemeApp extends ConsumerWidget {
  const DenemeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final exam = ref.watch(activeExamProvider);
    final ready = settings.onboarded && exam != null;

    return MaterialApp(
      title: 'Deneme Takip',
      debugShowCheckedModeBanner: false,
      theme: buildDenemeLightTheme(),
      darkTheme: buildDenemeDarkTheme(),
      themeMode: settings.themeMode.material,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ready ? const ShellScreen() : const OnboardingScreen(),
    );
  }
}
