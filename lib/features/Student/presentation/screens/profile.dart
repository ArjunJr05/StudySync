// Enhanced Student Profile Page with Live Data and Photo Support
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/constants/app_router_constants.dart';
import 'package:studysync/core/services/auth_service.dart';
import 'package:studysync/core/services/firestore_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/commons/widgets/responsive.dart';
// Add this import to use the extension method
import 'package:studysync/core/services/test_service.dart';


class StudentProfilePage extends StatefulWidget {
  final String studentId;
  final String institutionName;
  final String teacherName;

  const StudentProfilePage({
    super.key,
    required this.studentId,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _teacherData;
  // ✨ ADDED: State variable to hold data from the student_progress collection
  Map<String, dynamic>? _progressData;
  bool _isSigningOut = false;
  String? _photoUrl;
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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  /// ✅ FIXED: This function now fetches both main profile and progress data.
  Future<void> _loadProfileData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Fetch main student document
      final studentData = await FirestoreService.getStudentDataById(
        widget.studentId,
        widget.teacherName,
        widget.institutionName,
      );

      // Fetch teacher data
      final teacherData = await FirestoreService.findTeacherByName(
        widget.institutionName,
        widget.teacherName,
      );

      // ✨ ADDED: Fetch progress data from the student_progress collection
      final progressData =
          await TestProgressExtension.getStudentTestProgress(widget.studentId);

      if (mounted) {
        setState(() {
          _studentData = studentData;
          _teacherData = teacherData;
          _progressData = progressData; // Store the fetched progress data
          _photoUrl = studentData?['photoURL'] ??
              AuthService.getCurrentUser()?.photoURL;
          _isLoading = false;
        });

        _animationController.forward();
      }
    } catch (e) {
      print('Error loading profile data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCurrentUserEmail() {
    return AuthService.getCurrentUser()?.email ?? 'student@example.com';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
  
  // No changes needed for the methods below until _buildStatsCard
  // ...
  
  /// ✅ FIXED: This card now displays live data from Firestore.
  Widget _buildStatsCard() {
    // Extract performance data from the main student document
    final performance = _studentData?['performance'] as Map<String, dynamic>? ?? {};
    final double overallScore = (performance['averageScore'] as double? ?? 0.0);
    final int streak = (performance['streaks'] as int? ?? 0);

    // Calculate completion rate from the progress document
    final int easyCompleted = _progressData?['python_easy_completed'] ?? 0;
    final int mediumCompleted = _progressData?['python_medium_completed'] ?? 0;
    final int hardCompleted = _progressData?['python_hard_completed'] ?? 0;
    final int totalCompleted = easyCompleted + mediumCompleted + hardCompleted;
    const int totalLevels = 65; // 25 Easy + 25 Medium + 15 Hard
    final double completionRate =
        totalLevels > 0 ? (totalCompleted / totalLevels) * 100 : 0.0;

    return _buildCard(
      title: 'Performance Stats',
      icon: Icons.analytics_outlined,
      iconColor: AppColors.ThemeBlueColor,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Overall Score',
                '${overallScore.toStringAsFixed(1)}%', // Use real data
                AppColors.ThemeRedColor,
                Icons.grade,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Completion',
                '${completionRate.toStringAsFixed(1)}%', // Use real data
                AppColors.primaryColor,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Streak',
                '$streak days', // Use real data
                AppColors.ThemeRedColor,
                Icons.local_fire_department,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // The rest of the file remains the same.
  // ...
  Widget _buildProfileAvatar(String studentName, {double size = 100}) {
   if (_photoUrl != null && _photoUrl!.isNotEmpty) {
     return Container(
       width: size,
       height: size,
       decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(size / 2),
         border: Border.all(
           color: Colors.white.withOpacity(0.3),
           width: 3,
         ),
       ),
       child: ClipRRect(
         borderRadius: BorderRadius.circular(size / 2),
         child: Image.network(
           _photoUrl!,
           width: size,
           height: size,
           fit: BoxFit.cover,
           errorBuilder: (context, error, stackTrace) {
             return _buildInitialsAvatar(studentName, size);
           },
           loadingBuilder: (context, child, loadingProgress) {
             if (loadingProgress == null) return child;
             return Container(
               width: size,
               height: size,
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.2),
                 borderRadius: BorderRadius.circular(size / 2),
               ),
               child: Center(
                 child: CircularProgressIndicator(
                   valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                   strokeWidth: 2,
                 ),
               ),
             );
           },
         ),
       ),
     );
   } else {
     return _buildInitialsAvatar(studentName, size);
   }
  }

  Widget _buildInitialsAvatar(String studentName, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 3,
        ),
      ),
      child: Center(
        child: KText(
          text: _getInitials(studentName),
          fontSize: size * 0.36, // Responsive font size
          textColor: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);
    
    try {
      await AuthService.signOut();
      if (mounted) {
        context.goNamed(AppRouterConstants.findingUser);
      }
    } catch (e) {
      if(mounted){
        setState(() => _isSigningOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: AppColors.ThemeRedColor,
          ),
        );
      }
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing will be available in a future update.'),
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
      body: _isLoading ? _buildLoadingState() : _buildProfileContent(),
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

  Widget _buildProfileContent() {
    final studentName = _studentData?['name'] ?? 'Student Name';
    final studentEmail = _studentData?['email'] ?? 'student@example.com';
    final joinedDate = _studentData?['joinedAt'] != null
        ? (_studentData!['joinedAt'] as Timestamp).toDate()
        : DateTime.now();

    // ✨ WHERE TO ADD: Wrap your main scrollable view with RefreshIndicator.
    return RefreshIndicator(
      onRefresh: _loadProfileData, // Call your data loading method here.
      color: AppColors.primaryColor, // Custom color for the loading spinner.
      backgroundColor: Colors.white,
      child: CustomScrollView(
        // Ensure the view is always scrollable to allow the refresh gesture.
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildEnhancedAppBar(studentName, studentEmail),
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
                        const SizedBox(height: 24),
                        _buildPersonalInfoCard(
                            studentName, studentEmail, joinedDate),
                        const SizedBox(height: 16),
                        _buildAcademicInfoCard(),
                        const SizedBox(height: 16),
                        _buildStatsCard(),
                        const SizedBox(height: 16),
                        _buildAchievementsCard(),
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
      ),
    );
  }

  Widget _buildEnhancedAppBar(String studentName, String studentEmail) {
    final isMobile = Responsive.isMobile(context);
    return SliverAppBar(
      expandedHeight: isMobile ? 240 : 280,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
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
                      _buildProfileAvatar(studentName, size: 100),
                      const SizedBox(height: 16),
                      KText(
                        text: studentName,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      KText(
                        text: studentEmail,
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
      actions: [
        IconButton(
          onPressed: _showEditDialog,
          icon: const Icon(
            Icons.edit,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(String studentName, String studentEmail, DateTime joinedDate) {
    return _buildCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      iconColor: AppColors.primaryColor,
      children: [
        _buildDetailRow('Email', studentEmail, Icons.email),
        _buildDetailRow(
          'Member Since', 
          '${joinedDate.day}/${joinedDate.month}/${joinedDate.year}',
          Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildAcademicInfoCard() {
    return _buildCard(
      title: 'Academic Information',
      icon: Icons.school_outlined,
      iconColor: AppColors.ThemeRedColor,
      children: [
        _buildDetailRow('Institution', widget.institutionName, Icons.location_city),
        _buildDetailRow('Teacher', widget.teacherName, Icons.person_outline),
      ],
    );
  }

  Widget _buildAchievementsCard() {
    return _buildCard(
      title: 'Recent Achievements',
      icon: Icons.emoji_events_outlined,
      iconColor: Colors.amber,
      children: [
        _buildAchievementItem(
          'Python Basics Master',
          'Completed all basic Python tests',
          Icons.code,
          AppColors.ThemeRedColor,
        ),
        _buildAchievementItem(
          'Quick Learner',
          'Finished 3 tests in one day',
          Icons.flash_on,
          AppColors.ThemeRedColor,
        ),
        _buildAchievementItem(
          'Consistent Student',
          '7-day learning streak',
          Icons.local_fire_department,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showEditDialog,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              backgroundColor: AppColors.ThemeRedColor,
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
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
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

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        KText(
          text: value,
          fontSize: 16,
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
    );
  }

  Widget _buildAchievementItem(String title, String description, IconData icon, Color color) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KText(
                  text: title,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 2),
                KText(
                  text: description,
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.subTitleColor,
          ),
          const SizedBox(width: 12),
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