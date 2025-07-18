

import 'dart:ui';

import 'package:checkutil/Componentes/colors.dart';
import 'package:flutter/material.dart';


Gradient primarySplitBillLinearGradient() {
  return const LinearGradient(
    colors: [bottomNavBackgroundColor, lightBackgroundColor],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    tileMode: TileMode.mirror,
  );
}

Gradient primarySplitBillLightGradient() {
  return const LinearGradient(
    colors: [primarySplitBillColor, Colors.white],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    tileMode: TileMode.mirror,
    stops: [0.4, 1],
  );
}
