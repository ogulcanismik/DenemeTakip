import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _selected = <String>{};

  Future<void> _continue() async {
    if (_selected.isEmpty) return;
    await ref
        .read(settingsProvider.notifier)
        .completeOnboarding(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selected.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: AppFrame(
          maxWidth: 560,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
                  children: [
                    Text(
                      'Deneme Takip',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hangi sınavların denemelerini tutacaksın? Birden fazla seçebilirsin. Üst çubukta yalnızca seçtiklerin görünür; diğerlerini Ayarlar’dan ekleyebilirsin.',
                      style: TextStyle(
                        color: AppColors.of(context).textMuted,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    for (final exam in ExamRegistry.all) ...[
                      _ExamSelectTile(
                        exam: exam,
                        selected: _selected.contains(exam.id),
                        onToggle: () {
                          setState(() {
                            if (_selected.contains(exam.id)) {
                              _selected.remove(exam.id);
                            } else {
                              _selected.add(exam.id);
                            }
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
                    if (!canContinue)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Devam etmek için en az bir sınav seç.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.of(context).amber,
                          ),
                        ),
                      ),
                    FilledButton(
                      onPressed: canContinue ? _continue : null,
                      child: Text(
                        canContinue
                            ? 'Devam et (${_selected.length})'
                            : 'Devam et',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamSelectTile extends StatelessWidget {
  const _ExamSelectTile({
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
          ? AppColors.of(context).indigo.withValues(alpha: 0.18)
          : AppColors.of(context).surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: selected ? AppColors.of(context).indigo : AppColors.of(context).textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exam.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
