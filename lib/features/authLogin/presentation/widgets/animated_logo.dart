import 'package:flutter/material.dart';
import 'package:studysync/core/themes/app_colors.dart';

class AnimatedLogoWidget extends StatelessWidget {
  const AnimatedLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -5 * (1 - value)),
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  blurRadius: 60,
                  offset: const Offset(0, 30),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background glow effect
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                // Main icon
                const Icon(
                  Icons.school_rounded,
                  size: 70,
                  color: AppColors.secondaryColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
