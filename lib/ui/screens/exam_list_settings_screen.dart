import 'package:deneme_takip/domain/app_settings.dart';
import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/screens/custom_exam_builder_screen.dart';
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
    _selected = Set<String>.from(ref.read(settingsProvider).enabledExamTypeIds);
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

  Future<void> _openBuilder({ExamType? existing}) async {
    final result = await Navigator.of(context).push<ExamType>(
      MaterialPageRoute(
        builder: (context) => CustomExamBuilderScreen(existing: existing),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _selected.add(result.id);
      _hint = null;
    });
  }

  Future<void> _confirmDelete(ExamType exam) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Özel sınavı sil'),
          content: Text(
            '"${exam.name}" katalogdan kaldırılacak. Bu sınava ait eski '
            'denemeler silinmez; yalnızca yeni giriş ve listede görünmez.',
            style: TextStyle(color: colors.textMuted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(settingsProvider.notifier)
        .deleteCustomExam(exam.id);
    if (!mounted) return;
    if (!ok) {
      setState(
        () => _hint =
            'Son açık sınav silinemez. Önce başka bir sınavı aç, sonra sil.',
      );
      return;
    }
    setState(() {
      _selected.remove(exam.id);
      _hint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final settings = ref.watch(settingsProvider);
    final themeMode = settings.themeMode;
    final customs = settings.customExams;

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
                  Text(
                    'Görünüm',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AppThemeMode>(
                    segments: [
                      for (final mode in AppThemeMode.values)
                        ButtonSegment<AppThemeMode>(
                          value: mode,
                          label: Text(mode.labelTr),
                        ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (next) {
                      if (next.isEmpty) return;
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(next.first);
                    },
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.comfortable,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Diğer sınavlar',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kapattığın sınavlar üst çubukta görünmez. Kayıtlı denemeler silinmez.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _openBuilder(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Özel sınav oluştur'),
                  ),
                  const SizedBox(height: 20),
                  for (final exam in ExamRegistry.builtins) ...[
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
                  if (customs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Özel sınavlar',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final exam in customs) ...[
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
                        onEdit: () => _openBuilder(existing: exam),
                        onDelete: () => _confirmDelete(exam),
                      ),
                      const SizedBox(height: 10),
                    ],
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
                        style: TextStyle(color: colors.amber),
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
    this.onEdit,
    this.onDelete,
  });

  final ExamType exam;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: selected ? colors.indigo.withValues(alpha: 0.18) : colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: selected ? colors.indigo : colors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exam.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Düzenle',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Sil',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
