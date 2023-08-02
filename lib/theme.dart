// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';

const primaryColor = Color(0xFF005E83);
const secondaryColor = Color(0xFF52595D);
const accentColor = Color(0xFFF1DD38);

final ColorScheme lightScheme = ColorScheme.fromSeed(
  brightness: Brightness.light,
  seedColor: primaryColor,
  secondary: secondaryColor,
  tertiary: accentColor,
);

final ColorScheme darkSheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: primaryColor,
  secondary: secondaryColor,
  tertiary: accentColor,
);

final theme = ThemeData(colorScheme: lightScheme);
