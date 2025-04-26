import 'package:flutter/material.dart';
import 'package:wt_logging/wt_logging.dart';

class SearchOrdersByName extends StatefulWidget {
  static final log = logger(SearchOrdersByName);

  final void Function(String value) onChange;

  const SearchOrdersByName({
    super.key,
    required this.onChange,
  });

  @override
  State<SearchOrdersByName> createState() => _SearchOrdersByNameState();
}

class _SearchOrdersByNameState extends State<SearchOrdersByName> {
  late TextEditingController _controller;

  _SearchOrdersByNameState() {
    _controller = TextEditingController();
    _controller.addListener(onChange);
  }

  void onChange() {
    widget.onChange(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 8.0,
        top: 4,
      ),
      child: TextField(
        onChanged: (value) {},
        controller: _controller,
        // textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          labelText: 'Search Name',
          hintText: '',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: _controller.clear,
            icon: const Icon(Icons.clear),
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(onChange);
    _controller.dispose();
    super.dispose();
  }
}
