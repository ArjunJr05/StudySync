import 'package:studysync/features/authLogin/presentation/widgets/animated_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_router_constants.dart';
import 'package:studysync/core/services/auth_service.dart';
import 'package:studysync/core/themes/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndNavigate();
  }

  /// Checks if a user is logged in and navigates them to the correct screen.
  Future<void> _checkLoginStatusAndNavigate() async {
    // Wait for a moment to let the splash animation play.
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      final authService = AuthService();
      final loggedIn = await authService.isLoggedIn();

      if (loggedIn) {
        final userDetails = await authService.getUserDetails();
        final role = userDetails['role'];
        final id = userDetails['id'];
        final institutionName = userDetails['institutionName'];
        final teacherName = userDetails['teacherName'];

        print('🔍 Splash: User logged in - Role: $role, ID: $id');

        // Navigate based on the user's role and saved data.
        if (role == 'teacher' && id != null && institutionName != null) {
          print('👨‍🏫 Navigating to teacher dashboard');
          context.goNamed(
            AppRouterConstants.teacherMain,
            pathParameters: {
              'teacherId': id,
              'institutionName': institutionName,
            },
          );
        } else if (role == 'student' &&
            id != null &&
            institutionName != null &&
            teacherName != null) {
          
          print('👨‍🎓 Checking student approval status...');
          
          // Check student approval status before navigating
          try {
            final approvalStatus = await authService.checkStudentApprovalStatus(id);
            print('📊 Student approval status: $approvalStatus');
            
            switch (approvalStatus) {
              case 'accepted':
                print('✅ Student accepted - navigating to main dashboard');
                context.goNamed(
                  AppRouterConstants.studentMain,
                  pathParameters: {
                    'studentId': id,
                    'institutionName': institutionName,
                    'teacherName': teacherName,
                  },
                );
                break;
                
              case 'pending':
                print('⏳ Student pending - navigating to waiting page');
                context.goNamed(
                  AppRouterConstants.studentWaiting,
                  pathParameters: {
                    'studentId': id,
                    'institutionName': institutionName,
                    'teacherName': teacherName,
                  },
                );
                break;
                
              case 'rejected':
                print('❌ Student rejected - clearing session');
                await AuthService.signOut();
                if (mounted) {
                  context.goNamed(AppRouterConstants.findingUser);
                }
                break;
                
              default:
                print('❓ Unknown status - going to waiting page as fallback');
                context.goNamed(
                  AppRouterConstants.studentWaiting,
                  pathParameters: {
                    'studentId': id,
                    'institutionName': institutionName,
                    'teacherName': teacherName,
                  },
                );
                break;
            }
          } catch (e) {
            print('❌ Error checking student approval status: $e');
            // On error, send to waiting page to maintain user session
            print('🔄 Network error - defaulting to waiting page for logged-in student');
            context.goNamed(
              AppRouterConstants.studentWaiting,
              pathParameters: {
                'studentId': id,
                'institutionName': institutionName,
                'teacherName': teacherName,
              },
            );
          }
        } else {
          print('⚠️ Incomplete session data - going to finder');
          // If session data is incomplete, default to the finder page.
          context.goNamed(AppRouterConstants.findingUser);
        }
      } else {
        print('🚫 User not logged in - going to finder');
        // If not logged in, navigate to the finder page.
        context.goNamed(AppRouterConstants.findingUser);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      body: Center(
        child: AnimatedLogoWidget(),
      ),
    );
  }
}