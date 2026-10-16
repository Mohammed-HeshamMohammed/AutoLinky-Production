import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/theme_ext.dart';
import '../theme/tokens.dart';

/// A one-time code typed into separate boxes. One real (invisible) text field underneath does the typing, so the
/// keyboard, paste, autofill (AutofillHints.oneTimeCode) and accessibility all work as in any text field; the
/// boxes only draw it. Digits always run left to right, in Arabic too.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.length = 6,
    this.enabled = true,
    this.error = false,
    this.autofocus = false,
    this.onCompleted,
    this.onChanged,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final int length;
  final bool enabled;

  /// Red boxes (a wrong code).
  final bool error;
  final bool autofocus;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final String? semanticLabel;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  late final FocusNode _ownFocus = FocusNode();

  FocusNode get _focus => widget.focusNode ?? _ownFocus;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_redraw);
  }

  @override
  void didUpdateWidget(CodeInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if ((old.focusNode ?? _ownFocus) != _focus) {
      (old.focusNode ?? _ownFocus).removeListener(_redraw);
      _focus.addListener(_redraw);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.removeListener(_redraw);
    _ownFocus.dispose();
    super.dispose();
  }

  String _last = '';

  void _changed() {
    final text = widget.controller.text;
    if (text == _last) return;
    _last = text;
    setState(() {});
    widget.onChanged?.call(text);
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  void _redraw() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = widget.controller.text;
    final focused = _focus.hasFocus && widget.enabled;
    final fill = colors.brightness == Brightness.dark ? colors.surfaceContainerLow : colors.surfaceContainerLowest;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpace.sm;
          final size = ((constraints.maxWidth - gap * (widget.length - 1)) / widget.length).clamp(36.0, 56.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    AnimatedContainer(
                      duration: AppDurations.fast,
                      width: size,
                      height: size * 1.15,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(
                          color: widget.error
                              ? colors.error
                              : focused && i == text.length.clamp(0, widget.length - 1)
                              ? colors.primary
                              : i < text.length
                              ? colors.outline
                              : colors.outlineVariant,
                          width: widget.error || (focused && i == text.length.clamp(0, widget.length - 1)) ? 1.6 : 1,
                        ),
                      ),
                      child: Text(
                        i < text.length ? text[i] : '',
                        style: context.text.headlineSmall?.copyWith(
                          color: widget.enabled ? colors.onSurface : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // the real field: invisible, over the boxes, so a tap anywhere on them focuses it
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    showCursor: false,
                    enableSuggestions: false,
                    autocorrect: false,
                    maxLength: widget.length,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    decoration: InputDecoration.collapsed(hintText: widget.semanticLabel)
                        .copyWith(counterText: '', filled: false),
                    style: const TextStyle(color: Colors.transparent),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
