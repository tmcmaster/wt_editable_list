part of 'editable_list_view.dart';

class EditableListFormDefinition<T> {
  final String label;
  final T initialValue;
  final List<FormFieldValidator> validators;
  final bool readOnly;
  final bool isUUID;
  EditableListFormDefinition({
    required this.label,
    required this.validators,
    required this.initialValue,
    this.readOnly = false,
    this.isUUID = false,
  });
}
