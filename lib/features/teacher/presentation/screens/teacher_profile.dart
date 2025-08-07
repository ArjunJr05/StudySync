// features/teacher/presentation/teacher_profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/commons/widgets/responsive.dart';
import 'package:studysync/core/constants/app_router_constants.dart';
import 'package:studysync/core/services/auth_service.dart';
import 'package:studysync/core/services/firestore_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';
import 'package:studysync/core/services/teacher_service.dart';

class TeacherProfilePage extends StatefulWidget {
  final String teacherId;
  final String institutionName;
  final String teacherName;

  const TeacherProfilePage({
    super.key,
    required this.teacherId,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSigningOut = false;

  TeacherDashboardData? _dashboardData;
  Map<String, dynamic>? _rawTeacherData;
  User? _currentUser;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfileData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        TeacherService.getDashboardData(widget.teacherId, widget.institutionName),
        FirestoreService.getTeacherDataById(widget.teacherId, widget.institutionName),
      ]);

      final currentUser = AuthService.getCurrentUser();

      if (mounted) {
        setState(() {
          _dashboardData = results[0] as TeacherDashboardData;
          _rawTeacherData = results[1] as Map<String, dynamic>?;
          _currentUser = currentUser;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading profile data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data: ${e.toString()}'),
            backgroundColor: AppColors.checkOutColor,
          ),
        );
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'T';
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);

    try {
      await AuthService.signOut();
      if (mounted) {
        context.goNamed(AppRouterConstants.findingUser);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: AppColors.checkOutColor,
          ),
        );
      }
    }
  }

  void _showFeatureNotAvailableDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(featureName),
        content: Text('$featureName will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      body: _isLoading
          ? _buildLoadingState()
          : (_dashboardData == null ? _buildErrorState() : _buildProfileContent()),
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
            text: 'Loading profile...',
            textColor: AppColors.subTitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.checkOutColor, size: 48),
            const SizedBox(height: 16),
            const KText(
              text: 'Could not load profile data.',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProfileData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final isMobile = Responsive.isMobile(context);
    final teacherName = _dashboardData?.teacherName ?? widget.teacherName;
    final teacherEmail = _currentUser?.email ?? 'Not available';
    final joinedAtTimestamp = _rawTeacherData?['joinedAt'] as Timestamp?;
    final joinedDate = joinedAtTimestamp != null
        ? joinedAtTimestamp.toDate()
        : DateTime.now();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildEnhancedAppBar(isMobile, teacherName, teacherEmail),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildStatsCard(),
                      const KVerticalSpacer(height: 16),
                      _buildAcademicInfoCard(),
                      const KVerticalSpacer(height: 16),
                      _buildRecentActivitiesCard(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedAppBar(bool isMobile, String teacherName, String teacherEmail) {
    final photoUrl = _currentUser?.photoURL;

    return SliverAppBar(
      expandedHeight: isMobile ? 240 : 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? KText(
                                text: _getInitials(teacherName),
                                fontSize: 36,
                                textColor: Colors.white,
                                fontWeight: FontWeight.bold,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      KText(
                        text: teacherName,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      KText(
                        text: teacherEmail,
                        fontSize: 14,
                        textColor: Colors.white.withOpacity(0.9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Color iconColor, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              KText(
                text: title,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAcademicInfoCard() {
    return _buildCard(
      title: 'Academic Information',
      icon: Icons.school_outlined,
      iconColor: AppColors.ThemeGreenColor,
      children: [
        _buildDetailRow('Institution', widget.institutionName, Icons.location_city_outlined),
        _buildDetailRow('Role', 'Educator', Icons.work_outline),
      ],
    );
  }

  Widget _buildStatsCard() {
    return _buildCard(
      title: 'Teaching Stats',
      icon: Icons.analytics_outlined,
      iconColor: AppColors.ThemeBlueColor,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Students',
                _dashboardData?.totalStudents.toString() ?? '0',
                AppColors.ThemeGreenColor,
                Icons.people_outline,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Active Today',
                _dashboardData?.activeToday.toString() ?? '0',
                AppColors.primaryColor,
                Icons.online_prediction,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Avg Score',
                '${_dashboardData?.averageScore.toStringAsFixed(1) ?? '0.0'}%',
                AppColors.ThemelightGreenColor,
                Icons.grade_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesCard() {
    final activities = _dashboardData?.recentActivities ?? [];
    return _buildCard(
      title: 'Recent Activities',
      icon: Icons.history_edu_outlined,
      iconColor: Colors.amber.shade700,
      children: activities.isEmpty
          ? [const Center(child: KText(text: 'No recent activities.', textColor: AppColors.subTitleColor))]
          : activities.take(3).map((activity) => _buildActivityItem(activity)).toList(),
    );
  }

  Widget _buildActivityItem(String description) {
    IconData icon;
    Color color;

    if (description.toLowerCase().contains('accept') || description.toLowerCase().contains('join')) {
      icon = Icons.person_add_outlined;
      color = AppColors.checkInColor;
    } else if (description.toLowerCase().contains('creat') || description.toLowerCase().contains('assign')) {
      icon = Icons.assignment_outlined;
      color = AppColors.ThemeBlueColor;
    } else if (description.toLowerCase().contains('grad') || description.toLowerCase().contains('achiev')) {
      icon = Icons.rate_review_outlined;
      color = AppColors.ThemelightGreenColor;
    } else {
      icon = Icons.history;
      color = AppColors.subTitleColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: KText(
              text: description,
              fontSize: 14,
              textColor: AppColors.titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showFeatureNotAvailableDialog('Settings'),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.titleColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSigningOut ? null : _handleSignOut,
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.logout),
            label: Text(_isSigningOut ? 'Signing Out...' : 'Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.checkOutColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const KVerticalSpacer(height: 80)
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          KText(
            text: value,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            textColor: color,
          ),
          const SizedBox(height: 4),
          KText(
            text: label,
            fontSize: 12,
            textColor: AppColors.subTitleColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.subTitleColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: KText(
              text: label,
              textColor: AppColors.subTitleColor,
              fontSize: 14,
            ),
          ),
          Expanded(
            flex: 3,
            child: KText(
              text: value,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
