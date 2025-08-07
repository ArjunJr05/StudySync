import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/core/services/firestore_service.dart';
import 'package:studysync/core/services/auth_service.dart'; // Add this import
import 'package:studysync/commons/widgets/responsive.dart';
import 'package:studysync/features/Student/presentation/widgets/python_test_page.dart';
import 'package:studysync/features/Student/presentation/widgets/student_header.dart';

class StudentHomePage extends StatefulWidget {
  final String studentId;
  final String institutionName;
  final String teacherName;

  const StudentHomePage({
    super.key,
    required this.studentId,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _performanceData;
  List<dynamic> _recentActivities = [];
  List<Map<String, dynamic>> _classmates = [];
  int _currentRank = 0;
  String _studentName = '';
  String? _photoUrl; // Updated to fetch from both sources
  int _testsCompleted = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadStudentData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );
  }

  Future<void> _loadStudentData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final studentData = await FirestoreService.getStudentDataById(
        widget.studentId,
        widget.teacherName,
        widget.institutionName,
      );

      final classmates = await FirestoreService.getStudentsByTeacherName(
        widget.institutionName,
        widget.teacherName,
      );

      if (mounted) {
        setState(() {
          _studentData = studentData;
          _performanceData = studentData?['performance'];
          _recentActivities = studentData?['recentActivities'] ?? [];
          _classmates = classmates;
          _studentName = studentData?['name'] ?? 'Student';
          // Updated photo fetching logic - try Firestore first, then Auth
          _photoUrl = studentData?['photoURL'] ?? 
                     AuthService.getCurrentUser()?.photoURL;
          _currentRank = _calculateRank(studentData);
          _testsCompleted = _performanceData?['testsCompleted'] ?? 0;
          _isLoading = false;
        });

        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateRank(Map<String, dynamic>? studentData) {
    if (studentData == null || _classmates.isEmpty) return 1;

    _classmates.sort((a, b) {
      final scoreA = (a['performance']?['averageScore'] ?? 0.0) as double;
      final scoreB = (b['performance']?['averageScore'] ?? 0.0) as double;
      return scoreB.compareTo(scoreA);
    });

    final rank = _classmates
            .indexWhere((s) => s['studentId'] == studentData['studentId']) +
        1;
    return rank > 0 ? rank : _classmates.length + 1;
  }

  double _getOverallProgress() {
    final totalTests = 65;
    if (_testsCompleted > totalTests) return 1.0;
    return _testsCompleted / totalTests;
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 60) return "${totalSeconds}s";
    if (totalSeconds < 3600) return "${(totalSeconds / 60).floor()}m";
    final hours = totalSeconds / 3600;
    return "${hours.toStringAsFixed(1)}h";
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'a moment ago';
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours == 1) {
      return '1 hour ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} mins ago';
    } else {
      return 'just now';
    }
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      case 'join':
        return Icons.person_add_alt_1;
      case 'approval':
        return Icons.how_to_reg;
      default:
        return Icons.history;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          SizedBox(height: 16),
          KText(
            text: 'Loading your dashboard...',
            textColor: AppColors.subTitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final isMobile = Responsive.isMobile(context);
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      color: AppColors.primaryColor,
      child: CustomScrollView(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          StudentHeaderSliverAppBar(
            studentName: _studentName,
            institutionName: widget.institutionName,
            photoUrl: _photoUrl, // Pass the properly fetched photo URL
            rank: _currentRank,
            testsCompleted: _testsCompleted,
            isMobile: isMobile,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildEnhancedProgressCard(),
                        const SizedBox(height: 24),
                        _buildQuickStatsRow(),
                        const SizedBox(height: 24),
                        _buildEnhancedQuickActionCard(context),
                        const SizedBox(height: 24),
                        _buildRecentActivityCard(),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProgressCard() {
    final overallProgress = _getOverallProgress();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KText(
                        text: 'Learning Progress',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 8),
                      KText(
                        text: 'Keep up the great work!',
                        textColor: AppColors.subTitleColor,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: overallProgress),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeInOutCubic,
                        builder: (context, value, child) =>
                            CircularProgressIndicator(
                          value: value,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            KText(
                              text: '${(overallProgress * 100).toInt()}%',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              textColor: AppColors.primaryColor,
                            ),
                            const KText(
                              text: 'Complete',
                              fontSize: 12,
                              textColor: AppColors.subTitleColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEnhancedStatColumn(
                    'Rank',
                    '#$_currentRank',
                    Icons.emoji_events,
                    AppColors.primaryColor,
                  ),
                  Container(
                      width: 1, height: 40, color: Colors.grey.shade300),
                  _buildEnhancedStatColumn(
                    'Tests Done',
                    '$_testsCompleted',
                    Icons.quiz,
                    AppColors.primaryColor,
                  ),
                  Container(
                      width: 1, height: 40, color: Colors.grey.shade300),
                  _buildEnhancedStatColumn(
                    'Classmates',
                    '${_classmates.length}',
                    Icons.people,
                    AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        KText(
          text: value,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          textColor: color,
        ),
        const SizedBox(height: 4),
        KText(text: label, fontSize: 12, textColor: AppColors.subTitleColor),
      ],
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            'Streak',
            '${_performanceData?['streaks'] ?? 0} days',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            'Average',
            '${(_performanceData?['averageScore'] ?? 0.0).toStringAsFixed(1)}%',
            Icons.bar_chart,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            'Time',
            _formatTime(_performanceData?['timeSpentSeconds'] ?? 0),
            Icons.schedule,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          KText(
            text: value,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            textColor: color,
          ),
          const SizedBox(height: 4),
          KText(text: label, fontSize: 12, textColor: AppColors.subTitleColor),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickActionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // UPDATED: This now passes the required data to PythonTestPage
            final needsRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PythonTestPage(
                  studentId: widget.studentId,
                  institutionName: widget.institutionName,
                  teacherName: widget.teacherName,
                ),
              ),
            );
            if (needsRefresh == true && mounted) {
              _loadStudentData();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.code, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KText(
                        text: 'Start a Test',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                      SizedBox(height: 8),
                      KText(
                        text: 'Python Challenges',
                        fontSize: 14,
                        textColor: Colors.white70,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    _recentActivities.sort((a, b) {
      // Ensure items are maps before trying to access keys
      if (a is! Map || b is! Map) return 0;
      final aTimestamp = a['timestamp'] as Timestamp?;
      final bTimestamp = b['timestamp'] as Timestamp?;
      if (aTimestamp == null || bTimestamp == null) return 0;
      return bTimestamp.compareTo(aTimestamp);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              KText(
                text: 'Recent Activity',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: KText(
                  text: 'No recent activity yet. Complete a test!',
                  textColor: AppColors.subTitleColor,
                ),
              ),
            )
          else
            // ✨ FIX: Filter the list to only include Map objects before mapping.
            ..._recentActivities
                .where((activity) => activity is Map<String, dynamic>)
                .map((activity) {
              final timestamp = activity['timestamp'] as Timestamp?;
              final timeAgoString = _formatTimeAgo(timestamp);
              return _buildActivityItem(
                activity['activity'] ?? 'Unknown Activity',
                timeAgoString,
                _getActivityIcon(activity['icon'] ?? 'history'),
                AppColors.primaryColor,
              );
            }).toList(),
          const KVerticalSpacer(height: 100)
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KText(text: title, fontSize: 14, fontWeight: FontWeight.w500),
                KText(
                  text: time,
                  fontSize: 12,
                  textColor: AppColors.subTitleColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}