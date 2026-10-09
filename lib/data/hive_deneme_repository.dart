import 'dart:convert';

import 'package:deneme_takip/domain/app_settings.dart';
import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_migration.dart';
import 'package:deneme_takip/domain/exam_registry.dart';
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
  AppSettings? _settingsCache;
  List<DenemeEntry>? _entriesCache;

  static Future<HiveDenemeRepository> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>('deneme');
    final repo = HiveDenemeRepository(box);
    repo._migratePersisted();
    return repo;
  }

  void _migratePersisted() {
    final settings = loadSettings();
    final entries = loadEntries();
    // load* already migrates into caches; persist if raw differed.
    final rawSettings = _box.get(_settingsKey);
    final rawEntries = _box.get(_entriesKey);
    if (rawSettings != null) {
      try {
        final decoded = jsonDecode(rawSettings);
        if (decoded is Map) {
          final before = AppSettings.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          if (ExamMigration.settingsNeedRewrite(before, settings)) {
            saveSettings(settings);
          }
        }
      } on Object {
        // keep migrated cache
      }
    }
    if (rawEntries != null) {
      try {
        final decoded = jsonDecode(rawEntries);
        if (decoded is List) {
          final before = <DenemeEntry>[];
          for (final item in decoded) {
            if (item is! Map) continue;
            try {
              before.add(DenemeEntry.fromJson(Map<String, dynamic>.from(item)));
            } on Object {
              continue;
            }
          }
          if (ExamMigration.entriesNeedRewrite(before, entries)) {
            _remember(
              _entriesKey,
              jsonEncode([for (final item in entries) item.toJson()]),
            );
            _entriesCache = entries;
          }
        }
      } on Object {
        // keep migrated cache
      }
    }
  }

  @override
  AppSettings loadSettings() {
    if (_settingsCache != null) return _settingsCache!;
    final raw = _box.get(_settingsKey);
    if (raw == null) {
      _settingsCache = _rememberCustoms(AppSettings.defaults());
      return _settingsCache!;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _settingsCache = _rememberCustoms(AppSettings.defaults());
        return _settingsCache!;
      }
      final loaded = AppSettings.fromJson(Map<String, dynamic>.from(decoded));
      ExamRegistry.setCustomExams(loaded.customExams);
      _settingsCache = _rememberCustoms(ExamMigration.migrateSettings(loaded));
      return _settingsCache!;
    } on Object {
      _settingsCache = _rememberCustoms(AppSettings.defaults());
      return _settingsCache!;
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settingsCache = _rememberCustoms(settings);
    _remember(_settingsKey, jsonEncode(settings.toJson()));
  }

  AppSettings _rememberCustoms(AppSettings settings) {
    ExamRegistry.setCustomExams(settings.customExams);
    return settings;
  }

  @override
  List<DenemeEntry> loadEntries() {
    if (_entriesCache != null) return _entriesCache!;
    final raw = _box.get(_entriesKey);
    if (raw == null) {
      _entriesCache = const [];
      return _entriesCache!;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _entriesCache = const [];
        return _entriesCache!;
      }
      final loaded = <DenemeEntry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          loaded.add(
            ExamMigration.migrateEntry(
              DenemeEntry.fromJson(Map<String, dynamic>.from(item)),
            ),
          );
        } on Object {
          continue;
        }
      }
      _entriesCache = loaded;
      return loaded;
    } on Object {
      _entriesCache = const [];
      return _entriesCache!;
    }
  }

  @override
  Future<void> saveEntry(DenemeEntry entry) async {
    final next = [
      for (final existing in loadEntries())
        if (existing.id != entry.id) existing,
      entry,
    ];
    _entriesCache = next;
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
    _entriesCache = next;
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
