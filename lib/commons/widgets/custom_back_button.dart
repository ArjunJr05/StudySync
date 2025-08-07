// lib/commons/widgets/custom_back_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Animation<double>? animation;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final EdgeInsetsGeometry? padding;

  const CustomBackButton({
    super.key,
    required this.onPressed,
    this.animation,
    this.backgroundColor,
    this.iconColor,
    this.size = 20,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    Widget backButton = Padding(
      padding: padding!,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: (backgroundColor ?? Colors.white).withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: size,
                    color: iconColor ?? Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (animation != null) {
      return FadeTransition(
        opacity: animation!,
        child: backButton,
      );
    }

    return backButton;
  }
}