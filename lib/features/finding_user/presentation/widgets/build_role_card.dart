import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/extension/responsive_extension.dart';
Widget buildRoleCard({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String gifPath, // local asset path or network URL
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // GIF Container
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                gifPath,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KText(
                  text: title,
                  fontSize: context.responsiveFont(18),
                  fontWeight: FontWeight.w600,
                  textColor: Colors.black87,
                ),
                KVerticalSpacer(height: 4),
                KText(
                  text: subtitle,
                  fontSize: context.responsiveFont(14),
                  fontWeight: FontWeight.w400,
                  textColor: Colors.black54,
                ),
              ],
            ),
          ),

          // Arrow Icon
          Icon(Icons.arrow_forward_ios, size: 20, color: color),
        ],
      ),
    ),
  );
}
