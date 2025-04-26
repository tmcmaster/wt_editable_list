part of '../../editable_list_view.dart';

class EditableListItem<T extends IdSupport<T>> {
  final T item;
  final bool selected;
  final bool hidden;

  EditableListItem({
    required this.item,
    required this.selected,
    this.hidden = false,
  });

  @override
  bool operator ==(Object other) => other is EditableListItem && other.item == item;

  @override
  int get hashCode => item.hashCode;

  EditableListItem<T> copyWith({
    T? item,
    bool? selected,
    bool? hidden,
  }) {
    return EditableListItem<T>(
      item: item ?? this.item,
      selected: selected ?? this.selected,
      hidden: hidden ?? this.hidden,
    );
  }

  @override
  String toString() {
    return item.getId();
  }
}
