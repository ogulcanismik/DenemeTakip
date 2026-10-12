import 'package:deneme_takip/data/hive_deneme_repository.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await HiveDenemeRepository.open();
  final container = ProviderContainer(
    overrides: [denemeRepositoryProvider.overrideWithValue(repository)],
  );
  // Live isSupporter via settingsProvider; failures stay inside each service.
  await container.read(adServiceProvider).initialize();
  await container.read(billingServiceProvider).initialize();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DenemeApp(),
    ),
  );
}
