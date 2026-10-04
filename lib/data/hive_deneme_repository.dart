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
  HiveDenemeRepository(this._box);

  static const _settingsKey = 'settings';
  static const _entriesKey = 'entries';

  final Box<String> _box;

  static Future<HiveDenemeRepository> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>('deneme');
    return HiveDenemeRepository(box);
  }

  @override
  AppSettings loadSettings() {
    final raw = _box.get(_settingsKey);
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
  Future<void> saveSettings(AppSettings settings) async {
    _remember(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  List<DenemeEntry> loadEntries() {
    final raw = _box.get(_entriesKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final loaded = <DenemeEntry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          loaded.add(DenemeEntry.fromJson(Map<String, dynamic>.from(item)));
        } on Object {
          continue;
        }
      }
      return loaded;
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> saveEntry(DenemeEntry entry) async {
    final next = [
      for (final existing in loadEntries())
        if (existing.id != entry.id) existing,
      entry,
    ];
    _remember(
      _entriesKey,
      jsonEncode([for (final item in next) item.toJson()]),
    );
  }

  @override
  Future<void> deleteEntry(String id) async {
    final next = [
      for (final existing in loadEntries())
        if (existing.id != id) existing,
    ];
    _remember(
      _entriesKey,
      jsonEncode([for (final item in next) item.toJson()]),
    );
  }

  /// Hive updates its in-memory keystore before the IndexedDB request
  /// resolves. On web that request can stay pending forever, which would
  /// freeze the save button if we awaited it. The write is still issued.
  void _remember(String key, String value) {
    _box.put(key, value).ignore();
  }
}
