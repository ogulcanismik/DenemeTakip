import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:deneme_takip/ui/turkish_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider);
    DenemeEntry? entry;
    for (final candidate in entries) {
      if (candidate.id == entryId) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Bu deneme bulunamadı.')),
      );
    }

    final exam = ExamRegistry.byId(entry.examTypeId);
    final saved = entry;

    return Scaffold(
      appBar: AppBar(
        title: Text(saved.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: AppFrame(
        maxWidth: 680,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              formatTurkishDate(saved.date),
              style: TextStyle(color: AppColors.of(context).textMuted),
            ),
            if (exam != null) ...[
              const SizedBox(height: 4),
              Text(
                exam.name,
                style: TextStyle(color: AppColors.of(context).textMuted),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              formatNet(saved.totalNet),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppColors.of(context).emerald,
                height: 1.1,
              ).data,
            ),
            Text(
              'Toplam net',
              style: TextStyle(color: AppColors.of(context).textMuted),
            ),
            if (saved.durationMinutes != null) ...[
              const SizedBox(height: 12),
              Text('Süre: ${saved.durationMinutes} dk'),
            ],
            if (saved.difficultyRating != null) ...[
              const SizedBox(height: 4),
              Text('Zorluk: ${saved.difficultyRating} / 5'),
            ],
            const SizedBox(height: 20),
            for (final section in saved.sections) ...[
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam?.sectionById(section.sectionId)?.name ??
                          section.sectionId,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Stat(label: 'Doğru', value: '${section.correctCount}'),
                        _Stat(
                          label: 'Yanlış',
                          value: '${section.incorrectCount}',
                        ),
                        _Stat(label: 'Boş', value: '${section.emptyCount}'),
                        _Stat(
                          label: 'Net',
                          value: formatNet(section.calculatedNet),
                          emphasize: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _confirmDelete(context, ref, saved),
              child: const Text('Denemeyi sil'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DenemeEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deneme silinsin mi?'),
          content: const Text('Bu kayıt cihazdan kalkar. Geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Sil',
                style: TextStyle(color: AppColors.of(context).amber),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(entriesProvider.notifier).delete(entry.id);
    if (context.mounted) Navigator.pop(context);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: emphasize ? AppColors.of(context).emerald : AppColors.of(context).text,
            ).data,
          ),
        ],
      ),
    );
  }
}
