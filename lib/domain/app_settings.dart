import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:flutter/material.dart';

enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode parse(Object? raw) {
    switch (raw) {
      case 'light':
        return AppThemeMode.light;
      case 'system':
        return AppThemeMode.system;
      case 'dark':
      default:
        return AppThemeMode.dark;
    }
  }

  String get storageValue => name;

  ThemeMode get material => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  String get labelTr => switch (this) {
    AppThemeMode.system => 'Sistem',
    AppThemeMode.light => 'Açık',
    AppThemeMode.dark => 'Koyu',
  };
}

class AppSettings {
  const AppSettings({
    required this.onboarded,
    required this.activeExamTypeId,
    required this.enabledExamTypeIds,
    required this.targetNets,
    this.themeMode = AppThemeMode.dark,
  });

  final bool onboarded;
  final String? activeExamTypeId;
  final List<String> enabledExamTypeIds;
  final Map<String, double> targetNets;
  final AppThemeMode themeMode;

  static AppSettings defaults() {
    return AppSettings(
      onboarded: false,
      activeExamTypeId: null,
      enabledExamTypeIds: const [],
      targetNets: {
        for (final exam in ExamRegistry.all) exam.id: exam.defaultTargetNet,
      },
      themeMode: AppThemeMode.dark,
    );
  }

  bool isEnabled(String examTypeId) => enabledExamTypeIds.contains(examTypeId);

  double targetFor(String examTypeId) {
    return targetNets[examTypeId] ??
        ExamRegistry.byId(examTypeId)?.defaultTargetNet ??
        0;
  }

  AppSettings copyWith({
    bool? onboarded,
    String? activeExamTypeId,
    List<String>? enabledExamTypeIds,
    Map<String, double>? targetNets,
    AppThemeMode? themeMode,
    bool clearActiveExam = false,
  }) {
    return AppSettings(
      onboarded: onboarded ?? this.onboarded,
      activeExamTypeId: clearActiveExam
          ? null
          : (activeExamTypeId ?? this.activeExamTypeId),
      enabledExamTypeIds: enabledExamTypeIds ?? this.enabledExamTypeIds,
      targetNets: targetNets ?? this.targetNets,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'onboarded': onboarded,
    'activeExamTypeId': activeExamTypeId,
    'enabledExamTypeIds': enabledExamTypeIds,
    'targets': targetNets,
    'themeMode': themeMode.storageValue,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final targets = Map<String, double>.from(defaults().targetNets);
    final rawTargets = json['targets'];
    if (rawTargets is Map) {
      for (final entry in rawTargets.entries) {
        final value = entry.value;
        if (value is num && value.isFinite) {
          targets[entry.key.toString()] = value.toDouble();
        }
      }
    }

    final enabled = <String>[];
    final rawEnabled = json['enabledExamTypeIds'];
    if (rawEnabled is List) {
      for (final item in rawEnabled) {
        if (item is String && item.isNotEmpty && !enabled.contains(item)) {
          enabled.add(item);
        }
      }
    }

    final rawExam = json['activeExamTypeId'];
    final active = rawExam is String && rawExam.isNotEmpty ? rawExam : null;

    return AppSettings(
      onboarded: json['onboarded'] == true,
      activeExamTypeId: active,
      enabledExamTypeIds: enabled,
      targetNets: targets,
      themeMode: AppThemeMode.parse(json['themeMode']),
    );
  }
}
