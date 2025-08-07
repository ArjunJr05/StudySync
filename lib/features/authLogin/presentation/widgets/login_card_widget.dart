import 'package:flutter/material.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/authLogin/presentation/widgets/sign_in_button.dart';

class LoginCardWidget extends StatelessWidget {
  final String? userRole;
  final double screenHeight;
  final double screenWidth;
  final bool isSmallScreen;
  final bool isLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;

  const LoginCardWidget({
    super.key,
    required this.userRole,
    required this.screenHeight,
    required this.screenWidth,
    required this.isSmallScreen,
    required this.isLoading,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = userRole == 'teacher' 
        ? const Color(0xFF26BDCF) 
        : AppColors.primaryColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.08),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRoleIndicator(cardColor),
          SizedBox(height: screenHeight * 0.025),
          SignInButtonsWidget(
            onGoogleSignIn: onGoogleSignIn,
            onAppleSignIn: onAppleSignIn,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleIndicator(Color cardColor) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.008,
      ),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            userRole == 'teacher' ? Icons.school : Icons.person,
            color: cardColor,
            size: isSmallScreen ? 18 : 20,
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            userRole == 'teacher' ? 'Teacher Account' : 'Student Account',
            style: TextStyle(
              color: cardColor,
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}