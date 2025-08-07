import 'package:flutter/material.dart';

class KHorizontalSpacer extends StatelessWidget {
  final double width;

  const KHorizontalSpacer({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width);
  }
}
