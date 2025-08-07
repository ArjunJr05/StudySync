import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/extension/responsive_extension.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:studysync/features/on_boarding/presentation/widgets/study_sync_on_boarding_data.dart';

class studysyncConcentricCard extends StatelessWidget {
  const studysyncConcentricCard({super.key, required this.data});

  final studysyncCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          LottieBuilder.asset(data.lottieAssetIconName, fit: BoxFit.cover),
          const Spacer(flex: 1),

          // Title
          KText(
            textAlign: TextAlign.center,
            text: data.title,
            fontSize: context.responsiveFont(22),
            fontWeight: FontWeight.w600,
            textColor: data.titleColor,
          ),

          KVerticalSpacer(height: 4),

          // SubTitle
          KText(
            textAlign: TextAlign.center,
            text: data.subTitle,
            fontSize: context.responsiveFont(16),
            fontWeight: FontWeight.w500,
            textColor: data.subTitleColor,
          ),

          KVerticalSpacer(height: 10),
        ],
      ),
    );
  }
}
