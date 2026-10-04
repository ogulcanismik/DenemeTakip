import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExamListSettingsScreen extends ConsumerStatefulWidget {
  const ExamListSettingsScreen({super.key});

  @override
  ConsumerState<ExamListSettingsScreen> createState() =>
      _ExamListSettingsScreenState();
}

class _ExamListSettingsScreenState
    extends ConsumerState<ExamListSettingsScreen> {
  late Set<String> _selected;
  var _saving = false;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(
      ref.read(settingsProvider).enabledExamTypeIds,
    );
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      setState(() => _hint = 'En az bir sınav açık kalmalı.');
      return;
    }
    setState(() {
      _saving = true;
      _hint = null;
    });
    await ref
        .read(settingsProvider.notifier)
        .setEnabledExams(_selected.toList());
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sınav listesini düzenle')),
      body: AppFrame(
        maxWidth: 560,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  const Text(
                    'Diğer sınavlar',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kapattığın sınavlar üst çubukta görünmez. Kayıtlı denemeler silinmez; tekrar açınca geçmiş yerinde kalır.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final exam in ExamRegistry.all) ...[
                    _ExamToggleTile(
                      exam: exam,
                      selected: _selected.contains(exam.id),
                      onToggle: () {
                        setState(() {
                          if (_selected.contains(exam.id)) {
                            _selected.remove(exam.id);
                          } else {
                            _selected.add(exam.id);
                          }
                          _hint = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_hint != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _hint!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.amber),
                      ),
                    ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamToggleTile extends StatelessWidget {
  const _ExamToggleTile({
    required this.exam,
    required this.selected,
    required this.onToggle,
  });

  final ExamType exam;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.indigo.withValues(alpha: 0.18)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: selected ? AppColors.indigo : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exam.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
