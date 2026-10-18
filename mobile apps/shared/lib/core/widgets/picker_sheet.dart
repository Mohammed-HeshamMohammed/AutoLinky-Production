import 'package:material_ui/material_ui.dart';

import '../theme/theme_ext.dart';
import '../theme/tokens.dart';
import 'bidi_text.dart';

@immutable
class PickerItem {
  const PickerItem({required this.value, required this.label, this.subtitle});

  final String value;
  final String label;
  final String? subtitle;
}

/// What the user chose: an item of the list, or (with [showPickerSheet]'s `createLabel`) the text they typed.
@immutable
class PickerChoice {
  const PickerChoice.item(this.value) : created = false;

  const PickerChoice.created(this.value) : created = true;

  /// The item's value, or the typed text.
  final String value;
  final bool created;
}

/// A searchable list in a bottom sheet (adding a job or a skill); null when dismissed. With [createLabel], what
/// the user types and the list does not have exactly can be added as it is: the first row offers it.
Future<PickerChoice?> showPickerSheet(
  BuildContext context, {
  required String title,
  required List<PickerItem> items,
  String Function(String text)? createLabel,
  int maxLength = 60,
}) {
  return showModalBottomSheet<PickerChoice>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _PickerSheet(title: title, items: items, createLabel: createLabel, maxLength: maxLength),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.title, required this.items, required this.maxLength, this.createLabel});

  final String title;
  final List<PickerItem> items;
  final String Function(String text)? createLabel;
  final int maxLength;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _query = '';

  String get _typed => _query.trim().replaceAll(RegExp(r'\s+'), ' ');

  List<PickerItem> get _shown {
    final q = _typed.toLowerCase();
    if (q.isEmpty) return widget.items;
    final starts = <PickerItem>[];
    final contains = <PickerItem>[];
    for (final item in widget.items) {
      final label = item.label.toLowerCase();
      if (label.startsWith(q)) {
        starts.add(item);
      } else if (label.contains(q) || item.value.contains(q) || (item.subtitle?.toLowerCase().contains(q) ?? false)) {
        contains.add(item);
      }
    }
    return [...starts, ...contains];
  }

  /// Offer the typed text itself: long enough, and not exactly one of the items.
  bool _canCreate(List<PickerItem> shown) {
    final text = _typed;
    if (widget.createLabel == null || text.length < 2) return false;
    return !shown.any((item) => item.label.toLowerCase() == text.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final create = _canCreate(shown);
    final colors = context.colors;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: context.text.titleLarge),
                const SizedBox(height: AppSpace.md),
                TextField(
                  autofocus: true,
                  maxLength: widget.maxLength,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: context.l10n.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    counterText: '',
                  ),
                  onChanged: (value) => setState(() => _query = value),
                  onSubmitted: (_) {
                    if (shown.length == 1 && !create) {
                      Navigator.pop(context, PickerChoice.item(shown.single.value));
                    } else if (create && shown.isEmpty) {
                      Navigator.pop(context, PickerChoice.created(_typed));
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty && !create
                ? Center(child: Text(context.l10n.noResults, style: context.text.bodyMedium))
                : ListView.builder(
                    controller: scroll,
                    itemCount: shown.length + (create ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (create && i == 0) {
                        return ListTile(
                          leading: Icon(Icons.add_circle_outline_rounded, color: colors.primary),
                          title: BidiText(
                            widget.createLabel!(_typed),
                            maxLines: 2,
                            style: context.text.titleSmall?.copyWith(color: colors.primary),
                          ),
                          onTap: () => Navigator.pop(context, PickerChoice.created(_typed)),
                        );
                      }
                      final item = shown[i - (create ? 1 : 0)];
                      return ListTile(
                        title: BidiText(item.label, maxLines: 1),
                        subtitle: item.subtitle == null ? null : Text(item.subtitle!, maxLines: 1),
                        onTap: () => Navigator.pop(context, PickerChoice.item(item.value)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
