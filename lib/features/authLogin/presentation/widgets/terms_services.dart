import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/themes/app_colors.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          text: "Terms of Service",
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
              "1. Acceptance of Terms",
              "By accessing and using StudySync, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.",
            ),
            _buildSection(
              "2. User Account",
              "When you create an account with us, you must provide information that is accurate, complete, and current at all times. You are responsible for safeguarding the password and for all activities that occur under your account.",
            ),
            _buildSection(
              "3. Acceptable Use",
              "You may not use our service for any illegal or unauthorized purpose. You must not, in the use of the service, violate any laws in your jurisdiction including but not limited to copyright laws.",
            ),
            _buildSection(
              "4. Privacy Policy",
              "Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our service.",
            ),
            _buildSection(
              "5. Intellectual Property",
              "The service and its original content, features, and functionality are and will remain the exclusive property of StudySync and its licensors. The service is protected by copyright, trademark, and other laws.",
            ),
            _buildSection(
              "6. Termination",
              "We may terminate or suspend your account and bar access to the service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation.",
            ),
            _buildSection(
              "7. Changes to Terms",
              "We reserve the right, at our sole discretion, to modify or replace these terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect.",
            ),
            _buildSection(
              "8. Contact Information",
              "If you have any questions about these Terms of Service, please contact us at terms@studysync.com",
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
            Icons.description_outlined,
            size: 48,
            color: AppColors.primaryColor,
          ),
          const KVerticalSpacer(height: 16),
          const KText(
            text: "Terms of Service",
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 32,
            color: AppColors.primaryColor.withOpacity(0.7),
          ),
          const KVerticalSpacer(height: 12),
          const KText(
            text: "Need Help?",
            fontSize: 16,
            fontWeight: FontWeight.w600,
            textColor: AppColors.titleColor,
            textAlign: TextAlign.center,
          ),
          const KVerticalSpacer(height: 8),
          const KText(
            text: "If you have any questions about these terms, please contact our support team at support@studysync.com",
            fontSize: 14,
            fontWeight: FontWeight.w400,
            textColor: AppColors.subTitleColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}