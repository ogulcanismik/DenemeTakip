import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/screens/dashboard_screen.dart';
import 'package:deneme_takip/ui/screens/entry_screen.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _tab = 1;
  int _formToken = 0;

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(activeExamProvider);
    if (exam == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deneme Takip'),
        actions: const [_ExamSwitcher()],
      ),
      body: IndexedStack(
        index: _tab,
        sizing: StackFit.expand,
        children: [
          DashboardScreen(onEnterDeneme: () => setState(() => _tab = 1)),
          EntryScreen(
            key: ValueKey('${exam.id}:$_formToken'),
            exam: exam,
            active: _tab == 1,
            onSaved: () => setState(() {
              _tab = 0;
              _formToken += 1;
            }),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Özet',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Deneme gir',
          ),
        ],
      ),
    );
  }
}

class _ExamSwitcher extends ConsumerWidget {
  const _ExamSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeExamProvider);
    if (active == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Sınav değiştir',
      initialValue: active.id,
      color: AppColors.surfaceHigh,
      onSelected: (id) => ref.read(settingsProvider.notifier).setActiveExam(id),
      itemBuilder: (context) {
        return [
          for (final exam in ExamRegistry.all)
            PopupMenuItem<String>(
              value: exam.id,
              height: 68,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    exam.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    exam.penaltyLabel,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              active.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}
