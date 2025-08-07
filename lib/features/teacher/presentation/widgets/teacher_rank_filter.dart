// features/teacher/presentation/widgets/teacher_rank_filter.dart
import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/commons/widgets/responsive.dart'; 
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';

// Enhanced widget for filtering and sorting options
class RankingFilter extends StatefulWidget {
  final String selectedFilter;
  final String selectedSortBy;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;

  const RankingFilter({
    super.key,
    required this.selectedFilter,
    required this.selectedSortBy,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  State<RankingFilter> createState() => _RankingFilterState();
}

class _RankingFilterState extends State<RankingFilter>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _chipAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    const totalChips = 9;
    _chipAnimations = List.generate(totalChips, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            0.6 + (index * 0.05),
            curve: Curves.elasticOut,
          ),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Filter Students',
            Icons.filter_list_outlined,
            isMobile,
          ),
          const KVerticalSpacer(height: 16),
          _buildFilterChips(isMobile),
          const KVerticalSpacer(height: 24),
          _buildSectionHeader('Sort By', Icons.sort_outlined, isMobile),
          const KVerticalSpacer(height: 16),
          _buildSortChips(isMobile),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: isMobile ? 16 : 18,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 15 : 16,
            fontWeight: FontWeight.bold,
            color: AppColors.titleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(bool isMobile) {
    final filters = [
      {'value': 'all', 'label': 'All Students', 'icon': Icons.group_outlined},
      {
        'value': 'active',
        'label': 'Active Today',
        'icon': Icons.online_prediction,
      },
      {
        'value': 'inactive',
        'label': 'Inactive',
        'icon': Icons.offline_bolt_outlined,
      },
      {
        'value': 'high_performers',
        'label': 'High Performers',
        'icon': Icons.star_outline,
      },
      {
        'value': 'needs_attention',
        'label': 'Needs Attention',
        'icon': Icons.warning_amber_outlined,
      },
    ];

    return Wrap(
      spacing: isMobile ? 6 : 8,
      runSpacing: isMobile ? 6 : 8,
      children: List.generate(filters.length, (index) {
        return AnimatedBuilder(
          animation: _chipAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _chipAnimations[index].value,
              child: _buildEnhancedChip(
                isMobile: isMobile,
                value: filters[index]['value'] as String,
                label: filters[index]['label'] as String,
                icon: filters[index]['icon'] as IconData,
                groupValue: widget.selectedFilter,
                onChanged: widget.onFilterChanged,
                chipType: ChipType.filter,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildSortChips(bool isMobile) {
    final sorts = [
      {'value': 'rank', 'label': 'Rank', 'icon': Icons.emoji_events_outlined},
      {'value': 'score', 'label': 'Score', 'icon': Icons.score_outlined},
      {
        'value': 'activity',
        'label': 'Activity',
        'icon': Icons.trending_up_outlined,
      },
      {'value': 'name', 'label': 'Name', 'icon': Icons.sort_by_alpha_outlined},
    ];

    return Wrap(
      spacing: isMobile ? 6 : 8,
      runSpacing: isMobile ? 6 : 8,
      children: List.generate(sorts.length, (index) {
        final animationIndex = index + 5;
        return AnimatedBuilder(
          animation: _chipAnimations[animationIndex],
          builder: (context, child) {
            return Transform.scale(
              scale: _chipAnimations[animationIndex].value,
              child: _buildEnhancedChip(
                isMobile: isMobile,
                value: sorts[index]['value'] as String,
                label: sorts[index]['label'] as String,
                icon: sorts[index]['icon'] as IconData,
                groupValue: widget.selectedSortBy,
                onChanged: widget.onSortChanged,
                chipType: ChipType.sort,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildEnhancedChip({
    required bool isMobile,
    required String value,
    required String label,
    required IconData icon,
    required String groupValue,
    required ValueChanged<String> onChanged,
    required ChipType chipType,
  }) {
    final isSelected = value == groupValue;
    final color = chipType == ChipType.filter
        ? AppColors.primaryColor
        : AppColors.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 10,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isMobile ? 14 : 16,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ChipType { filter, sort }

// Enhanced widget to show summary statistics
class RankingStatsSummary extends StatefulWidget {
  final List<StudentData> students;

  const RankingStatsSummary({super.key, required this.students});

  @override
  State<RankingStatsSummary> createState() => _RankingStatsSummaryState();
}

class _RankingStatsSummaryState extends State<RankingStatsSummary>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 600 + (index * 200)),
        vsync: this,
      );
    });

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final activeCount = widget.students.where((s) => s.isActiveToday).length;
    final highPerformers = widget.students
        .where((s) => s.overallScore >= 80)
        .length;

    final stats = [
      {
        'label': 'Total Students',
        'value': widget.students.length.toString(),
        'color': AppColors.primaryColor,
        'icon': Icons.people_outline,
      },
      {
        'label': 'Active Today',
        'value': activeCount.toString(),
        'color': AppColors.primaryColor,
        'icon': Icons.online_prediction,
      },
      {
        'label': 'Top Performers',
        'value': highPerformers.toString(),
        'color': AppColors.tipsPrimaryColor,
        'icon': Icons.star_outline,
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.primaryColor.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: isMobile ? 12 : 16,
        runSpacing: isMobile ? 12 : 16,
        children: List.generate(stats.length, (index) {
          return AnimatedBuilder(
            animation: _scaleAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimations[index].value,
                child: _buildEnhancedStatItem(
                  isMobile: isMobile,
                  label: stats[index]['label'] as String,
                  value: stats[index]['value'] as String,
                  color: stats[index]['color'] as Color,
                  icon: stats[index]['icon'] as IconData,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildEnhancedStatItem({
    required bool isMobile,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: isMobile ? 20 : 24, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 22 : 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            color: AppColors.subTitleColor,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Enhanced card representing a single student in the ranking list
class StudentCard extends StatefulWidget {
  final StudentData student;
  final VoidCallback onTap;

  const StudentCard({super.key, required this.student, required this.onTap});

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              boxShadow: [
                BoxShadow(
                  color: _getRankColor(widget.student.rank).withOpacity(0.15),
                  blurRadius: _isPressed ? 8 : 12,
                  spreadRadius: _isPressed ? 1 : 2,
                  offset: Offset(0, _isPressed ? 2 : 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                    border: Border.all(
                      color: _getRankColor(
                        widget.student.rank,
                      ).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildEnhancedRankIndicator(
                        widget.student.rank,
                        isMobile,
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.student.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14 : 16,
                                color: AppColors.titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.student.email,
                              style: TextStyle(
                                color: AppColors.subTitleColor,
                                fontSize: isMobile ? 11 : 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildInfoChip(
                                  '${widget.student.totalActivity}',
                                  Icons.trending_up,
                                  AppColors.primaryColor,
                                  isMobile,
                                ),
                                const SizedBox(width: 8),
                                _buildStatusChip(
                                  widget.student.isActiveToday,
                                  isMobile,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 12,
                              vertical: isMobile ? 5 : 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryColor,
                                  AppColors.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 12,
                              ),
                            ),
                            child: Text(
                              '${widget.student.overallScore.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.student.completionRate.toStringAsFixed(0)}% complete',
                            style: TextStyle(
                              color: AppColors.subTitleColor,
                              fontSize: isMobile ? 10 : 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _buildEnhancedRankIndicator(int rank, bool isMobile) {
    final color = _getRankColor(rank);
    final size = isMobile ? 45.0 : 50.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (rank <= 3)
              Icon(
                rank == 1 ? Icons.emoji_events : Icons.military_tech,
                color: Colors.white,
                size: isMobile ? 14 : 16,
              )
            else
              Text(
                '#',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              rank.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 10 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, bool isMobile) {
    final color = isActive ? AppColors.primaryColor : Colors.grey;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Offline',
            style: TextStyle(
              fontSize: isMobile ? 9 : 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) {
      return AppColors.primaryColor;
    } else if (rank <= 10) {
      return AppColors.tipsPrimaryColor;
    } else {
      return AppColors.primaryColor;
    }
  }
}

// Enhanced modal bottom sheet for displaying detailed student info
class StudentDetailsSheet extends StatefulWidget {
  final StudentData student;

  const StudentDetailsSheet({super.key, required this.student});

  @override
  State<StudentDetailsSheet> createState() => _StudentDetailsSheetState();
}

class _StudentDetailsSheetState extends State<StudentDetailsSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return DraggableScrollableSheet(
          initialChildSize: isMobile ? 0.75 : 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSheetHeader(isMobile),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView(
                        controller: controller,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                        ),
                        children: [
                          _buildStudentHeader(isMobile),
                          const SizedBox(height: 24),
                          _buildPerformanceSection(isMobile),
                          const SizedBox(height: 24),
                          _buildActivitySection(isMobile),
                          if (widget.student.subjectScores.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSubjectScoresSection(isMobile),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Student Details',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader(bool isMobile) {
    final rankColor = _getRankColor(widget.student.rank);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [rankColor.withOpacity(0.1), rankColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(color: rankColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 60 : 70,
            height: isMobile ? 60 : 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [rankColor, rankColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.student.name.isNotEmpty
                    ? widget.student.name.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.student.email,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: AppColors.subTitleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rank #${widget.student.rank}',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(bool isMobile) {
    return _buildDetailSection(
      isMobile,
      'Performance Overview',
      Icons.analytics_outlined,
      [
        _buildDetailItem(
          isMobile,
          'Overall Score',
          '${widget.student.overallScore.toStringAsFixed(1)}%',
          Icons.score_outlined,
        ),
        _buildDetailItem(
          isMobile,
          'Completion Rate',
          '${widget.student.completionRate.toStringAsFixed(1)}%',
          Icons.check_circle_outline,
        ),
        _buildDetailItem(
          isMobile,
          'Total Activities',
          '${widget.student.totalActivity} completed',
          Icons.trending_up_outlined,
        ),
      ],
    );
  }

  Widget _buildActivitySection(bool isMobile) {
    return _buildDetailSection(
      isMobile,
      'Activity Information',
      Icons.history_outlined,
      [
        _buildDetailItem(
          isMobile,
          'Last Active',
          widget.student.lastActiveTime,
          Icons.access_time_outlined,
        ),
        _buildDetailItem(
          isMobile,
          'Status Today',
          widget.student.isActiveToday ? 'Active' : 'Inactive',
          widget.student.isActiveToday
              ? Icons.online_prediction
              : Icons.offline_bolt_outlined,
        ),
      ],
    );
  }

  Widget _buildSubjectScoresSection(bool isMobile) {
    return _buildDetailSection(
      isMobile,
      'Subject Performance',
      Icons.subject_outlined,
      widget.student.subjectScores.entries
          .map(
            (entry) => _buildDetailItem(
              isMobile,
              entry.key,
              '${entry.value.toStringAsFixed(1)}%',
              Icons.book_outlined,
            ),
          )
          .toList(),
    );
  }

  Widget _buildDetailSection(
    bool isMobile,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBgLightColor,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: isMobile ? 16 : 18,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    bool isMobile,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: isMobile ? 14 : 16, color: AppColors.subTitleColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) {
      return AppColors.primaryColor;
    } else if (rank <= 10) {
      return AppColors.tipsPrimaryColor;
    } else {
      return AppColors.primaryColor;
    }
  }
}
