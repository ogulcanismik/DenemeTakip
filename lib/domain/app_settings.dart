import 'package:deneme_takip/domain/exam_registry.dart';

class AppSettings {
  const AppSettings({
    required this.onboarded,
    required this.activeExamTypeId,
    required this.enabledExamTypeIds,
    required this.targetNets,
  });

  final bool onboarded;
  final String? activeExamTypeId;
  final List<String> enabledExamTypeIds;
  final Map<String, double> targetNets;

  static AppSettings defaults() {
    return AppSettings(
      onboarded: false,
      activeExamTypeId: null,
      enabledExamTypeIds: const [],
      targetNets: {
        for (final exam in ExamRegistry.all) exam.id: exam.defaultTargetNet,
      },
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
    bool clearActiveExam = false,
  }) {
    return AppSettings(
      onboarded: onboarded ?? this.onboarded,
      activeExamTypeId: clearActiveExam
          ? null
          : (activeExamTypeId ?? this.activeExamTypeId),
      enabledExamTypeIds: enabledExamTypeIds ?? this.enabledExamTypeIds,
      targetNets: targetNets ?? this.targetNets,
    );
  }

  Map<String, dynamic> toJson() => {
    'onboarded': onboarded,
    'activeExamTypeId': activeExamTypeId,
    'enabledExamTypeIds': enabledExamTypeIds,
    'targets': targetNets,
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
    );
  }
}
