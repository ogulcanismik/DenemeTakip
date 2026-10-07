import 'dart:async';

import 'package:deneme_takip/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountField extends StatefulWidget {
  const CountField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.order,
    required this.onStep,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final double order;
  final void Function(int delta) onStep;

  @override
  State<CountField> createState() => _CountFieldState();
}

class _CountFieldState extends State<CountField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(CountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocus);
      widget.focusNode.addListener(_handleFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    if (!widget.focusNode.hasFocus) return;
    _selectAll();
  }

  void _selectAll() {
    void select() {
      if (!mounted || !widget.focusNode.hasFocus) return;
      final text = widget.controller.text;
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.length,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => select());
    Timer(const Duration(milliseconds: 40), select);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: AppColors.of(context).textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _StepButton(
              tooltip: '${widget.label} azalt',
              icon: Icons.remove,
              onPressed: () => widget.onStep(-1),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FocusTraversalOrder(
                order: NumericFocusOrder(widget.order),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  textAlign: TextAlign.center,
                  enableSuggestions: false,
                  autocorrect: false,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).text,
                    height: 1.2,
                  ).data,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\-]')),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                  ),
                  onTap: _selectAll,
                  onEditingComplete: () => widget.focusNode.nextFocus(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _StepButton(
              tooltip: '${widget.label} artır',
              icon: Icons.add,
              onPressed: () => widget.onStep(1),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.of(context).surfaceHigh,
        foregroundColor: AppColors.of(context).text,
        minimumSize: const Size(40, 40),
        fixedSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
