import 'package:deneme_takip/data/hive_deneme_repository.dart';
import 'package:deneme_takip/domain/app_settings.dart';
import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/domain/istanbul_time.dart';
import 'package:deneme_takip/domain/streak.dart';
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

  Future<void> completeOnboarding(String examTypeId) async {
    final next = state.copyWith(onboarded: true, activeExamTypeId: examTypeId);
    await ref.read(denemeRepositoryProvider).saveSettings(next);
    state = next;
  }

  Future<void> setActiveExam(String examTypeId) async {
    if (state.activeExamTypeId == examTypeId) return;
    final next = state.copyWith(activeExamTypeId: examTypeId);
    await ref.read(denemeRepositoryProvider).saveSettings(next);
    state = next;
  }

  Future<void> setTarget(String examTypeId, double target) async {
    if (!target.isFinite || target < 0) return;
    final targets = Map<String, double>.from(state.targetNets);
    targets[examTypeId] = target;
    final next = state.copyWith(targetNets: targets);
    await ref.read(denemeRepositoryProvider).saveSettings(next);
    state = next;
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
  return ExamRegistry.byId(id);
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

final streakProvider = Provider<int>((ref) {
  final entries = ref.watch(activeEntriesProvider);
  return weeklyStreak([
    for (final entry in entries) entry.date,
  ], today: istanbulToday());
});
