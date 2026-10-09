import 'package:deneme_takip/data/hive_deneme_repository.dart';
import 'package:deneme_takip/domain/app_settings.dart';
import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final denemeRepositoryProvider = Provider<DenemeRepository>((ref) {
  throw StateError('DenemeRepository sağlanmadı.');
});

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(denemeRepositoryProvider).loadSettings();

  Future<void> completeOnboarding(List<String> enabledExamTypeIds) async {
    final enabled = _sanitizeEnabled(enabledExamTypeIds);
    if (enabled.isEmpty) return;
    final next = state.copyWith(
      onboarded: true,
      enabledExamTypeIds: enabled,
      activeExamTypeId: enabled.first,
    );
    await _persist(next);
  }

  Future<void> setActiveExam(String examTypeId) async {
    if (!state.isEnabled(examTypeId)) return;
    if (state.activeExamTypeId == examTypeId) return;
    final next = state.copyWith(activeExamTypeId: examTypeId);
    await _persist(next);
  }

  Future<void> setEnabledExams(List<String> enabledExamTypeIds) async {
    final enabled = _sanitizeEnabled(enabledExamTypeIds);
    if (enabled.isEmpty) return;

    var active = state.activeExamTypeId;
    if (active == null || !enabled.contains(active)) {
      active = enabled.first;
    }

    final next = state.copyWith(
      enabledExamTypeIds: enabled,
      activeExamTypeId: active,
    );
    await _persist(next);
  }

  Future<void> setTarget(String examTypeId, double target) async {
    if (!target.isFinite || target < 0) return;
    final targets = Map<String, double>.from(state.targetNets);
    targets[examTypeId] = target;
    final next = state.copyWith(targetNets: targets);
    await _persist(next);
  }

  Future<void> setThemeMode(AppThemeMode themeMode) async {
    if (state.themeMode == themeMode) return;
    final next = state.copyWith(themeMode: themeMode);
    await _persist(next);
  }

  /// Creates or updates a user-defined exam and enables it in the switcher.
  Future<void> upsertCustomExam(ExamType exam) async {
    if (!exam.isCustom || exam.id.isEmpty) return;
    if (exam.sections.isEmpty) return;

    final customs = [...state.customExams];
    final index = customs.indexWhere((item) => item.id == exam.id);
    if (index >= 0) {
      customs[index] = exam;
    } else {
      customs.add(exam);
    }

    final targets = Map<String, double>.from(state.targetNets);
    // Keep hedef net aligned with the builder value on create/edit.
    targets[exam.id] = exam.defaultTargetNet;

    ExamRegistry.setCustomExams(customs);
    final enabled = _sanitizeEnabled([...state.enabledExamTypeIds, exam.id]);
    final resolvedEnabled = enabled.isEmpty ? [exam.id] : enabled;
    var active = state.activeExamTypeId;
    if (active == null || !resolvedEnabled.contains(active)) {
      active = resolvedEnabled.first;
    }

    final next = state.copyWith(
      customExams: customs,
      targetNets: targets,
      enabledExamTypeIds: resolvedEnabled,
      activeExamTypeId: active,
    );
    await _persist(next);
  }

  /// Removes a custom exam from the catalog. Past denemeler for that id are
  /// kept; detail view falls back when the config is gone.
  /// Returns false if this is the last enabled exam (app must keep ≥1).
  Future<bool> deleteCustomExam(String examTypeId) async {
    if (!ExamRegistry.isCustomId(examTypeId)) return false;
    if (!state.customExams.any((exam) => exam.id == examTypeId)) return false;

    final customs = [
      for (final exam in state.customExams)
        if (exam.id != examTypeId) exam,
    ];

    // Temporarily sync so sanitize still resolves remaining customs.
    ExamRegistry.setCustomExams(customs);

    final enabled = _sanitizeEnabled([
      for (final id in state.enabledExamTypeIds)
        if (id != examTypeId) id,
    ]);
    if (enabled.isEmpty) {
      // Restore overlay; caller should keep ≥1 exam enabled.
      ExamRegistry.setCustomExams(state.customExams);
      return false;
    }

    var active = state.activeExamTypeId;
    if (active == null || !enabled.contains(active)) {
      active = enabled.first;
    }

    final targets = Map<String, double>.from(state.targetNets)
      ..remove(examTypeId);

    final next = state.copyWith(
      customExams: customs,
      enabledExamTypeIds: enabled,
      activeExamTypeId: active,
      targetNets: targets,
    );
    await _persist(next);
    return true;
  }

  Future<void> _persist(AppSettings next) async {
    ExamRegistry.setCustomExams(next.customExams);
    await ref.read(denemeRepositoryProvider).saveSettings(next);
    state = next;
  }

  List<String> _sanitizeEnabled(Iterable<String> ids) {
    final seen = <String>{};
    final result = <String>[];
    for (final id in ids) {
      if (ExamRegistry.byId(id) == null) continue;
      if (!seen.add(id)) continue;
      result.add(id);
    }
    return result;
  }
}

final entriesProvider = NotifierProvider<EntriesNotifier, List<DenemeEntry>>(
  EntriesNotifier.new,
);

class EntriesNotifier extends Notifier<List<DenemeEntry>> {
  @override
  List<DenemeEntry> build() => ref.read(denemeRepositoryProvider).loadEntries();

  Future<void> add(DenemeEntry entry) async {
    await ref.read(denemeRepositoryProvider).saveEntry(entry);
    state = [
      for (final existing in state)
        if (existing.id != entry.id) existing,
      entry,
    ];
  }

  Future<void> delete(String id) async {
    await ref.read(denemeRepositoryProvider).deleteEntry(id);
    state = ref.read(denemeRepositoryProvider).loadEntries();
  }
}

final activeExamProvider = Provider<ExamType?>((ref) {
  final id = ref.watch(settingsProvider).activeExamTypeId;
  if (id == null) return null;
  // Watch customExams so lookups refresh after create/edit/delete.
  ref.watch(settingsProvider.select((s) => s.customExams));
  return ExamRegistry.byId(id);
});

final enabledExamsProvider = Provider<List<ExamType>>((ref) {
  final settings = ref.watch(settingsProvider);
  return ExamRegistry.enabledOf(settings.enabledExamTypeIds);
});

final activeEntriesProvider = Provider<List<DenemeEntry>>((ref) {
  final exam = ref.watch(activeExamProvider);
  if (exam == null) return const [];
  final filtered = [
    for (final entry in ref.watch(entriesProvider))
      if (entry.examTypeId == exam.id) entry,
  ];
  filtered.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return b.id.compareTo(a.id);
  });
  return filtered;
});
