import 'package:flutter/material.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/authLogin/presentation/widgets/animated_logo.dart';

class LoginHeaderWidget extends StatelessWidget {
  final String? userRole;
  final String? institutionName;
  final double screenHeight;
  final double screenWidth;
  final bool isSmallScreen;

  const LoginHeaderWidget({
    super.key,
    required this.userRole,
    required this.institutionName,
    required this.screenHeight,
    required this.screenWidth,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = isSmallScreen ? screenWidth * 0.25 : screenWidth * 0.3;

    return Column(
      children: [
        // Logo
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(logoSize * 0.17),
            child: const AnimatedLogoWidget(),
          ),
        ),

        SizedBox(height: screenHeight * 0.02),

        // Welcome Message
        _buildWelcomeMessage(context),

        // Institution Info
        if (institutionName != null) _buildInstitutionInfo(context),
      ],
    );
  }

  Widget _buildWelcomeMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome Back!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
            fontSize: isSmallScreen ? 24 : 28,
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        Text(
          userRole == 'teacher'
              ? 'Sign in to manage your courses'
              : 'Sign in to continue learning',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 14 : 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInstitutionInfo(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: screenHeight * 0.015),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.008,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        institutionName!,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: isSmallScreen ? 12 : 14,
        ),
      ),
    );
  }
}