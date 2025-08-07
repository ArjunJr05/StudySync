import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_router_constants.dart';
import 'package:studysync/core/services/auth_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/authLogin/presentation/widgets/animated_logo.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment:  MainAxisAlignment.center,
          
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AnimatedLogoWidget(),
            const SizedBox(height: 40),
            const Text(
              'Request Sent!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your request to join has been sent to your teacher for approval. Please check back later.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                await AuthService.signOut();
                if (context.mounted) {
                  context.goNamed(AppRouterConstants.findingUser);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ThemeRedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}