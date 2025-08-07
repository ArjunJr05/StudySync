import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/extension/responsive_extension.dart';
import 'package:studysync/core/themes/app_colors.dart';

Widget buildHeader(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Logo/Animation
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(Icons.school, size: 60, color: AppColors.primaryColor),
          ),

          KVerticalSpacer(height: 24),

          // Welcome Text
          KText(
            text: "Welcome to StudySync",
            fontSize: context.responsiveFont(28),
            fontWeight: FontWeight.bold,
            textColor: Colors.black87,
            textAlign: TextAlign.center,
          ),

          KVerticalSpacer(height: 8),

          KText(
            text: "Choose your role to get started",
            fontSize: context.responsiveFont(16),
            fontWeight: FontWeight.w400,
            textColor: Colors.black54,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
