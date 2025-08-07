import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_router_constants.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/authLogin/presentation/widgets/auth_animations_mixin.dart';
import 'package:studysync/features/authLogin/presentation/widgets/login_header_widget.dart';
import 'package:studysync/features/authLogin/presentation/widgets/login_card_widget.dart';
import 'package:studysync/features/authLogin/presentation/widgets/route_data_extractor.dart';
import 'package:studysync/features/authLogin/presentation/widgets/terms_and_policy.dart';
import 'package:studysync/core/services/auth_service.dart';
import 'dart:async';

class AuthSignIn extends StatefulWidget {
  final String? role;
  const AuthSignIn({super.key, this.role});

  @override
  State<AuthSignIn> createState() => _AuthSignInState();
}

class _AuthSignInState extends State<AuthSignIn>
    with TickerProviderStateMixin, AuthAnimationsMixin {
  String? institutionName;
  String? teacherName; // For students to find their teacher
  String? userRole;
  String? _manualTeacherName; // For the teacher's own name
  bool isLoading = false;
  bool _hasExtractedRouteData = false;

  @override
  void initState() {
    super.initState();
    initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasExtractedRouteData) {
      _extractRouteData();
      _hasExtractedRouteData = true;
    }
  }

  void _extractRouteData() {
    try {
      final routeData = RouteDataExtractor.extractFromContext(context);
      institutionName = routeData.institutionName?.trim();
      teacherName = routeData.teacherName?.trim();
      userRole = routeData.userRole?.trim() ?? widget.role?.trim();

      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic> &&
          userRole?.toLowerCase() == 'teacher') {
        _manualTeacherName = extra['teacherName']?.toString().trim();
      }
    } catch (e) {
      print('Error extracting route data: $e');
      _showErrorDialog(
        'Failed to get page data. Please go back and try again.',
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (isLoading || !mounted) return;

    final validationError = _validateSignInData();
    if (validationError != null) {
      _showErrorDialog(validationError);
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = AuthService();
      final role = userRole!.toLowerCase();
      Map<String, dynamic> result;

      if (role == 'teacher') {
        result = await authService.signInWithGoogleTeacher(
          institutionName: institutionName!,
          teacherName: _manualTeacherName!,
        );
      } else if (role == 'student') {
        result = await authService.signInWithGoogleStudent(
          institutionName: institutionName!,
          teacherName: teacherName!,
        );
      } else {
        _showErrorDialog("Invalid user role: $role. Please try again.");
        return;
      }

      if (mounted) await _handleSignInResult(result);
    } catch (e) {
      if (mounted) {
        _showErrorDialog("An error occurred during sign-in: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String? _validateSignInData() {
    if (_isStringNullOrEmpty(institutionName)) {
      return 'Institution name is missing.';
    }
    if (_isStringNullOrEmpty(userRole)) {
      return 'User role is not specified.';
    }
    final role = userRole!.toLowerCase();
    if (role != 'teacher' && role != 'student') {
      return 'Invalid user role.';
    }
    if (role == 'teacher' && _isStringNullOrEmpty(_manualTeacherName)) {
      return 'Teacher name could not be found. Please go back and select it.';
    }
    if (role == 'student' && _isStringNullOrEmpty(teacherName)) {
      return 'Teacher name is required for student login.';
    }
    return null;
  }

  // **CORRECTED LOGIC**
  Future<void> _handleSignInResult(Map<String, dynamic> result) async {
    print('📊 Handling sign-in result: $result');

    if (result['success'] == true) {
      // 1. Show a success message regardless of status
      final message = result['message'] ?? 'Sign-in successful!';
      _showSuccessSnackBar(message);

      // 2. Wait a moment for the user to see the snackbar
      await Future.delayed(const Duration(milliseconds: 1200));

      // 3. ALWAYS navigate. The destination is determined in the navigation method.
      if (mounted) {
        _navigateToHomepage(result);
      }
    } else {
      // Handle failure case
      print('❌ Sign-in failed: ${result['message']}');
      _showErrorDialog(result['message'] ?? 'Sign-in failed.');
    }
  }

  // **NO CHANGES NEEDED HERE - THIS LOGIC IS ALREADY CORRECT**
  void _navigateToHomepage(Map<String, dynamic> signInResult) {
    if (!mounted) return;

    try {
      final role = (signInResult['userRole'] as String?)?.toLowerCase();
      final status = (signInResult['status'] as String?)?.toLowerCase();
      print('🏠 Navigating based on role: $role, status: $status');

      if (role == 'teacher') {
        // Teacher Navigation
        final teacherId = signInResult['teacherId'] as String?;
        final institution = signInResult['institutionName'] as String?;
        if (_isStringNullOrEmpty(teacherId) ||
            _isStringNullOrEmpty(institution)) {
          throw Exception('Missing teacher data for navigation.');
        }
        context.pushReplacementNamed(
          AppRouterConstants.teacherMain,
          pathParameters: {
            'teacherId': teacherId!,
            'institutionName': institution!,
          },
        );
      } else if (role == 'student') {
        // Student Navigation
        final studentId = signInResult['studentId'] as String?;
        final institution = signInResult['institutionName'] as String?;
        final teacher = signInResult['teacherName'] as String?;

        if (_isStringNullOrEmpty(studentId) ||
            _isStringNullOrEmpty(institution) ||
            _isStringNullOrEmpty(teacher)) {
          throw Exception('Missing student data for navigation.');
        }

        // ROUTING LOGIC: If pending, go to waiting page. Otherwise, go to dashboard.
        if (status == 'pending') {
          context.pushReplacementNamed(
            AppRouterConstants.studentWaiting,
            pathParameters: {
              'studentId': studentId!,
              'institutionName': institution!,
              'teacherName': teacher!,
            },
          );
          print('✅ Navigated to Student Waiting Page.');
        } else if (status == 'accepted') {
          context.pushReplacementNamed(
            AppRouterConstants.studentMain,
            pathParameters: {
              'studentId': studentId!,
              'institutionName': institution!,
              'teacherName': teacher!,
            },
          );
          print('✅ Navigated to Student Dashboard.');
        } else {
          // Handle other statuses like 'rejected' if necessary,
          // for now, we can route back to login.
          context.goNamed(AppRouterConstants.findingUser);
        }
      } else {
        throw Exception('Invalid role for navigation: "$role"');
      }
    } catch (e) {
      print('❌ Navigation error: $e');
      _showErrorDialog(
        'Could not open your dashboard. Please restart the app.',
      );
    }
  }

  bool _isStringNullOrEmpty(String? value) =>
      value == null || value.trim().isEmpty;

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign-In Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The rest of your build method remains unchanged...
    // I'm omitting it here for brevity but it should be included in your file.
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: AppColors.primaryColor),
          onPressed: () => context.goNamed(AppRouterConstants.findingUser),
        ),
      ),
      body: SingleChildScrollView(
        child: AnimatedBuilder(
          animation: fadeAnimation,
          builder: (context, child) => Opacity(
            opacity: fadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  LoginHeaderWidget(
                    userRole: userRole,
                    institutionName: institutionName,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(
                    height: screenHeight * (isSmallScreen ? 0.03 : 0.04),
                  ),
                  AnimatedBuilder(
                    animation: scaleAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: scaleAnimation.value,
                      child: LoginCardWidget(
                        userRole: userRole,
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                        isSmallScreen: isSmallScreen,
                        isLoading: isLoading,
                        onGoogleSignIn: _handleGoogleSignIn,
                        onAppleSignIn: () {
                          _showErrorDialog(
                            "Apple Sign-In is under development.",
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  const TermsPolicyWidget(),
                  SizedBox(height: screenHeight * 0.01),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    disposeAnimations();
    super.dispose();
  }
}