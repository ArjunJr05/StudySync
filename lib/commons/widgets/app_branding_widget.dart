// lib/commons/widgets/app_branding_widget.dart

import 'package:flutter/material.dart';
import 'package:studysync/core/themes/app_colors.dart';

class AppBrandingWidget extends StatelessWidget {
  final String role;
  final String? institutionName;
  final bool showInstitution;
  final double appNameSize;
  final double subtitleSize;
  final double roleIndicatorSize;

  const AppBrandingWidget({
    super.key,
    required this.role,
    this.institutionName,
    this.showInstitution = false,
    this.appNameSize = 32,
    this.subtitleSize = 16,
    this.roleIndicatorSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App Name
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ).createShader(bounds),
          child: Text(
            'StudySync',
            style: TextStyle(
              fontSize: appNameSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Learning Management System',
          style: TextStyle(
            fontSize: subtitleSize,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        
        // Role indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${role.toUpperCase()} LOGIN',
            style: TextStyle(
              fontSize: roleIndicatorSize,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        
        // Institution name (if provided and showInstitution is true)
        if (showInstitution && institutionName != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Text(
              institutionName!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}