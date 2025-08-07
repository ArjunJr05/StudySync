import 'package:flutter/material.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/authLogin/presentation/widgets/privacy_policy.dart';
import 'package:studysync/features/authLogin/presentation/widgets/terms_services.dart';

class TermsPolicyWidget extends StatelessWidget {
  const TermsPolicyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      child: Column(
        children: [
          Text(
            "By continuing, you agree to our",
            style: TextStyle(
              color: AppColors.subTitleColor,
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.008),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsOfServicePage(),
                      ),
                    ),
                child: Text(
                  "Terms of Service",
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryColor,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                child: Text(
                  "&",
                  style: TextStyle(
                    color: AppColors.subTitleColor,
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    ),
                child: Text(
                  "Privacy Policy",
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
