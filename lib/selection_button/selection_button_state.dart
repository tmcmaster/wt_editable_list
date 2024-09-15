part of 'selection_button.dart';

enum SelectionButtonState {
  none(FontAwesomeIcons.square),
  some(FontAwesomeIcons.squareMinus),
  all(FontAwesomeIcons.solidSquareCheck);

  const SelectionButtonState(this.iconData);
  final IconData iconData;
}
