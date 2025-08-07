// lib/features/authLogin/presentation/utils/route_data_extractor.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteData {
  final String? userRole;
  final String? institutionName;
  final String? teacherName;

  RouteData({
    this.userRole,
    this.institutionName,
    this.teacherName,
  });
}

class RouteDataExtractor {
  static RouteData extractFromContext(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    
    if (extra != null) {
      return RouteData(
        userRole: extra['role'] as String?,
        institutionName: extra['institutionName'] as String?,
        teacherName: extra['teacherName'] as String?,
      );
    }
    
    return RouteData();
  }
}