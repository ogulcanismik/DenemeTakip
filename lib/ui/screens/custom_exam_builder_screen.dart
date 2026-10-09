import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomExamBuilderScreen extends ConsumerStatefulWidget {
  const CustomExamBuilderScreen({super.key, this.existing});

  final ExamType? existing;

  @override
  ConsumerState<CustomExamBuilderScreen> createState() =>
      _CustomExamBuilderScreenState();
}

class _TopicDraft {
  _TopicDraft({String? id, String name = '', int questionCount = 20})
    : id = id ?? newSectionId(),
      nameController = TextEditingController(text: name),
      countController = TextEditingController(
        text: questionCount > 0 ? '$questionCount' : '',
      );

  final String id;
  final TextEditingController nameController;
  final TextEditingController countController;

  void dispose() {
    nameController.dispose();
    countController.dispose();
  }
}

class _CustomExamBuilderScreenState
    extends ConsumerState<CustomExamBuilderScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _penaltyController;
  late final TextEditingController _targetController;
  late final List<_TopicDraft> _topics;
  var _saving = false;
  String? _hint;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _penaltyController = TextEditingController(
      text: '${existing?.penaltyDivisor ?? 4}',
    );
    if (existing != null && existing.sections.isNotEmpty) {
      _topics = [
        for (final section in existing.sections)
          _TopicDraft(
            id: section.id,
            name: section.name,
            questionCount: section.questionCount,
          ),
      ];
      _targetController = TextEditingController(
        text: _formatNumber(existing.defaultTargetNet),
      );
    } else {
      _topics = [_TopicDraft()];
      _targetController = TextEditingController(
        text: _formatNumber(suggestedTargetNet(_parsedSections())),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _penaltyController.dispose();
    _targetController.dispose();
    for (final topic in _topics) {
      topic.dispose();
    }
    super.dispose();
  }

  List<SectionDefinition> _parsedSections() {
    return [
      for (final topic in _topics)
        SectionDefinition(
          id: topic.id,
          name: topic.nameController.text.trim(),
          questionCount: int.tryParse(topic.countController.text.trim()) ?? 0,
        ),
    ];
  }

  String? _validate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return 'Sınav adı boş olamaz.';

    final sections = _parsedSections();
    if (sections.isEmpty) return 'En az bir ders / bölüm ekle.';

    for (final section in sections) {
      if (section.name.isEmpty) return 'Ders adı boş olamaz.';
      if (section.questionCount <= 0) {
        return 'Soru sayısı 1 veya daha büyük olmalı.';
      }
    }

    final penalty = int.tryParse(_penaltyController.text.trim());
    if (penalty == null || penalty < 0) {
      return 'Ceza kuralı 0 veya pozitif tam sayı olmalı.';
    }

    final target = double.tryParse(
      _targetController.text.trim().replaceAll(',', '.'),
    );
    if (target == null || !target.isFinite || target < 0) {
      return 'Hedef net 0 veya daha büyük olmalı.';
    }

    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _hint = error);
      return;
    }

    setState(() {
      _saving = true;
      _hint = null;
    });

    final sections = _parsedSections();
    final penalty = int.parse(_penaltyController.text.trim());
    final target = double.parse(
      _targetController.text.trim().replaceAll(',', '.'),
    );
    final exam = ExamType(
      id: widget.existing?.id ?? newCustomExamId(),
      name: _nameController.text.trim(),
      penaltyDivisor: penalty,
      sections: sections,
      defaultTargetNet: target,
    );

    await ref.read(settingsProvider.notifier).upsertCustomExam(exam);
    if (!mounted) return;
    Navigator.pop(context, exam);
  }

  void _addTopic() {
    setState(() {
      _topics.add(_TopicDraft());
      _hint = null;
    });
  }

  void _removeTopic(int index) {
    if (_topics.length <= 1) {
      setState(() => _hint = 'En az bir ders / bölüm kalmalı.');
      return;
    }
    setState(() {
      _topics.removeAt(index).dispose();
      _hint = null;
    });
  }

  void _refreshSuggestedTarget() {
    if (_isEdit) return;
    final suggested = suggestedTargetNet(_parsedSections());
    _targetController.text = _formatNumber(suggested);
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return '${value.round()}';
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Özel sınavı düzenle' : 'Özel sınav oluştur'),
      ),
      body: AppFrame(
        maxWidth: 560,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  Text(
                    'Sınav adı',
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Örn. Deneme Kursu Matematik',
                    ),
                    onChanged: (_) => setState(() => _hint = null),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dersler / bölümler',
                          style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addTopic,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _topics.length; i++) ...[
                    _TopicCard(
                      index: i,
                      topic: _topics[i],
                      canRemove: _topics.length > 1,
                      onRemove: () => _removeTopic(i),
                      onChanged: () {
                        setState(() => _hint = null);
                        _refreshSuggestedTarget();
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Ceza kuralı',
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'X yanlış 1 doğruyu götürür. 0 = ceza yok (HMGS gibi).',
                    style: TextStyle(color: colors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _penaltyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'X (yanlış sayısı)',
                      hintText: '4',
                    ),
                    onChanged: (_) => setState(() => _hint = null),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Varsayılan hedef net',
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Örn. 70',
                    ),
                    onChanged: (_) => setState(() => _hint = null),
                  ),
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

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.index,
    required this.topic,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _TopicDraft topic;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bölüm ${index + 1}',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Kaldır',
                  onPressed: canRemove ? onRemove : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            TextField(
              controller: topic.nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Ders adı'),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: topic.countController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'Soru sayısı'),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
