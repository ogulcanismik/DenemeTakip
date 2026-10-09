import 'package:deneme_takip/domain/app_settings.dart';
import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_registry.dart';

/// Maps legacy exam / section ids from the 3-exam registry onto the expanded
/// catalog so stored denemeler and settings keep opening.
abstract final class ExamMigration {
  static const examTypeIds = <String, String>{
    'yks-tyt': 'yks_tyt',
    'kpss-lisans': 'kpss_lisans',
  };

  static const sectionIdsByExam = <String, Map<String, String>>{
    'yks_tyt': {
      'turkce': 'tr',
      'sosyal': 'sos',
      'matematik': 'mat',
      // fen unchanged
    },
    'lgs': {
      'turkce': 'tr',
      'matematik': 'mat',
      // fen, din unchanged
      'inkilap': 'ink',
      'yabanci': 'dil',
    },
    // Old KPSS used gy/gk aggregates; new catalog is subject-level. Keep old
    // section ids as-is so history still opens (detail falls back to id text).
  };

  static String migrateExamTypeId(String id) => examTypeIds[id] ?? id;

  static String migrateSectionId(String examTypeId, String sectionId) {
    final map = sectionIdsByExam[examTypeId];
    if (map == null) return sectionId;
    return map[sectionId] ?? sectionId;
  }

  static AppSettings migrateSettings(AppSettings settings) {
    // Customs must already be synced onto ExamRegistry before this runs.
    final migratedTargets = <String, double>{
      for (final exam in ExamRegistry.all) exam.id: exam.defaultTargetNet,
    };
    for (final entry in settings.targetNets.entries) {
      final id = migrateExamTypeId(entry.key);
      migratedTargets[id] = entry.value;
    }

    final active = settings.activeExamTypeId == null
        ? null
        : migrateExamTypeId(settings.activeExamTypeId!);

    var enabled = [
      for (final id in settings.enabledExamTypeIds) migrateExamTypeId(id),
    ];
    enabled = [
      for (final id in enabled)
        if (ExamRegistry.byId(id) != null) id,
    ];

    // Older builds only stored a single active exam.
    if (enabled.isEmpty && active != null && ExamRegistry.byId(active) != null) {
      enabled = [active];
    }

    final nextActive = active != null && enabled.contains(active)
        ? active
        : (enabled.isEmpty ? null : enabled.first);

    return AppSettings(
      onboarded: settings.onboarded && nextActive != null,
      activeExamTypeId: nextActive,
      enabledExamTypeIds: enabled,
      targetNets: migratedTargets,
      customExams: settings.customExams,
      themeMode: settings.themeMode,
    );
  }

  static DenemeEntry migrateEntry(DenemeEntry entry) {
    final examTypeId = migrateExamTypeId(entry.examTypeId);
    return DenemeEntry(
      id: entry.id,
      examTypeId: examTypeId,
      title: entry.title,
      date: entry.date,
      durationMinutes: entry.durationMinutes,
      difficultyRating: entry.difficultyRating,
      sections: [
        for (final section in entry.sections)
          SectionScore(
            sectionId: migrateSectionId(examTypeId, section.sectionId),
            correctCount: section.correctCount,
            incorrectCount: section.incorrectCount,
            emptyCount: section.emptyCount,
            calculatedNet: section.calculatedNet,
          ),
      ],
      totalNet: entry.totalNet,
    );
  }

  static bool settingsNeedRewrite(AppSettings before, AppSettings after) {
    if (before.onboarded != after.onboarded) return true;
    if (before.activeExamTypeId != after.activeExamTypeId) return true;
    if (!_sameStringList(before.enabledExamTypeIds, after.enabledExamTypeIds)) {
      return true;
    }
    if (before.themeMode != after.themeMode) return true;
    if (before.targetNets.length != after.targetNets.length) return true;
    for (final entry in after.targetNets.entries) {
      if (before.targetNets[entry.key] != entry.value) return true;
    }
    return false;
  }

  static bool entriesNeedRewrite(
    List<DenemeEntry> before,
    List<DenemeEntry> after,
  ) {
    if (before.length != after.length) return true;
    for (var i = 0; i < before.length; i++) {
      final a = before[i];
      final b = after[i];
      if (a.examTypeId != b.examTypeId) return true;
      if (a.sections.length != b.sections.length) return true;
      for (var j = 0; j < a.sections.length; j++) {
        if (a.sections[j].sectionId != b.sections[j].sectionId) return true;
      }
    }
    return false;
  }

  static bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
