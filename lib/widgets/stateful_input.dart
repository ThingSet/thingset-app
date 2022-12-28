import 'package:flutter/material.dart';

class StatefulSwitch extends StatefulWidget {
  final bool value;
  final void Function(bool) onChanged;

  const StatefulSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<StatefulWidget> createState() => StatefulSwitchState();
}

class StatefulSwitchState extends State<StatefulSwitch> {
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: (v) {
        setState(() {
          value = v;
          widget.onChanged(v);
        });
      },
    );
  }
}

class StatefulTextField extends StatefulWidget {
  final dynamic value;
  final String unit;
  final void Function(dynamic) onChanged;

  const StatefulTextField({
    super.key,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<StatefulWidget> createState() => StatefulTextFieldState();
}

class StatefulTextFieldState extends State<StatefulTextField> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.value.toString();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) {
        widget.onChanged(value);
      },
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        isDense: true,
        suffixText: widget.unit,
      ),
      controller: controller,
    );
  }
}
