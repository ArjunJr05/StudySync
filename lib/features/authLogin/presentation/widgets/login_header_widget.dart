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
        AnimatedLogoWidget(),

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
  // Calculate text width to determine container size
  final textStyle = TextStyle(
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w600,
    fontSize: isSmallScreen ? 12 : 14,
  );
  
  final textPainter = TextPainter(
    text: TextSpan(text: institutionName!, style: textStyle),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  
  // Calculate required width: text width + icon width + spacing + padding
  final iconWidth = 20.0;
  final spacing = 8.0;
  final horizontalPadding = screenWidth * 0.04 * 2; // left + right padding
  final borderWidth = 2.0; // 1px border on each side
  
  final requiredWidth = textPainter.size.width + iconWidth + spacing + horizontalPadding + borderWidth;
  
  // Set maximum width to prevent overflow (90% of screen width)
  final maxWidth = screenWidth * 0.9;
  final containerWidth = requiredWidth > maxWidth ? maxWidth : requiredWidth;
  
  return Container(
    width: containerWidth,
    margin: EdgeInsets.only(top: screenHeight * 0.015),
    padding: EdgeInsets.symmetric(
      horizontal: screenWidth * 0.03,
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
    child: Row(
      mainAxisSize: MainAxisSize.min, // This helps the row take minimum required space
      children: [
        Icon(Icons.school, color: AppColors.primaryColor, size: 20),
        SizedBox(width: 8), // spacing between icon and text
        Flexible( // Changed from Expanded to Flexible
          child: Text(
            institutionName!,
            style: textStyle,
            overflow: TextOverflow.ellipsis, // prevent overflow
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    ),
  );

  }
}