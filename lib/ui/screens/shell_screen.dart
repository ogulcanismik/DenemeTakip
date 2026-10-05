import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/screens/analysis_screen.dart';
import 'package:deneme_takip/ui/screens/dashboard_screen.dart';
import 'package:deneme_takip/ui/screens/entry_screen.dart';
import 'package:deneme_takip/ui/screens/exam_list_settings_screen.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  /// 0 Özet, 1 Analiz, 2 Deneme Gir
  int _tab = 2;
  int _formToken = 0;
  final _saveHandle = EntrySaveHandle();

  @override
  void dispose() {
    _saveHandle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(activeExamProvider);
    if (exam == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deneme Takip'),
        actions: [
          const _ExamSwitcher(),
          IconButton(
            tooltip: 'Ayarlar',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ExamListSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
        bottom: _tab == 2
            ? PreferredSize(
                preferredSize: const Size.fromHeight(188),
                child: ListenableBuilder(
                  listenable: _saveHandle,
                  builder: (context, _) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        AppSpacing.shellBodyTop,
                        16,
                        12,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: EntrySaveBar(
                            total: _saveHandle.total,
                            hint: _saveHandle.hint,
                            saving: _saveHandle.saving,
                            onSave: _saveHandle.onSave,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            : null,
      ),
      body: IndexedStack(
        index: _tab,
        sizing: StackFit.expand,
        children: [
          DashboardScreen(onEnterDeneme: () => setState(() => _tab = 2)),
          const AnalysisScreen(),
          EntryScreen(
            key: ValueKey('${exam.id}:$_formToken'),
            exam: exam,
            active: _tab == 2,
            saveHandle: _saveHandle,
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
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Deneme Gir',
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
    final enabled = ref.watch(enabledExamsProvider);
    if (active == null || enabled.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Sınav değiştir',
      initialValue: active.id,
      color: AppColors.surfaceHigh,
      onSelected: (id) => ref.read(settingsProvider.notifier).setActiveExam(id),
      itemBuilder: (context) {
        return [
          for (final exam in enabled)
            PopupMenuItem<String>(
              value: exam.id,
              child: Text(
                exam.name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                active.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}
