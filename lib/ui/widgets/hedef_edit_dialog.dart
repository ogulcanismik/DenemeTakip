import 'package:deneme_takip/domain/net_format.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';

/// Same hedef-net editor as the Özet pencil affordance.
Future<double?> showEditHedefDialog(
  BuildContext context, {
  required double initial,
}) {
  return showDialog<double>(
    context: context,
    builder: (context) => _HedefEditDialog(initial: initial),
  );
}

class _HedefEditDialog extends StatefulWidget {
  const _HedefEditDialog({required this.initial});

  final double initial;

  @override
  State<_HedefEditDialog> createState() => _HedefEditDialogState();
}

class _HedefEditDialogState extends State<_HedefEditDialog> {
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ).data,
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
