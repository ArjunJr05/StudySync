import 'package:concentric_transition/concentric_transition.dart';
import 'package:studysync/core/constants/app_assets_constants.dart';
import 'package:studysync/core/themes/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:studysync/features/on_boarding/presentation/widgets/study_sync_concentric_card.dart';
import 'package:studysync/features/on_boarding/presentation/widgets/study_sync_on_boarding_data.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data
    final data = [
      studysyncCardData(
        title: "Interactive Learning",
        subTitle:
            "Access engaging courses, video lectures, and interactive content designed for effective learning.",
        lottieAssetIconName: AppAssetsConstants.starAnimation,
        titleColor: AppColors.secondaryColor,
        subTitleColor: AppColors.secondaryColor.withOpacity(0.8),
        backgroundColor: AppColors.primaryColor,
      ),
      studysyncCardData(
        title: "Track Your Progress",
        subTitle:
            "Monitor your learning journey with detailed analytics, grades, and completion rates.",
        lottieAssetIconName: AppAssetsConstants.alienAnimation,
        titleColor: Colors.black,
        subTitleColor: Colors.black87,
        backgroundColor: const Color(0xFFD0F5D8),
      ),
      studysyncCardData(
        title: "Study Smart",
        subTitle:
            "Set study schedules, get assignment reminders, and access offline content anytime.",
        lottieAssetIconName: AppAssetsConstants.emojiAnimation,
        titleColor: AppColors.secondaryColor,
        subTitleColor: AppColors.secondaryColor.withOpacity(0.9),
        backgroundColor: AppColors.primaryColor,
      ),
      studysyncCardData(
        title: "Connect & Collaborate",
        subTitle:
            "Join study groups, discuss with peers, and get support from instructors and mentors.",
        lottieAssetIconName: AppAssetsConstants.successAnimation,
        titleColor: AppColors.secondaryColor,
        subTitleColor: AppColors.secondaryColor.withOpacity(0.8),
        backgroundColor: const Color(0xFF162B36),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      body: ConcentricPageView(
        itemCount: data.length,
        physics: const BouncingScrollPhysics(),
        colors: const [
          AppColors.primaryColor,
          Color(0xFFD0F5D8), // pastel green
          Color(0xFF80CBC4), // teal
          Color(0xFF162B36), // dark blue
        ],
        itemBuilder: (int index) {
          return studysyncConcentricCard(data: data[index]);
        },
        onChange: (index) {
          debugPrint('Page changed to index $index');
        },
        // onFinish: () {
        //   // Navigate to authentication or main app screen
        //   GoRouter.of(context)
        //       .pushReplacementNamed(AppRouterConstants.authSignUp);
        // },
      ),
    );
  }
}
