import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/themes/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBgLightColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.titleColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const KText(
          text: "Privacy Policy",
          fontSize: 20,
          fontWeight: FontWeight.w600,
          textColor: AppColors.titleColor,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const KVerticalSpacer(height: 32),
            _buildSection(
              "1. Information We Collect",
              "We collect information you provide directly to us, such as when you create an account, use our services, or contact us. This may include your name, email address, and learning preferences.",
            ),
            _buildSection(
              "2. How We Use Your Information",
              "We use the information we collect to provide, maintain, and improve our services, process transactions, send you technical notices and support messages, and communicate with you about products and services.",
            ),
            _buildSection(
              "3. Information Sharing",
              "We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy. We may share your information with trusted partners who assist us in operating our services.",
            ),
            _buildSection(
              "4. Data Security",
              "We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.",
            ),
            _buildSection(
              "5. Data Retention",
              "We retain your personal information for as long as necessary to fulfill the purposes outlined in this policy, unless a longer retention period is required or permitted by law.",
            ),
            _buildSection(
              "6. Your Rights",
              "You have the right to access, update, or delete your personal information. You may also opt out of certain communications from us. Contact us if you wish to exercise these rights.",
            ),
            _buildSection(
              "7. Cookies and Analytics",
              "We use cookies and similar technologies to enhance your experience, analyze usage patterns, and improve our services. You can control cookie settings through your browser preferences.",
            ),
            _buildSection(
              "8. Children's Privacy",
              "Our services are not directed to children under 13. We do not knowingly collect personal information from children under 13. If we learn we have collected such information, we will delete it promptly.",
            ),
            _buildSection(
              "9. Changes to This Policy",
              "We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the 'Last updated' date.",
            ),
            _buildSection(
              "10. Contact Us",
              "If you have any questions about this Privacy Policy, please contact us at privacy@studysync.com",
            ),
            const KVerticalSpacer(height: 32),
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 48,
            color: AppColors.primaryColor,
          ),
          const KVerticalSpacer(height: 16),
          const KText(
            text: "Privacy Policy",
            fontSize: 24,
            fontWeight: FontWeight.w700,
            textColor: AppColors.titleColor,
            textAlign: TextAlign.center,
          ),
          const KVerticalSpacer(height: 8),
          KText(
            text: "Last updated: ${DateTime.now().toString().split(' ')[0]}",
            fontSize: 14,
            fontWeight: FontWeight.w400,
            textColor: AppColors.subTitleColor,
            textAlign: TextAlign.center,
          ),
          const KVerticalSpacer(height: 12),
          const KText(
            text:
                "We respect your privacy and are committed to protecting your personal data.",
            fontSize: 14,
            fontWeight: FontWeight.w500,
            textColor: AppColors.subTitleColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KText(
            text: title,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            textColor: AppColors.titleColor,
          ),
          const KVerticalSpacer(height: 8),
          KText(
            text: content,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            textColor: AppColors.subTitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 40, color: AppColors.primaryColor),
          const KVerticalSpacer(height: 12),
          const KText(
            text: "Your data security is our top priority.",
            fontSize: 16,
            fontWeight: FontWeight.w500,
            textColor: AppColors.titleColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
