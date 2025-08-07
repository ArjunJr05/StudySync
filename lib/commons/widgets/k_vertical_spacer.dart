import 'package:flutter/material.dart';

class KVerticalSpacer extends StatelessWidget {
  final double height;
  const KVerticalSpacer({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
    );
  }
}
