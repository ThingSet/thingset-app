// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        // maintain type of original data (default would be String)
        var numValue = num.tryParse(value);
        if (widget.value is num && numValue != null) {
          widget.onChanged(numValue);
        } else {
          widget.onChanged(value);
        }
      },
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        isDense: true,
        suffixText: widget.unit,
      ),
      controller: controller,
      keyboardType:
          widget.value is num ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (widget.value is num)
          FilteringTextInputFormatter.allow(RegExp('[0-9.-]')),
        if (widget.value is num)
          TextInputFormatter.withFunction(
              (TextEditingValue oldValue, TextEditingValue newValue) {
            if (['-', '-.', '.', ''].contains(newValue.text)) {
              // allow starting with decimal dot or minus sign
              return newValue;
            } else {
              // otherwise check if the value can be parsed into double
              try {
                double.parse(newValue.text);
                return newValue;
              } catch (e) {
                return oldValue;
              }
            }
          }),
      ],
    );
  }
}
