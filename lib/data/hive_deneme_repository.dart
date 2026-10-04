import 'dart:convert';

import 'package:deneme_takip/domain/app_settings.dart';
import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class DenemeRepository {
  AppSettings loadSettings();

  Future<void> saveSettings(AppSettings settings);

  List<DenemeEntry> loadEntries();

  Future<void> saveEntry(DenemeEntry entry);

  Future<void> deleteEntry(String id);
}

class HiveDenemeRepository implements DenemeRepository {
  HiveDenemeRepository(this._settings, this._entries);

  static const _settingsKey = 'settings';

  final Box<String> _settings;
  final Box<String> _entries;

  static Future<HiveDenemeRepository> open() async {
    await Hive.initFlutter();
    final settings = await Hive.openBox<String>('settings');
    final entries = await Hive.openBox<String>('entries');
    return HiveDenemeRepository(settings, entries);
  }

  @override
  AppSettings loadSettings() {
    final raw = _settings.get(_settingsKey);
    if (raw == null) return AppSettings.defaults();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return AppSettings.defaults();
      return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
    } on Object {
      return AppSettings.defaults();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) {
    return _settings.put(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  List<DenemeEntry> loadEntries() {
    final loaded = <DenemeEntry>[];
    for (final raw in _entries.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        loaded.add(DenemeEntry.fromJson(Map<String, dynamic>.from(decoded)));
      } on Object {
        continue;
      }
    }
    return loaded;
  }

  @override
  Future<void> saveEntry(DenemeEntry entry) {
    return _entries.put(entry.id, jsonEncode(entry.toJson()));
  }

  @override
  Future<void> deleteEntry(String id) {
    return _entries.delete(id);
  }
}
