// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_horizontal_spacer.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/commons/widgets/responsive.dart';
import 'package:studysync/core/themes/app_colors.dart';

class ModernRecentActivity extends StatefulWidget {
  final List<String> activities;
  const ModernRecentActivity({super.key, required this.activities});

  @override
  State<ModernRecentActivity> createState() => _ModernRecentActivityState();
}

class _ModernRecentActivityState extends State<ModernRecentActivity>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late List<Animation<double>> _itemAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final itemCount = widget.activities.isNotEmpty ? widget.activities.length : 1;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _itemAnimations = List.generate(
      itemCount,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.08,
            (0.5 + (index * 0.08)).clamp(0.0, 1.0),
            curve: Curves.easeOutExpo,
          ),
        ),
      ),
    );

    _slideAnimations = List.generate(
      itemCount,
      (index) => Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.08,
            (0.5 + (index * 0.08)).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.1),
                          AppColors.primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                  const KHorizontalSpacer(width: 12),
                  const KText(
                    text: 'Recent Activity',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    textColor: AppColors.titleColor,
                  ),
                ],
              ),
            ],
          ),
          if (widget.activities.isEmpty)
            _buildEmptyState(isMobile)
          else
            _buildActivityList(isMobile),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return FadeTransition(
      opacity: _itemAnimations[0],
      child: SlideTransition(
        position: _slideAnimations[0],
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF8FAFC),
                Colors.grey.shade100,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.subTitleColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.manage_history_rounded,
                        size: isMobile ? 32 : 40,
                        color: AppColors.subTitleColor.withOpacity(0.6),
                      ),
                    ),
                  );
                },
              ),
              const KVerticalSpacer(height: 20),
              const KText(
                text: 'No Recent Activity',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                textColor: AppColors.titleColor,
              ),
              const KVerticalSpacer(height: 8),
              const KText(
                text: 'New updates and activities will appear here.',
                fontSize: 14,
                textColor: AppColors.subTitleColor,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList(bool isMobile) {
    final activityData = {
      'ASSIGNMENT': {
        'icon': Icons.assignment_turned_in_rounded,
        'color': AppColors.ThemeBlueColor,
        'bgGradient': [
          AppColors.ThemeBlueColor.withOpacity(0.1),
          AppColors.ThemeBlueColor.withOpacity(0.05),
        ],
      },
      'JOINED': {
        'icon': Icons.person_add_alt_1_rounded,
        'color': AppColors.ThemeGreenColor,
        'bgGradient': [
          AppColors.ThemeGreenColor.withOpacity(0.1),
          AppColors.ThemeGreenColor.withOpacity(0.05),
        ],
      },
      'ACCEPTED': {
        'icon': Icons.check_circle_rounded,
        'color': AppColors.ThemeGreenColor,
        'bgGradient': [
          AppColors.ThemeGreenColor.withOpacity(0.1),
          AppColors.ThemeGreenColor.withOpacity(0.05),
        ],
      },
      'GRADE': {
        'icon': Icons.grade_rounded,
        'color': AppColors.primaryColor,
        'bgGradient': [
          AppColors.primaryColor.withOpacity(0.1),
          AppColors.primaryColor.withOpacity(0.05),
        ],
      },
      'ACHIEVED': {
        'icon': Icons.star_rounded,
        'color': Colors.amber.shade700,
        'bgGradient': [
          Colors.amber.shade700.withOpacity(0.1),
          Colors.amber.shade700.withOpacity(0.05),
        ],
      },
      'DEFAULT': {
        'icon': Icons.history_rounded,
        'color': AppColors.subTitleColor,
        'bgGradient': [
          AppColors.subTitleColor.withOpacity(0.1),
          AppColors.subTitleColor.withOpacity(0.05),
        ],
      },
    };

    return ListView.separated(
      itemCount: widget.activities.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const KVerticalSpacer(height: 12),
      itemBuilder: (context, index) {
        final activityText = widget.activities[index];
        final key = activityData.keys.firstWhere(
          (k) => activityText.toUpperCase().contains(k),
          orElse: () => 'DEFAULT',
        );
        final data = activityData[key]!;
        final color = data['color'] as Color;
        final icon = data['icon'] as IconData;
        final bgGradient = data['bgGradient'] as List<Color>;

        return FadeTransition(
          opacity: _itemAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Handle activity item tap
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: bgGradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.15), color.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, size: 22, color: color),
                      ),
                      const KHorizontalSpacer(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KText(
                              text: activityText,
                              fontSize: 15,
                              textColor: AppColors.titleColor,
                              fontWeight: FontWeight.w600,
                            ),
                            const KVerticalSpacer(height: 4),
                            KText(
                              text: 'Just now',
                              fontSize: 12,
                              textColor: AppColors.subTitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: color.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}