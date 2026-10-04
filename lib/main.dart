import 'package:deneme_takip/data/hive_deneme_repository.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await HiveDenemeRepository.open();
  runApp(
    ProviderScope(
      overrides: [denemeRepositoryProvider.overrideWithValue(repository)],
      child: const DenemeApp(),
    ),
  );
}
