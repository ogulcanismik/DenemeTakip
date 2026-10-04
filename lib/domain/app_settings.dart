import 'package:deneme_takip/domain/exam_registry.dart';

class AppSettings {
  const AppSettings({
    required this.onboarded,
    required this.activeExamTypeId,
    required this.targetNets,
  });

  final bool onboarded;
  final String? activeExamTypeId;
  final Map<String, double> targetNets;

  static AppSettings defaults() {
    return AppSettings(
      onboarded: false,
      activeExamTypeId: null,
      targetNets: {
        for (final exam in ExamRegistry.all) exam.id: exam.defaultTargetNet,
      },
    );
  }

  double targetFor(String examTypeId) {
    return targetNets[examTypeId] ??
        ExamRegistry.byId(examTypeId)?.defaultTargetNet ??
        0;
  }

  AppSettings copyWith({
    bool? onboarded,
    String? activeExamTypeId,
    Map<String, double>? targetNets,
  }) {
    return AppSettings(
      onboarded: onboarded ?? this.onboarded,
      activeExamTypeId: activeExamTypeId ?? this.activeExamTypeId,
      targetNets: targetNets ?? this.targetNets,
    );
  }

  Map<String, dynamic> toJson() => {
    'onboarded': onboarded,
    'activeExamTypeId': activeExamTypeId,
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
    final rawExam = json['activeExamTypeId'];
    return AppSettings(
      onboarded: json['onboarded'] == true,
      activeExamTypeId: rawExam is String && rawExam.isNotEmpty
          ? rawExam
          : null,
      targetNets: targets,
    );
  }
}
