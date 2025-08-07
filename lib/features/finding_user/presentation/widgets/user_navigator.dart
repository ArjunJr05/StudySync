import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_router_constants.dart';

void navigateToLogin(BuildContext context, String role) {
  HapticFeedback.lightImpact();

  // Check if context is still mounted before navigation
  if (!context.mounted) return;

  if (role == 'teacher') {
    // Option 1: If you have a separate teacher verification screen
    // GoRouter.of(context).pushReplacementNamed(AppRouterConstants.teacherVerify);

    // Option 2: Use the same verification screen but pass the role as extra data
    GoRouter.of(context).pushReplacementNamed(
      AppRouterConstants.teacherVerify,
      extra: {'role': role},
    );
  } else if (role == 'student') {
    // Navigate to student verification page
    GoRouter.of(context).pushReplacementNamed(
      AppRouterConstants.studentVerify,
      extra: {'role': role},
    );
  }
}
