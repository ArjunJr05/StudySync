import 'package:studysync/core/themes/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class KSnackBar {
  static void success(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppColors.checkInColor,
      icon: Icons.check_circle_outline,
    );
  }

  static void failure(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppColors.checkOutColor,
      icon: Icons.error_outline,
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          spacing: 12,
          children: [
            Icon(icon, color: AppColors.secondaryColor),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.jost(color: AppColors.secondaryColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        closeIconColor: AppColors.secondaryColor,
        showCloseIcon: true,
        dismissDirection: DismissDirection.down,
      ),
    );
  }
}
