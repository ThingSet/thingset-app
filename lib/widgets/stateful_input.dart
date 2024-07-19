// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../clients/thingset.dart';

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
  late bool isNum = false;
  late bool isList = false;

  @override
  void initState() {
    super.initState();
    if (widget.value is num) {
      isNum = true;
      controller.text = widget.value.toString();
    } else if (widget.value is List) {
      isList = true;
      controller.text = widget.value.join(', ');
    } else {
      controller.text = widget.value.toString();
    }
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
        if (isNum) {
          widget.onChanged(num.tryParse(value));
        } else if (isList) {
          try {
            widget.onChanged(jsonDecode('[$value]'));
          } catch (e) {
            // ignore invalid data
          }
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
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (isNum) FilteringTextInputFormatter.allow(RegExp('[0-9.-]')),
        if (isNum)
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

class StatefulExec extends StatefulWidget {
  final dynamic params;
  final String description;
  final void Function(List<dynamic>) onPressed;

  const StatefulExec({
    super.key,
    required this.params,
    required this.description,
    required this.onPressed,
  });

  @override
  State<StatefulWidget> createState() => StatefulExecState();
}

class StatefulExecState extends State<StatefulExec> {
  List<dynamic> _paramValues = [];
  List<String> _paramNames = [];

  @override
  void initState() {
    if (widget.params is List &&
        widget.params.isNotEmpty &&
        widget.params
            .every((element) => element is String && element.isNotEmpty)) {
      _paramNames = List<String>.from(widget.params);
      _paramValues = List.generate(_paramNames.length, (int i) {
        switch (_paramNames[i][0]) {
          case 'n':
          case 'i':
            return 0;
          case 'f':
            return 0.0;
          case 'l':
            return false;
          default:
            return '';
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? paramsWidget;
    if (_paramNames.isNotEmpty) {
      paramsWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < _paramNames.length; i++)
            if (_paramNames[i][0] == 'n' ||
                _paramNames[i][0] == 'i' ||
                _paramNames[i][0] == 'f' ||
                _paramNames[i][0] == 'u')
              ListTile(
                title: Text(
                  thingsetSplitCamelCaseName(
                      _paramNames[i].split('_').first.substring(1)),
                ),
                trailing: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.4),
                  child: StatefulTextField(
                    value: _paramValues[i],
                    unit: thingsetParseUnit(_paramNames[i]),
                    onChanged: (value) {
                      _paramValues[i] = value;
                    },
                  ),
                ),
              )
            else if (_paramNames[i][0] == 'l')
              ListTile(
                title: Text(
                  thingsetSplitCamelCaseName(
                      _paramNames[i].split('_').first.substring(1)),
                ),
                trailing: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.4),
                  child: StatefulSwitch(
                    value: _paramValues[i],
                    onChanged: (value) {
                      _paramValues[i] = value;
                    },
                  ),
                ),
              )
        ],
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        tileColor: Theme.of(context).cardColor,
        title: OutlinedButton(
          child: Text(widget.description),
          onPressed: () {
            widget.onPressed(_paramValues);
          },
        ),
        subtitle: paramsWidget,
      ),
    );
  }
}
