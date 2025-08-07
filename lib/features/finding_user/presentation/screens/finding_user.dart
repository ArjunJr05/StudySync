import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/features/finding_user/presentation/widgets/build_header.dart';
import 'package:studysync/features/finding_user/presentation/widgets/build_role_card.dart';
import 'package:studysync/features/finding_user/presentation/widgets/user_navigator.dart';

class FindingUser extends StatefulWidget {
  const FindingUser({super.key});

  @override
  State<FindingUser> createState() => _FindingUserState();
}

class _FindingUserState extends State<FindingUser>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // App Logo and Welcome
                    buildHeader(context),

                    const Spacer(flex: 2),

                    // Role Selection Cards
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Column(
                            children: [
                              buildRoleCard(
                                context: context,
                                title: "I'm a Student",
                                subtitle:
                                    "Access courses, track progress, and learn",
                                gifPath:
                                    'assets/gifs/student.gif', // or use Image.network if it's online
                                color: AppColors.primaryColor,
                                onTap: () => navigateToLogin(context, 'student'),
                              ),

                              KVerticalSpacer(height: 20),

                              buildRoleCard(
                                context: context,
                                title: "I'm a Teacher",
                                subtitle:
                                    "Create courses, manage students, and teach",
                                gifPath: 'assets/gifs/teacher.gif',
                                color: Color(0xFF26BDCF),
                                onTap: () => navigateToLogin(context, 'teacher'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 2),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}
