part of 'editable_list_view.dart';

class EditableListProviders<T extends BaseModel<T>> {
  static final log = logger(EditableListProviders);

  final String name;
  late final StateNotifierProvider<EditableListStateNotifier<T>, List<EditableListItem<T>>> list;
  late final Provider<List<String>> ids;
  late final Provider<List<T>> items;
  late final Provider<List<T>> selected;
  late final AutoDisposeProviderFamily<EditableListItem<T>?, String> family;
  late final Refreshable<EditableListStateNotifier<T>> notifier;
  late final Provider<SelectionButtonState> selectionState;
  late final ProviderFamily<List<EditableListItem<T>>, String> search;

  // TODO: need a field for the function to give item to to get the string to be searched. Could return an array of strings.
  EditableListProviders({
    this.name = 'EditableListProviders',
    List<T>? initialItems,
    AlwaysAliveProviderBase<List<T>>? provider,
  }) {
    list = _list(initialItems: initialItems, provider: provider);
    notifier = list.notifier;
    items = _items(list);
    selected = _selected(list);
    selectionState = _selectionState(items, selected);
    ids = _ids(list);
    family = _family(list);
    // TODO: need to remove this search provider. Using a different approach.
    search = _search(list);
  }

  StateNotifierProvider<EditableListStateNotifier<T>, List<EditableListItem<T>>> _list({
    List<T>? initialItems,
    AlwaysAliveProviderBase<List<T>>? provider,
  }) {
    return StateNotifierProvider<EditableListStateNotifier<T>, List<EditableListItem<T>>>(
      name: '$name.list',
      (ref) {
        final notifier = EditableListStateNotifier<T>();

        if (provider != null) {
          log.d('Provider($name.list) is aAdding a listener to provider: ${provider.name}');
          final items = ref.read(provider);
          notifier.replaceAll(items);
          // TODO: this should be keeping a reference to the subscription and disposing it.
          ref.listen(provider, (_, List<T> next) {
            notifier.replaceAll(next);
          });
        }

        if (initialItems != null) {
          notifier.replaceAll(initialItems);
        }

        return notifier;
      },
    );
  }

  Provider<List<String>> _ids(
    StateNotifierProvider<EditableListStateNotifier<T>, List<EditableListItem<T>>> listProvider,
  ) {
    return Provider(
      name: '$name.ids',
      (ref) => ref.watch(listProvider).map((e) => e.item.getId()).toList(),
    );
  }

  Provider<List<T>> _items(
    StateNotifierProvider<EditableListStateNotifier<T>, List<EditableListItem<T>>> listProvider,
  ) {
    // TODO: look at making this autoDispose.
    return Provider(
      name: '$name.items',
      (ref) => ref.watch(listProvider).map((e) => e.item).toList(),
    );
  }

  // TODO: check if this providers like this are being recreated frequently
  Provider<List<T>> _selected(
    StateNotifierProvider<EditableListStateNotifier<T>, List<EditableListItem<T>>> listProvider,
  ) {
    return Provider(
      name: '$name.selected',
      (ref) => ref.watch(listProvider).where((e) => e.selected == true).map((e) => e.item).toList(),
    );
  }

  AutoDisposeProviderFamily<EditableListItem<T>?, String> _family(
    StateNotifierProvider<EditableListStateNotifier<T>, List<EditableListItem<T>>> listProvider,
  ) {
    return Provider.autoDispose.family<EditableListItem<T>?, String>(
      name: '$name.family',
      (ref, id) {
        final orderList = ref.watch(listProvider);
        final selectableItems = orderList.where((element) => element.item.getId() == id).toList();
        return selectableItems.isNotEmpty ? selectableItems[0] : null;
      },
    );
  }

  // TODO: this search functionality needs to be completed and tested.
  ProviderFamily<List<EditableListItem<T>>, String> _search(
    StateNotifierProvider<EditableListStateNotifier<T>, List<EditableListItem<T>>> listProvider,
  ) {
    return Provider.family<List<EditableListItem<T>>, String>(
      name: '$name.search',
      (ref, query) {
        final orderList = ref.watch(listProvider);
        return orderList.where((element) => element.item.toString().toLowerCase().contains(query)).toList();
      },
    );
  }

  // TODO: need to review the use of provider, and maybe change to StateNotifierProvider and use listeners.
  Provider<SelectionButtonState> _selectionState(
    Provider<List<T>> items,
    Provider<List<T>> selectedItems,
  ) {
    return Provider(
      name: '$name.selection',
      (ref) {
        final total = ref.watch(items).length;
        final selected = ref.watch(selectedItems).length;
        if (total == selected) {
          return SelectionButtonState.all;
        } else if (selected == 0) {
          return SelectionButtonState.none;
        } else {
          return SelectionButtonState.some;
        }
      },
    );
  }
}
