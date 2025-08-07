// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:study_sync/core/constants/app_router_constants.dart';
// import 'package:study_sync/core/services/auth_service.dart';
// import 'package:study_sync/features/authLogin/presentation/widgets/error_dialog.dart';

// mixin AuthHandlersMixin<T extends StatefulWidget> on State<T> {
  
//   Future<void> handleGoogleSignIn({
//     required BuildContext context,
//     required String? userRole,
//     required String? institutionName,
//     required String? teacherName,
//     required bool isLoading,
//     required Function(bool) setLoading,
//   }) async {
//     if (isLoading || !mounted) return;

//     if (institutionName == null) {
//       ErrorDialogHelper.show(
//         context,
//         'Institution name is required. Please go back and try again.',
//       );
//       return;
//     }

//     if (userRole == 'student' && teacherName == null) {
//       ErrorDialogHelper.show(
//         context,
//         'Teacher name is required for students. Please go back and try again.',
//       );
//       return;
//     }

//     setLoading(true);

//     try {
//       Map<String, dynamic> result;

//       if (userRole == 'teacher') {
//         result = await AuthService.signInWithGoogleTeacher(
//           institutionName: institutionName,
//           additionalData: {'signInTimestamp': DateTime.now().toIso8601String()},
//         );
//       } else {
//         result = await AuthService.signInWithGoogleStudent(
//           institutionName: institutionName,
//           teacherName: teacherName!,
//           additionalData: {'signInTimestamp': DateTime.now().toIso8601String()},
//         );
//       }

//       if (mounted && result['success']) {
//         _navigateToDashboard(context, userRole);
//       } else if (mounted) {
//         ErrorDialogHelper.show(context, result['message']);
//       }
//     } catch (e) {
//       if (mounted) {
//         ErrorDialogHelper.show(context, 'An unexpected error occurred. Please try again.');
//       }
//     } finally {
//       if (mounted) {
//         setLoading(false);
//       }
//     }
//   }

//   Future<void> handleAppleSignIn({
//     required BuildContext context,
//     required String? userRole,
//     required String? institutionName,
//     required bool isLoading,
//     required Function(bool) setLoading,
//   }) async {
//     if (isLoading || !mounted) return;

//     if (institutionName == null) {
//       ErrorDialogHelper.show(
//         context,
//         'Institution name is required. Please go back and try again.',
//       );
//       return;
//     }

//     setLoading(true);

//     try {
//       Map<String, dynamic> result;

//       if (userRole == 'teacher') {
//         result = await AuthService.signInWithAppleTeacher(
//           institutionName: institutionName,
//           additionalData: {'signInTimestamp': DateTime.now().toIso8601String()},
//         );
//       } else {
//         ErrorDialogHelper.show(context, 'Apple sign in for students is not available yet.');
//         return;
//       }

//       if (mounted && result['success']) {
//         _navigateToDashboard(context, userRole);
//       } else if (mounted) {
//         ErrorDialogHelper.show(context, result['message']);
//       }
//     } catch (e) {
//       if (mounted) {
//         ErrorDialogHelper.show(context, 'An unexpected error occurred. Please try again.');
//       }
//     } finally {
//       if (mounted) {
//         setLoading(false);
//       }
//     }
//   }

//   void _navigateToDashboard(BuildContext context, String? userRole) {
//     if (userRole == 'teacher') {
//       context.pushReplacementNamed(AppRouterConstants.teacherDashboard);
//     } else {
//       context.pushReplacementNamed(AppRouterConstants.studentDashboard);
//     }
//   }
// }