// lib/features/authLogin/presentation/widgets/sign_in_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/themes/app_colors.dart';

class SignInButtonsWidget extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final bool isLoading;

  const SignInButtonsWidget({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign In Button
        _buildEnhancedSignInButton(
          text: "Continue with Google",
          onPressed: isLoading ? null : onGoogleSignIn,
          backgroundColor: AppColors.secondaryColor,
          textColor: AppColors.titleColor,
          svgIconPath: "assets/icons/svg/google.svg",
          borderColor: Colors.grey.shade200,
          isEnabled: !isLoading,
        ),

        const KVerticalSpacer(height: 16),

        // Apple Sign In Button
        _buildEnhancedSignInButton(
          text: "Continue with Apple",
          onPressed: isLoading ? null : onAppleSignIn,
          backgroundColor: AppColors.secondaryColor,
          textColor: AppColors.titleColor,
          svgIconPath: "assets/icons/svg/apple.svg",
          borderColor: AppColors.titleColor,
          isEnabled: !isLoading,
        ),

        if (isLoading) ...[
          const KVerticalSpacer(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              KText(
                text: 'Signing you in...',
                fontSize: 14,
                textColor: Colors.grey[600],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedSignInButton({
    required String text,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color textColor,
    required String svgIconPath,
    required Color borderColor,
    required bool isEnabled,
  }) {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            isEnabled
                ? [
                  BoxShadow(
                    color:
                        backgroundColor == AppColors.secondaryColor
                            ? Colors.grey.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ]
                : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: isEnabled ? backgroundColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isEnabled
                        ? borderColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SVG Icon with fallback to regular icons
                _buildIcon(svgIconPath, isEnabled, textColor),
                const SizedBox(width: 12),
                KText(
                  text: text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  textColor: isEnabled ? textColor : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String svgIconPath, bool isEnabled, Color textColor) {
    try {
      return SvgPicture.asset(
        svgIconPath,
        height: 24,
        width: 24,
        colorFilter:
            isEnabled
                ? null
                : ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn),
      );
    } catch (e) {
      // Fallback to regular icons if SVG assets are not available
      IconData iconData;
      if (svgIconPath.contains('google')) {
        iconData = Icons.g_mobiledata;
      } else if (svgIconPath.contains('apple')) {
        iconData = Icons.apple;
      } else {
        iconData = Icons.login;
      }

      return Icon(
        iconData,
        size: 24,
        color: isEnabled ? textColor : Colors.grey[400],
      );
    }
  }
}
