import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:uuid/uuid.dart';
import 'package:wt_editable_list/src/widget/search_order_by_name.dart';
import 'package:wt_editable_list/src/widget/selection_button/selection_button.dart';
import 'package:wt_logging/wt_logging.dart';
import 'package:wt_models/wt_models.dart';
import 'package:wt_state/wt_state.dart';

part 'provider/editable_list_providers.dart';
part 'provider/editable_list_state_notifier.dart';
part 'widget/editable_list_form/editable_list_form.dart';
part 'widget/editable_list_form/editable_list_form_definition.dart';
part 'widget/editable_list_form/editable_list_item.dart';
part 'widget/editable_list_tile.dart';

// TODO: need to look into supporting expandable tiles with actions (for example call/message customer).
class EditableListView<T extends BaseModel<T>> extends ConsumerWidget {
  static final log = logger(EditableListView, level: Level.warning);

  final String name;
  final EditableListProviders<T> providers;

  final Widget Function(T item) itemWidgetBuilder;
  final Widget Function(T? item) itemWidgetEditorBuilder;
  final bool Function(T item, String value) searchPredicate;
  final bool Function(T item, T destItem, int oldIndex, int newIndex)? moveValidator;
  final void Function(List<EditableListItem<T>> list)? onMove;
  final void Function()? onLoadPressed;

  final bool canAdd;
  final bool canDelete;
  final bool canEdit;
  final bool canSelect;
  final bool canReorder;
  // TODO: need to implement search functionality
  final bool canSearch;
  final bool allSelected;
  final bool editIcon;
  final bool showScrollbars;

  final String title;

  final double? itemExtent;
  final double itemSpacing;

  const EditableListView({
    super.key,
    required this.name,
    required this.providers,
    this.itemWidgetBuilder = _defaultItemWidgetBuilder,
    this.itemWidgetEditorBuilder = _defaultItemWidgetEditorBuilder,
    this.searchPredicate = _defaultSearchPredicate,
    this.canAdd = false,
    this.canDelete = false,
    this.canEdit = false,
    this.canReorder = false,
    this.canSelect = false,
    this.canSearch = false,
    this.allSelected = true,
    this.editIcon = false,
    this.showScrollbars = false,
    // TODO: need to review where the title ends up.
    this.title = '',
    this.itemExtent,
    this.itemSpacing = 5,
    this.onMove,
    this.moveValidator,
    this.onLoadPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idList = ref.watch(providers.ids);
    final itemList = ref.watch(providers.list);
    final selectedState = ref.watch(providers.selectionState);
    final listNotifier = ref.read(providers.notifier);

    return Column(
      children: [
        if (canSearch || canSelect || canAdd || title.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (canSelect && itemList.isNotEmpty)
                      SelectionButton(
                        selectionState: selectedState,
                        onSelectAll: () {
                          listNotifier.selectAll(true);
                        },
                        onSelectNone: () {
                          listNotifier.selectAll(false);
                        },
                      ),
                    if (onLoadPressed != null)
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: onLoadPressed,
                      ),
                    if (canAdd)
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.plus),
                        onPressed: canAdd ? () => addNewItem(context, null) : null,
                      ),
                  ],
                ),
              ),
              Flexible(
                flex: (title.length / 10).floor() + 1,
                fit: FlexFit.tight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: title.isEmpty ? 0 : 8,
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (canSearch)
                Flexible(
                  flex: 3,
                  fit: FlexFit.tight,
                  child: SearchOrdersByName(
                    onChange: (value) {
                      listNotifier.hideItems((item) => searchPredicate(item, value));
                    },
                  ),
                ),
            ],
          ),
        Expanded(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(
              scrollbars: showScrollbars,
            ),
            child: canReorder
                ? ReorderableListView.builder(
                    itemExtent: itemExtent,
                    itemCount: idList.length,
                    itemBuilder: (context, index) {
                      final EditableListItem<T> selectedItem = itemList[index];
                      // TODO: investigate why there is a separate list of IDs, instead of using the id in the item
                      final String itemKeyName = '$name : $index : ${idList[index]}';
                      // debugPrint('TILE KEY: $itemKeyName');
                      return _createTile(
                        idList[index],
                        itemKeyName,
                        listNotifier,
                        context,
                        selectedItem,
                      );
                    },
                    // The reorder function
                    onReorder: (oldIndex, newIndex) {
                      final item = itemList[oldIndex].item;
                      final destItem = itemList[newIndex].item;
                      log.d(item);
                      final moveIsValid = moveValidator == null || moveValidator!(item, destItem, oldIndex, newIndex);
                      log.d(moveIsValid);
                      if (moveIsValid) {
                        listNotifier.moveItem(
                          oldIndex,
                          newIndex,
                          onMove: onMove,
                          // postMoveTransform: postMoveTransform,
                        );
                      }
                    },
                  )
                : ListView.builder(
                    itemExtent: itemExtent,
                    itemCount: idList.length,
                    itemBuilder: (context, index) {
                      final EditableListItem<T> selectedItem = itemList[index];
                      final String itemId = idList[index];
                      final String itemKeyName = '$name : ${idList[index]}';
                      return _createTile(
                        itemId,
                        itemKeyName,
                        listNotifier,
                        context,
                        selectedItem,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  StatefulWidget _createTile(
    String orderId,
    String itemKeyValue,
    EditableListStateNotifier<dynamic> listNotifier,
    BuildContext context,
    EditableListItem<dynamic> selectedItem,
  ) {
    final tile = EditableListTile<T>(
      key: Key(itemKeyValue),
      id: orderId,
      // selectableItem: selectedItem,
      selectedItemProvider: providers.family,
      itemWidgetBuilder: itemWidgetBuilder,
      onDelete: listNotifier.removeItem,
      onEdit: (item) => addNewItem(context, item.item),
      onSelect: listNotifier.selectItem,
      canEdit: canEdit,
      canSelect: canSelect,
      canReorder: canReorder,
      editIcon: editIcon,
    );

    final dismissibleTile = canDelete
        ? Dismissible(
            onDismissed: (_) => listNotifier.removeItem(selectedItem),
            key: tile.key!,
            background: Container(color: Colors.transparent),
            child: SizedBox(
              height: itemExtent,
              child: tile,
            ),
          )
        : tile;

    return dismissibleTile;
  }

  void onDelete(EditableListItem item) {
    log.d('onDelete($item)');
  }

  void onAdd(EditableListItem item) {
    log.d('onAdd($item)');
  }

  void onEdit(EditableListItem item) {
    log.d('onEdit($item)');
  }

  void onSelect(EditableListItem item, bool selected) {
    log.d('onSelect($item)');
  }

  void allCheckedChanged(bool? value) {
    log.d('All items checkbox has changed: $value.');
  }

  void addNewItem(BuildContext context, T? item) {
    log.d('Add new Item has been pressed.');
    showDialog(
      context: context,
      barrierDismissible: true,
      // animationType: DialogTransitionType.slideFromRight,
      // alignment: Alignment.center,
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Add a new Website token'),
          ),
          body: itemWidgetEditorBuilder(item),
        );
      },
    );
  }

  void itemHasMoved(int oldIndex, int newIndex) {
    log.d('Item has moved from position $oldIndex to position $newIndex');
  }

  static bool _defaultSearchPredicate(Object item, String value) => true;

  static Widget _defaultItemWidgetEditorBuilder(Object? item) {
    return ListTile(title: Text(item.toString()));
  }

  static Widget _defaultItemWidgetBuilder(Object item) {
    return ListTile(title: Text(item.toString()));
  }
}
