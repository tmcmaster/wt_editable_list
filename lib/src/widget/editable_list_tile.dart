part of '../editable_list_view.dart';

class EditableListTile<T extends IdSupport<T>> extends ConsumerWidget {
  // final SelectableItem<T> selectableItem;
  final Widget Function(T item) itemWidgetBuilder;

  final AutoDisposeProviderFamily<EditableListItem<T>?, String> selectedItemProvider;

  final void Function(EditableListItem<T> item) onEdit;
  final void Function(EditableListItem<T> item) onDelete;
  final void Function(EditableListItem<T> item, bool selected) onSelect;

  final bool editIcon;
  final bool canEdit;
  final bool canSelect;
  final bool canReorder;
  final String id;

  const EditableListTile({
    super.key,
    required this.id,
    // required this.selectableItem,
    required this.selectedItemProvider,
    required this.itemWidgetBuilder,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
    this.canEdit = false,
    this.canSelect = false,
    this.editIcon = false,
    this.canReorder = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItemWatch = ref.watch(selectedItemProvider(id));

    final hidden = selectedItemWatch == null || selectedItemWatch.hidden;

    // TODO: there is a bug where some searches have a empty card at the bottom.
    return Visibility(
      visible: !hidden,
      child: selectedItemWatch != null
          ? Card(
              child: Padding(
                padding: EdgeInsets.only(right: canReorder ? 30.0 : 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (canSelect)
                      SizedBox(
                        width: 36,
                        child: Checkbox(
                          value: selectedItemWatch.selected,
                          activeColor: Colors.grey,
                          onChanged: (bool? selected) {
                            if (selected != null) {
                              onSelect(selectedItemWatch, selected);
                            }
                          },
                        ),
                      ),
                    Flexible(
                      flex: 4,
                      fit: FlexFit.tight,
                      child: canEdit
                          ? InkWell(
                              onTap: () => onEdit(selectedItemWatch),
                              child: itemWidgetBuilder(selectedItemWatch.item),
                            )
                          : itemWidgetBuilder(selectedItemWatch.item),
                    ),
                    if (editIcon && canEdit)
                      SizedBox(
                        width: 36,
                        child: IconButton(
                          icon: const Icon(FontAwesomeIcons.penToSquare),
                          onPressed: () => onEdit(selectedItemWatch),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : const Card(),
    );
  }
}
