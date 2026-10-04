import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/domain/istanbul_time.dart';
import 'package:deneme_takip/domain/net_engine.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:deneme_takip/ui/turkish_date.dart';
import 'package:deneme_takip/ui/widgets/count_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EntrySaveHandle extends ChangeNotifier {
  String total = '—';
  String? hint;
  var saving = false;
  VoidCallback? onSave;
  var _disposed = false;

  void publish({
    required String total,
    required String? hint,
    required bool saving,
    required VoidCallback onSave,
  }) {
    if (_disposed) return;
    final changed =
        this.total != total ||
        this.hint != hint ||
        this.saving != saving ||
        this.onSave == null;
    this.total = total;
    this.hint = hint;
    this.saving = saving;
    this.onSave = onSave;
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({
    super.key,
    required this.exam,
    required this.active,
    required this.onSaved,
    required this.saveHandle,
  });

  final ExamType exam;
  final bool active;
  final VoidCallback onSaved;
  final EntrySaveHandle saveHandle;

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  late final TextEditingController _title;
  late final TextEditingController _duration;
  late final List<TextEditingController> _correct;
  late final List<TextEditingController> _incorrect;
  late final List<FocusNode> _focus;
  DateTime _date = istanbulToday();
  int? _difficulty;
  var _saving = false;
  var _didFocus = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    final count = widget.exam.sections.length;
    _title = TextEditingController();
    _duration = TextEditingController();
    _correct = [
      for (var i = 0; i < count; i++) TextEditingController(text: '0'),
    ];
    _incorrect = [
      for (var i = 0; i < count; i++) TextEditingController(text: '0'),
    ];
    _focus = [for (var i = 0; i < count * 2; i++) FocusNode()];
    for (final controller in [..._correct, ..._incorrect, _duration]) {
      controller.addListener(_rebuild);
    }
    _focusIfNeeded();
  }

  @override
  void didUpdateWidget(EntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focusIfNeeded();
  }

  void _focusIfNeeded() {
    if (_didFocus || !widget.active || _focus.isEmpty) return;
    _didFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.first.requestFocus();
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    for (final controller in [..._correct, ..._incorrect]) {
      controller.removeListener(_rebuild);
      controller.dispose();
    }
    _duration.removeListener(_rebuild);
    for (final node in _focus) {
      node.dispose();
    }
    super.dispose();
  }

  NetResult _evaluate() {
    return NetEngine.evaluate(widget.exam, {
      for (var i = 0; i < widget.exam.sections.length; i++)
        widget.exam.sections[i].id: SectionCounts(
          _parseCount(_correct[i].text),
          _parseCount(_incorrect[i].text),
        ),
    });
  }

  bool get _durationValid {
    final text = _duration.text.trim();
    if (text.isEmpty) return true;
    final value = int.tryParse(text);
    return value != null && value > 0;
  }

  int? _durationValue() {
    final text = _duration.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  void _step(int index, bool correct, int delta) {
    final definition = widget.exam.sections[index];
    final controller = correct ? _correct[index] : _incorrect[index];
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, definition.questionCount);
    controller.text = '$next';
    final node = _focus[index * 2 + (correct ? 0 : 1)];
    if (node.hasFocus) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final result = _evaluate();
    if (!result.isValid || !_durationValid) {
      final names = [
        for (final issue in result.issues)
          widget.exam.sectionById(issue.sectionId)?.name ?? issue.sectionId,
      ];
      setState(() {
        _status = names.isEmpty
            ? 'Süreyi düzelt veya boş bırak.'
            : 'Düzelt: ${names.join(', ')}';
      });
      return;
    }

    final title = _title.text.trim();
    final existing = ref
        .read(entriesProvider)
        .where((entry) => entry.examTypeId == widget.exam.id)
        .length;
    setState(() {
      _saving = true;
      _status = 'Kaydediliyor…';
    });
    try {
      final entry = DenemeEntry(
        id: newEntryId(),
        examTypeId: widget.exam.id,
        title: title.isEmpty ? 'Deneme ${existing + 1}' : title,
        date: _date,
        durationMinutes: _durationValue(),
        difficultyRating: _difficulty,
        sections: [
          for (final section in result.sections)
            SectionScore(
              sectionId: section.sectionId,
              correctCount: section.correctCount,
              incorrectCount: section.incorrectCount,
              emptyCount: section.emptyCount,
              calculatedNet: section.net,
            ),
        ],
        totalNet: result.totalNet,
      );
      await ref
          .read(entriesProvider.notifier)
          .add(entry)
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      widget.onSaved();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _status = 'Kayıt olmadı: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _evaluate();
    final exam = widget.exam;

    final total = result.isValid ? formatNet(result.totalNet) : '—';
    final hint = result.isValid ? _status : _footerHint(result);
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.saveHandle.publish(
          total: total,
          hint: hint,
          saving: _saving,
          onSave: _save,
        );
      });
    }

    return AppFrame(
      maxWidth: 760,
      child: Column(
        children: [
          Expanded(
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  TextField(
                    controller: _title,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Başlık (isteğe bağlı)',
                      hintText: 'Özdebir Türkiye Geneli 1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 12),
                            const Text('Tarih'),
                            const Spacer(),
                            Text(
                              formatTurkishDate(_date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < exam.sections.length; i++) ...[
                    _SectionCard(
                      definition: exam.sections[i],
                      correct: _correct[i],
                      incorrect: _incorrect[i],
                      correctFocus: _focus[i * 2],
                      incorrectFocus: _focus[i * 2 + 1],
                      order: i * 2,
                      computed: result.find(exam.sections[i].id),
                      issue: result.issueFor(exam.sections[i].id),
                      onStepCorrect: (delta) => _step(i, true, delta),
                      onStepIncorrect: (delta) => _step(i, false, delta),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: ExpansionTile(
                        title: const Text('Süre ve zorluk'),
                        subtitle: const Text('İsteğe bağlı'),
                        iconColor: AppColors.textMuted,
                        collapsedIconColor: AppColors.textMuted,
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        children: [
                          TextField(
                            controller: _duration,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Süre (dakika)',
                              hintText: 'ör. 135',
                            ),
                          ),
                          if (!_durationValid) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Süre, pozitif bir tam sayı olmalı.',
                              style: TextStyle(color: AppColors.amber),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Zorluk',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var rating = 1; rating <= 5; rating++)
                                ChoiceChip(
                                  label: Text('$rating'),
                                  selected: _difficulty == rating,
                                  onSelected: (selected) {
                                    setState(() {
                                      _difficulty = selected ? rating : null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _footerHint(NetResult result) {
    if (!result.isValid) {
      return 'Kaydetmek için satırlardaki uyarıları düzelt.';
    }
    if (!_durationValid) {
      return 'Süreyi düzelt veya boş bırak.';
    }
    return null;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.definition,
    required this.correct,
    required this.incorrect,
    required this.correctFocus,
    required this.incorrectFocus,
    required this.order,
    required this.computed,
    required this.issue,
    required this.onStepCorrect,
    required this.onStepIncorrect,
  });

  final SectionDefinition definition;
  final TextEditingController correct;
  final TextEditingController incorrect;
  final FocusNode correctFocus;
  final FocusNode incorrectFocus;
  final int order;
  final ComputedSection? computed;
  final InputIssue? issue;
  final void Function(int delta) onStepCorrect;
  final void Function(int delta) onStepIncorrect;

  @override
  Widget build(BuildContext context) {
    final net = computed == null ? '—' : formatNet(computed!.net);
    final empty = computed == null ? '—' : '${computed!.emptyCount}';
    final wide = MediaQuery.sizeOf(context).width >= 640;

    final correctField = CountField(
      controller: correct,
      focusNode: correctFocus,
      label: 'Doğru',
      order: order.toDouble(),
      onStep: onStepCorrect,
    );
    final incorrectField = CountField(
      controller: incorrect,
      focusNode: incorrectFocus,
      label: 'Yanlış',
      order: order + 1,
      onStep: onStepIncorrect,
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  definition.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Net $net',
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${definition.questionCount} soru · Boş $empty',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: correctField),
                const SizedBox(width: 16),
                Expanded(child: incorrectField),
              ],
            )
          else ...[
            correctField,
            const SizedBox(height: 12),
            incorrectField,
          ],
          if (issue != null) ...[
            const SizedBox(height: 8),
            Text(
              _issueText(issue!, definition.questionCount),
              style: const TextStyle(color: AppColors.amber, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  String _issueText(InputIssue issue, int questionCount) {
    return switch (issue.kind) {
      InputIssueKind.negative => 'Negatif olamaz.',
      InputIssueKind.nonInteger => 'Tam sayı gir.',
      InputIssueKind.overflow =>
        'Doğru + yanlış, $questionCount soruyu aşıyor.',
    };
  }
}

class EntrySaveBar extends StatelessWidget {
  const EntrySaveBar({
    super.key,
    required this.total,
    required this.hint,
    required this.saving,
    required this.onSave,
  });

  final String total;
  final String? hint;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Toplam net',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
              const Spacer(),
              Text(
                total,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: const TextStyle(color: AppColors.amber, height: 1.3),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: saving ? null : onSave,
            child: Text(saving ? 'Kaydediliyor…' : 'Denemeyi kaydet'),
          ),
        ],
      ),
    );
  }
}

num _parseCount(String raw) {
  final trimmed = raw.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return double.nan;
  final asInt = int.tryParse(trimmed);
  if (asInt != null) return asInt;
  return double.tryParse(trimmed) ?? double.nan;
}
