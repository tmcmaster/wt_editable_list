part of 'editable_list_view.dart';

class EditableListForm<T extends BaseModel<T>> extends StatefulWidget {
  static final log = logger(EditableListForm);

  final T? item;
  final EditableListStateNotifier<T> listNotifier;
  final Map<String, EditableListFormDefinition<String>> formItemDefinitions;

  final T Function(Map<String, dynamic> json) mapToItem;
  final Map<String, dynamic> Function(T item) itemToMap;

  const EditableListForm({
    super.key,
    this.item,
    required this.formItemDefinitions,
    required this.listNotifier,
    required this.itemToMap,
    required this.mapToItem,
  });

  // TODO: need to investigate how this GlobalKey is being created and used.
  @override
  // ignore: no_logic_in_create_state
  State<EditableListForm> createState() => _EditableListFormState(
        GlobalKey<FormBuilderState>(),
      );

  void persistItem(Map<String, dynamic> map) {
    try {
      final editableListItem = EditableListItem<T>(
        item: mapToItem(map),
        selected: false,
      );
      log.d('About to save item: $editableListItem');
      if (item == null) {
        listNotifier.addItem(editableListItem);
      } else {
        listNotifier.editItem(editableListItem);
      }
    } catch (error) {
      log.e('There was an issue adding new item: $error');
    }
  }
}

class _EditableListFormState extends State<EditableListForm> {
  static final log = logger(EditableListForm);

  static const uuid = Uuid();

  final GlobalKey<FormBuilderState> _formKey;

  final Map<String, bool> _hasError = {};

  _EditableListFormState(this._formKey) {
    Future.delayed(const Duration(milliseconds: 10)).then((_) {
      setState(() {
        log.d('Initialising the hasError map.');
        for (final key in widget.formItemDefinitions.keys) {
          _hasError[key] =
              !(_formKey.currentState?.fields[key]?.validate() ?? true);
          log.d('- hasError($key): ${_hasError[key]}');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final JsonMap initialValues = _generateInitialValues();

    final fields = widget.formItemDefinitions.keys.map((key) {
      final fieldDefinition = widget.formItemDefinitions[key];
      final String? initialValue =
          initialValues[key] is String ? initialValues[key] as String : null;
      // TODO: Add field type tp definition and support other types of fields
      return FormBuilderTextField(
        autovalidateMode: AutovalidateMode.always,
        name: key,
        enabled: !fieldDefinition!.readOnly,
        decoration: InputDecoration(
          labelText: widget.formItemDefinitions[key]!.label,
          suffixIcon: _hasError[key] ?? true
              ? const Icon(Icons.error, color: Colors.red)
              : const Icon(Icons.check, color: Colors.green),
        ),
        onChanged: (val) {
          setState(() {
            log.d('-- Setting hasError($key): ${_hasError[key]}');
            _hasError[key] =
                !(_formKey.currentState?.fields[key]?.validate() ?? true);
          });
        },
        // valueTransformer: (text) => num.tryParse(text),
        validator: FormBuilderValidators.compose(
          widget.formItemDefinitions[key]!.validators,
        ),
        initialValue: initialValue,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilder(
        key: _formKey,
        // enabled: false,
        onChanged: () {
          _formKey.currentState!.save();
          log.d(_formKey.currentState!.value.toString());
        },
        autovalidateMode: AutovalidateMode.disabled,
        initialValue: initialValues,
        skipDisabled: true,
        child: Column(
          children: [
            ...fields,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: allValid()
                      ? () {
                          _persistItem();
                          Navigator.of(context).pop();
                        }
                      : null,
                  icon: const Icon(FontAwesomeIcons.floppyDisk),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  JsonMap _generateInitialValues() {
    if (widget.item == null) {
      log.d('Generating initial values from definition.');
      return widget.formItemDefinitions.map(
        (key, definition) => MapEntry(
          key,
          definition.isUUID ? uuid.v4() : definition.initialValue,
        ),
      );
    } else {
      final initialValues = widget.item!.toJson();
      log.d('Generating initial values from item: $initialValues');
      return initialValues;
    }
  }

  bool allValid() {
    for (final key in _hasError.keys) {
      log.d('-- hasError($key): ${_hasError[key]}');
      if (_hasError[key] == true) return false;
    }
    return true;
  }

  void _persistItem() {
    _formKey.currentState!.save();

    final map = {..._formKey.currentState!.value};
    if (map['id'] == null) {
      map['id'] = uuid.v4();
      log.d('Added an ID to the item: ${map['id']}');
    }

    widget.persistItem(map);
  }
}
