import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: AppFrame(
          maxWidth: 560,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 32),
            children: [
              Text(
                'Deneme Takip',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hangi sınavın denemelerini tutacaksın? Seçimin üst çubuktan istediğin zaman değişir. Diğer sınavların kayıtları durur.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              for (final exam in ExamRegistry.all) ...[
                _ExamCard(
                  exam: exam,
                  onPick: () => ref
                      .read(settingsProvider.notifier)
                      .completeOnboarding(exam.id),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onPick});

  final ExamType exam;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final subjects = exam.sections.map((section) => section.name).join(' · ');
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exam.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Text(
                    'Seç',
                    style: TextStyle(
                      color: AppColors.indigo,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, color: AppColors.indigo),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exam.penaltyLabel,
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subjects,
                style: const TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
