// features/teacher/presentation/teacher_ranking.dart
import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/services/teacher_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';
import 'package:studysync/features/teacher/presentation/widgets/teacher_rank_filter.dart';
import 'package:studysync/commons/widgets/responsive.dart';

class StudentRankingsPage extends StatefulWidget {
  final String teacherId;
  final String institutionName;

  const StudentRankingsPage({
    super.key,
    required this.teacherId,
    required this.institutionName,
  });

  @override
  State<StudentRankingsPage> createState() => _StudentRankingsPageState();
}

class _StudentRankingsPageState extends State<StudentRankingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _headerController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _floatingAnimation;

  List<StudentData> students = [];
  List<StudentData> filteredStudents = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter = 'all';
  String selectedSortBy = 'rank';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadStudentData();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.elasticOut));

    _floatingAnimation = Tween<double>(begin: -0.015, end: 0.015)
        .animate(CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _headerController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final studentData = await TeacherService.getStudentRankings(
        widget.teacherId,
        widget.institutionName,
      );

      if (mounted) {
        setState(() {
          students = studentData;
          _applyFilters();
          isLoading = false;
        });

        _fadeController.forward();
        _slideController.forward();
        _headerController.forward();
        _floatingController.repeat(reverse: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
        _headerController.forward();
      }
    }
  }

  void _applyFilters() {
    List<StudentData> tempStudents;

    tempStudents = students.where((student) {
      switch (selectedFilter) {
        case 'active':
          return student.isActiveToday;
        case 'inactive':
          return !student.isActiveToday;
        case 'high_performers':
          return student.overallScore >= 80;
        case 'needs_attention':
          return student.overallScore < 60;
        default:
          return true;
      }
    }).toList();

    switch (selectedSortBy) {
      case 'rank':
        tempStudents.sort((a, b) => a.rank.compareTo(b.rank));
        break;
      case 'score':
        tempStudents.sort((a, b) => b.overallScore.compareTo(a.overallScore));
        break;
      case 'activity':
        tempStudents.sort((a, b) => b.totalActivity.compareTo(a.totalActivity));
        break;
      case 'name':
        tempStudents.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    setState(() {
      filteredStudents = tempStudents;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      body: RefreshIndicator(
        onRefresh: _loadStudentData,
        color: AppColors.primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        child: CustomScrollView(
          slivers: [
            _buildEnhancedAppBar(),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    final isMobile = Responsive.isMobile(context);
    return SliverAppBar(
      expandedHeight: isMobile ? 220 : 250,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: Listenable.merge([_headerController, _floatingController]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _headerFadeAnimation,
              child: SlideTransition(
                position: _headerSlideAnimation,
                child: Transform.rotate(
                  angle: _floatingAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.9),
                          AppColors.scaffoldBgLightColor,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -40,
                          right: -40,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Student Rankings',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: isMobile ? 28 : 32,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (!isLoading)
                                  Text(
                                    '${filteredStudents.length} students found',
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: isMobile ? 8 : 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          ),
          child: IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white, size: isMobile ? 20 : 22),
            onPressed: _loadStudentData,
            tooltip: 'Refresh Rankings',
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: isMobile ? 16 : 20, top: 8, bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          ),
          child: IconButton(
            icon: Icon(Icons.analytics_outlined, color: Colors.white, size: isMobile ? 20 : 22),
            onPressed: () => _showAnalyticsSheet(),
            tooltip: 'View Analytics',
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return SliverFillRemaining(child: _buildEnhancedLoadingWidget());
    }
    if (errorMessage != null) {
      return SliverFillRemaining(child: _buildEnhancedErrorWidget());
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                const SizedBox(height: 16),
                RankingFilter(
                  selectedFilter: selectedFilter,
                  selectedSortBy: selectedSortBy,
                  onFilterChanged: (filter) {
                    setState(() => selectedFilter = filter);
                    _applyFilters();
                  },
                  onSortChanged: (sortBy) {
                    setState(() => selectedSortBy = sortBy);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 20),
                RankingStatsSummary(students: students),
                const SizedBox(height: 20),
                if (filteredStudents.isEmpty)
                  _buildEnhancedEmptyState()
                else
                  _buildStudentsList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildEnhancedLoadingWidget() {
    final isMobile = Responsive.isMobile(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 24 : 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.15),
                  AppColors.primaryColor.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              strokeWidth: isMobile ? 4 : 5,
            ),
          ),
          KVerticalSpacer(height: isMobile ? 24 : 28),
          Text(
            'Loading Student Rankings',
            style: TextStyle(
              fontSize: isMobile ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: AppColors.titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching performance data...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: AppColors.subTitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedErrorWidget() {
    final isMobile = Responsive.isMobile(context);
    return Center(
      child: Container(
        margin: EdgeInsets.all(isMobile ? 24 : 32),
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.95),
              AppColors.primaryColor.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 15),
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.15),
                    AppColors.primaryColor.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: isMobile ? 48 : 56,
                color: AppColors.primaryColor,
              ),
            ),
            KVerticalSpacer(height: isMobile ? 24 : 28),
            Text(
              'Failed to Load Rankings',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppColors.titleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const KVerticalSpacer(height: 16),
            Text(
              errorMessage ?? 'An unknown error occurred. Please check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: AppColors.subTitleColor,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            KVerticalSpacer(height: isMobile ? 24 : 28),
            ElevatedButton.icon(
              onPressed: _loadStudentData,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: isMobile ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    final isMobile = Responsive.isMobile(context);
    String title;
    String subtitle;
    IconData icon;
    Color color;

    switch (selectedFilter) {
      case 'active':
        title = 'No Active Students';
        subtitle = 'No students are currently active today';
        icon = Icons.online_prediction;
        color = AppColors.primaryColor;
        break;
      case 'inactive':
        title = 'No Inactive Students';
        subtitle = 'All students have been active today';
        icon = Icons.offline_bolt_outlined;
        color = Colors.grey;
        break;
      case 'high_performers':
        title = 'No High Performers';
        subtitle = 'No students have scored above 80%';
        icon = Icons.star_outline;
        color = AppColors.tipsPrimaryColor;
        break;
      case 'needs_attention':
        title = 'No Students Need Attention';
        subtitle = 'All students are performing well';
        icon = Icons.warning_amber_outlined;
        color = AppColors.primaryColor;
        break;
      default:
        title = 'No Students Found';
        subtitle = 'Try adjusting the filters to find students';
        icon = Icons.search_off;
        color = AppColors.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.subTitleColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                selectedFilter = 'all';
                selectedSortBy = 'rank';
              });
              _applyFilters();
            },
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return Column(
      children: List.generate(filteredStudents.length, (index) {
        final student = filteredStudents[index];
        return Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: StudentCard(
            student: student,
            onTap: () => _showStudentDetails(student),
          ),
        );
      }),
    );
  }

  void _showStudentDetails(StudentData student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StudentDetailsSheet(student: student),
    );
  }

  void _showAnalyticsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAnalyticsSheet(),
    );
  }

  Widget _buildAnalyticsSheet() {
    final totalStudents = students.length;
    final activeToday = students.where((s) => s.isActiveToday).length;
    final highPerformers = students.where((s) => s.overallScore >= 80).length;
    final needsAttention = students.where((s) => s.overallScore < 60).length;
    final averageScore = totalStudents > 0
        ? students.map((s) => s.overallScore).reduce((a, b) => a + b) / totalStudents
        : 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Performance Analytics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.titleColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildAnalyticsCard(
                      'Overall Performance',
                      [
                        _buildAnalyticsItem(
                          'Average Score',
                          '${averageScore.toStringAsFixed(1)}%',
                          Icons.score_outlined,
                          AppColors.primaryColor,
                        ),
                        _buildAnalyticsItem(
                          'Total Students',
                          totalStudents.toString(),
                          Icons.people_outline,
                          AppColors.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildAnalyticsCard(
                      'Activity Status',
                      [
                        _buildAnalyticsItem(
                          'Active Today',
                          '$activeToday students',
                          Icons.online_prediction,
                          AppColors.primaryColor,
                        ),
                        _buildAnalyticsItem(
                          'Inactive Today',
                          '${totalStudents - activeToday} students',
                          Icons.offline_bolt_outlined,
                          Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildAnalyticsCard(
                      'Performance Categories',
                      [
                        _buildAnalyticsItem(
                          'High Performers (≥80%)',
                          '$highPerformers students',
                          Icons.star_outline,
                          AppColors.tipsPrimaryColor,
                        ),
                        _buildAnalyticsItem(
                          'Needs Attention (<60%)',
                          '$needsAttention students',
                          Icons.warning_amber_outlined,
                          AppColors.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBgLightColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.titleColor,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
