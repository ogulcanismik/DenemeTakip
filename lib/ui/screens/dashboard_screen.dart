import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/screens/detail_screen.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:deneme_takip/ui/turkish_date.dart';
import 'package:deneme_takip/ui/widgets/net_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.onEnterDeneme});

  final VoidCallback onEnterDeneme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = ref.watch(activeExamProvider);
    final entries = ref.watch(activeEntriesProvider);
    final settings = ref.watch(settingsProvider);
    if (exam == null) return const SizedBox.shrink();

    final target = settings.targetFor(exam.id);
    final oldestFirst = [...entries]
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });
    final recent = entries.length <= 3 ? entries : entries.sublist(0, 3);

    return AppFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.shellBodyHorizontal,
          AppSpacing.shellBodyTop,
          AppSpacing.shellBodyHorizontal,
          28,
        ),
        children: [
          _TargetCard(
            target: target,
            onEdit: () => _editTarget(context, ref, exam.id, target),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            _EmptyState(examName: exam.name, onEnterDeneme: onEnterDeneme)
          else ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam net',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Eskiden yeniye. Kesik çizgi hedef net.',
                    style: TextStyle(color: AppColors.of(context).textMuted),
                  ),
                  const SizedBox(height: 12),
                  TotalNetChart(entries: oldestFirst, target: target),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Son denemeler', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: AppColors.of(context).outline),
                    _HistoryTile(entry: recent[i]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editTarget(
    BuildContext context,
    WidgetRef ref,
    String examTypeId,
    double current,
  ) async {
    final next = await showDialog<double>(
      context: context,
      builder: (context) => _TargetDialog(initial: current),
    );
    if (next == null) return;
    await ref.read(settingsProvider.notifier).setTarget(examTypeId, next);
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.target, required this.onEdit});

  final double target;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Hedef net',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatNet(target),
                style: TextStyle(
                  color: AppColors.of(context).indigo,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, color: AppColors.of(context).textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({required this.initial});

  final double initial;

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  late final TextEditingController _controller;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: formatNet(widget.initial));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || !parsed.isFinite) {
      setState(() => _hint = 'Bir sayı gir.');
      return;
    }
    if (parsed < 0) {
      setState(() => _hint = 'Hedef negatif olamaz.');
      return;
    }
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hedef net'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Hedef'),
            onSubmitted: (_) => _submit(),
          ),
          if (_hint != null) ...[
            const SizedBox(height: 8),
            Text(_hint!, style: TextStyle(color: AppColors.of(context).amber)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Kaydet')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.examName, required this.onEnterDeneme});

  final String examName;
  final VoidCallback onEnterDeneme;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Henüz $examName denemesi yok.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'İlkini girmek bir dakikadan kısa sürer. Doğru ve yanlış yeterli; boş kendiliğinden hesaplanır.',
            style: TextStyle(color: AppColors.of(context).textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onEnterDeneme,
            child: const Text('Deneme gir'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final DenemeEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        entry.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(formatTurkishDate(entry.date)),
      trailing: Text(
        formatNet(entry.totalNet),
        style: TextStyle(
          color: AppColors.of(context).emerald,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => DetailScreen(entryId: entry.id),
          ),
        );
      },
    );
  }
}
