part of '../editable_list_view.dart';

class EditableListStateNotifier<T extends BaseModel<T>> extends StateNotifier<List<EditableListItem<T>>> {
  static final log = logger(EditableListStateNotifier, level: Level.warning);

  EditableListStateNotifier() : super([]);

  void clear() {
    if (state.isNotEmpty) {
      replaceAll([]);
    }
  }

  void replaceAll(List<T> newItems) {
    log.d('🐯Items have been updated: ${newItems.length})');

    state = newItems
        .map(
          (item) => EditableListItem(
            item: item,
            selected: true,
          ),
        )
        .toList();
  }

  void addItem(EditableListItem<T> newItem) {
    log.d('🐯Saving new item: $newItem');
    state = [...state, newItem];
  }

  void removeItem(EditableListItem<T> removedItem) {
    log.d('🐯Deleting item: ${removedItem.item}');
    state = state.where((item) => item.item != removedItem.item).toList();
  }

  void editItem(EditableListItem<T> newItem) {
    state = state.map((item) {
      // debugPrint('${item.item.getId()} compare with ${newItem.item.getId()}: ${item.item == newItem.item}');
      // FIXME: This only works because my models object has overridden the == operator to only consider the object id property.
      return item.item == newItem.item ? newItem.copyWith(selected: item.selected) : item;
    }).toList();
  }

  void selectAll(bool selected) {
    log.d('🐯selectAll: $selected');
    state = state
        .map(
          (e) => e.selected == selected
              ? e
              : EditableListItem<T>(
                  item: e.item,
                  selected: selected,
                ),
        )
        .toList();
  }

  void moveItem(
    int oldIndex,
    int newIndex, {
    List<EditableListItem<T>> Function(List<EditableListItem<T>> list)? postMoveTransform,
    void Function(List<EditableListItem<T>> list)? onMove,
  }) {
    log.d('🐯$oldIndex -> $newIndex');
    if (oldIndex == newIndex) return;
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex + (oldIndex < newIndex ? -1 : 0), item);
    state = postMoveTransform == null ? list : postMoveTransform(list);
    onMove?.call(state);
  }

  void selectItem(EditableListItem item, bool selected) {
    log.d('🐯Selecting item: ${item.item.getId()}');
    state = state.map((e) {
      return e == item
          ? EditableListItem<T>(
              item: e.item,
              selected: selected,
            )
          : e;
    }).toList();
  }

  void hideItems(bool Function(T item) predicate) {
    log.d('🐯Hiding items');
    state = state.map((e) {
      final hidden = !predicate(e.item);
      return e.hidden == hidden ? e : e.copyWith(hidden: hidden);
    }).toList();
  }
}
