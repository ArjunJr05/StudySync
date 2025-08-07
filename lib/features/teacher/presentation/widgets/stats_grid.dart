// lib/features/teacher/presentation/widgets/stats_grid.dart

import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_horizontal_spacer.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';

class StatsGrid extends StatefulWidget {
  final TeacherDashboardData data;
  final int? crossAxisCount;

  const StatsGrid({super.key, required this.data, this.crossAxisCount});

  @override
  State<StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<StatsGrid> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<AnimationController> _hoverControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _hoverAnimations;
  late List<Animation<double>> _rotationAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        duration: Duration(milliseconds: 500 + (index * 100)),
        vsync: this,
      ),
    );

    _hoverControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0)
          .animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutExpo));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
    }).toList();

    _hoverAnimations = _hoverControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.05)
          .animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _rotationAnimations = _controllers.map((controller) {
      return Tween<double>(begin: -0.1, end: 0.0)
          .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var controller in _hoverControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final int crossAxisCount = widget.crossAxisCount ?? (isMobile ? 2 : 4);
    final double childAspectRatio = isMobile ? 0.8 : 1.2;
    final double spacing = isMobile ? 16.0 : 20.0;

    final stats = [
      {
        'title': 'Total Students',
        'value': widget.data.totalStudents.toString(),
        'icon': Icons.groups_rounded,
        'color': AppColors.ThemeGreenColor,
        'gradient': [
          AppColors.ThemeGreenColor,
          AppColors.ThemeGreenColor.withOpacity(0.8),
        ],
        'bgGradient': [
          AppColors.ThemeGreenColor.withOpacity(0.1),
          AppColors.ThemeGreenColor.withOpacity(0.05),
        ],
        'subtitle': 'Active learners',
      },
      {
        'title': 'Active Today',
        'value': widget.data.activeToday.toString(),
        'icon': Icons.trending_up_rounded,
        'color': AppColors.primaryColor,
        'gradient': [
          AppColors.primaryColor,
          AppColors.primaryColor.withOpacity(0.8),
        ],
        'bgGradient': [
          AppColors.primaryColor.withOpacity(0.1),
          AppColors.primaryColor.withOpacity(0.05),
        ],
        'subtitle': 'Currently online',
      },
      {
        'title': 'Average Score',
        'value': '${widget.data.averageScore.toStringAsFixed(1)}%',
        'icon': Icons.star_rounded,
        'color': Colors.amber.shade700,
        'gradient': [
          Colors.amber.shade700,
          Colors.amber.shade600,
        ],
        'bgGradient': [
          Colors.amber.shade700.withOpacity(0.1),
          Colors.amber.shade700.withOpacity(0.05),
        ],
        'subtitle': 'Class performance',
      },
      {
        'title': 'New Requests',
        'value': widget.data.pendingRequests.toString(),
        'icon': Icons.person_add_alt_1_rounded,
        'color': AppColors.ThemeBlueColor,
        'gradient': [
          AppColors.ThemeBlueColor,
          AppColors.ThemeBlueColor.withOpacity(0.8),
        ],
        'bgGradient': [
          AppColors.ThemeBlueColor.withOpacity(0.1),
          AppColors.ThemeBlueColor.withOpacity(0.05),
        ],
        'subtitle': 'Pending approval',
      },
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: Listenable.merge([_controllers[index], _hoverControllers[index]]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: Transform.rotate(
                  angle: _rotationAnimations[index].value,
                  child: Transform.scale(
                    scale: _scaleAnimations[index].value * _hoverAnimations[index].value,
                    child: MouseRegion(
                      onEnter: (_) => _hoverControllers[index].forward(),
                      onExit: (_) => _hoverControllers[index].reverse(),
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Handle stat card tap
                        },
                        child: _buildEnhancedStatsCard(
                          title: stats[index]['title'] as String,
                          value: stats[index]['value'] as String,
                          subtitle: stats[index]['subtitle'] as String,
                          icon: stats[index]['icon'] as IconData,
                          color: stats[index]['color'] as Color,
                          gradient: stats[index]['gradient'] as List<Color>,
                          bgGradient: stats[index]['bgGradient'] as List<Color>,
                          index: index,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedStatsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required List<Color> bgGradient,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 24, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const KVerticalSpacer(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: gradient,
                      ).createShader(bounds),
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const KVerticalSpacer(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const KVerticalSpacer(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subTitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}