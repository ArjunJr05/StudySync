import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_router_constants.dart';

/// A utility class to handle form validation and navigation for the verification process.
class FormNavigationHandler {
  /// Handles navigation for the teacher verification form.
  /// Validates the form and pushes the user to the sign-in page with the necessary data.
  static void handleTeacherContinue({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController institutionController,
    required TextEditingController teacherNameController,
  }) {
    // First, check if the form fields are valid.
    if (formKey.currentState!.validate()) {
      // Prepare the data payload to be sent to the sign-in screen.
      final teacherData = {
        'userType': 'teacher',
        'teacherName': teacherNameController.text.trim(),
        'institutionName': institutionController.text.trim(),
      };

      // MODIFIED: Using pushNamed instead of goNamed.
      // This adds the sign-in page to the navigation stack, allowing the user
      // to press 'back' to return to this verification page and edit details.
      GoRouter.of(context).pushNamed(
        AppRouterConstants.authSignIn,
        pathParameters: {'role': 'teacher'},
        extra: teacherData,
      );
    } else {
      // If validation fails, show a generic error message.
      _showValidationError(
        context,
        'Please fill in all required fields correctly.',
      );
    }
  }

  /// Handles navigation for the student verification form.
  /// Validates the form and pushes the user to the sign-in page with the necessary data.
  static void handleStudentContinue({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController institutionController,
    required TextEditingController teacherController,
  }) {
    if (formKey.currentState!.validate()) {
      final studentData = {
        'userType': 'student',
        'institutionName': institutionController.text.trim(),
        'teacherName': teacherController.text.trim(),
      };

      // MODIFIED: Using pushNamed for a better user experience.
      // This allows students to easily go back and change their selected
      // institution or teacher without restarting the entire process.
      GoRouter.of(context).pushNamed(
        AppRouterConstants.authSignIn,
        pathParameters: {'role': 'student'},
        extra: studentData,
      );
    } else {
      _showValidationError(
        context,
        'Please fill in all required fields correctly.',
      );
    }
  }

  /// Handles back navigation for verification forms, returning to the user selection screen.
  static void handleBackNavigation(BuildContext context) {
    GoRouter.of(context).goNamed(AppRouterConstants.findingUser);
  }

  /// Shows a standardized validation error message in a SnackBar.
  static void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- The rest of the validation and helper methods remain unchanged ---

  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return '$fieldName must not exceed 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return '$fieldName should only contain letters and spaces';
    }
    return null;
  }

  static String? validateInstitution(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your institution name';
    }
    if (value.trim().length < 3) {
      return 'Institution name must be at least 3 characters';
    }
    if (value.trim().length > 100) {
      return 'Institution name must not exceed 100 characters';
    }
    return null;
  }

  static String? validateTeacherName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your teacher's name";
    }
    if (value.trim().length < 2) {
      return 'Teacher name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Teacher name must not exceed 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(value.trim())) {
      return 'Teacher name should only contain letters, spaces, and periods';
    }
    return null;
  }
}
