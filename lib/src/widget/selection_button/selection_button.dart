import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

part 'selection_button_state.dart';

class SelectionButton extends StatelessWidget {
  final void Function() onSelectAll;
  final void Function() onSelectNone;
  final SelectionButtonState selectionState;

  const SelectionButton({
    super.key,
    required this.selectionState,
    required this.onSelectAll,
    required this.onSelectNone,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(selectionState.iconData),
      onPressed: () {
        switch (selectionState) {
          case SelectionButtonState.all:
            {
              onSelectNone();
            }
          case SelectionButtonState.none:
            {
              onSelectAll();
            }
          case SelectionButtonState.some:
            {
              onSelectNone();
            }
        }
      },
    );
  }
}
