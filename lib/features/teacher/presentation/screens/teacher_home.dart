import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:studysync/commons/widgets/k_horizontal_spacer.dart';
import 'package:studysync/commons/widgets/k_snack_bar.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/commons/widgets/responsive.dart';
import 'package:studysync/core/services/auth_service.dart';
import 'package:studysync/core/services/teacher_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';
import 'package:studysync/features/teacher/presentation/widgets/modernrecent.dart';
import 'package:studysync/features/teacher/presentation/widgets/quick_action.dart';
import 'package:studysync/features/teacher/presentation/widgets/stats_grid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studysync/features/teacher/presentation/widgets/teacher_header.dart';

class TeacherHomePage extends StatefulWidget {
  final String teacherId;
  final String institutionName;
  final String teacherName;

  const TeacherHomePage({
    super.key,
    required this.teacherId,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  TeacherDashboardData? dashboardData;
  User? _currentUser;
  String? _teacherDisplayName;
  String? _teacherPhotoUrl;
  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;

  late double screenWidth;
  late bool isMobileScreen;
  late bool isTabletScreen;
  late bool isDesktopScreen;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardData();
  }

  void _updateScreenDimensions() {
    if (!mounted) return;
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    isMobileScreen = Responsive.isMobile(context);
    isTabletScreen = Responsive.isTablet(context);
    isDesktopScreen = Responsive.isDesktop(context);
  }

  // Load current user data from Firebase Auth for photo and initial name
  void _loadUserData() {
    try {
      _currentUser = AuthService.getCurrentUser();
      if (_currentUser != null) {
        _teacherDisplayName = _currentUser!.displayName ?? widget.teacherName;
        _teacherPhotoUrl = _currentUser!.photoURL;
        print('✅ User data loaded - Name: $_teacherDisplayName, Photo: ${_teacherPhotoUrl != null ? 'Available' : 'Not available'}');
      } else {
        _teacherDisplayName = widget.teacherName;
        _teacherPhotoUrl = null;
        print('⚠️ No current user found, using fallback name');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      _teacherDisplayName = widget.teacherName;
      _teacherPhotoUrl = null;
    }
  }

  Future<void> _loadDashboardData({bool isRefresh = false}) async {
    if (!mounted) return;
    try {
      setState(() {
        if (isRefresh) isRefreshing = true;
        errorMessage = null;
      });

      final dataFuture = TeacherService.getDashboardData(
        widget.teacherId,
        widget.institutionName,
      );
      
      final delayFuture = Future.delayed(
        Duration(milliseconds: isLoading ? 1200 : 600)
      );

      final results = await Future.wait([dataFuture, delayFuture]);
      final data = results[0] as TeacherDashboardData;

      // Reload user data in case it changed (e.g., profile photo)
      if (isRefresh) {
        _loadUserData();
      }

      if (mounted) {
        setState(() {
          dashboardData = data;
          isLoading = false;
          isRefreshing = false;
        });
        if (isRefresh) {
          KSnackBar.success(context, 'Dashboard updated successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = _getErrorMessage(e);
          isLoading = false;
          isRefreshing = false;
        });
        KSnackBar.failure(context, _getErrorMessage(e));
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('not found')) {
      return 'Teacher data not found. Please try again.';
    }
    return 'Unable to load dashboard. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    _updateScreenDimensions();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      body: RefreshIndicator(
        onRefresh: () => _loadDashboardData(isRefresh: true),
        color: AppColors.primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Use the new animated header
            TeacherHeaderSliverAppBar(
              // ✨ FIX: Prioritize the name from fetched dashboard data for accuracy.
              // This ensures the header shows the correct name from the database,
              // falling back to the auth name or widget property if necessary.
              teacherName: dashboardData?.teacherName ?? _teacherDisplayName ?? widget.teacherName,
              institutionName: widget.institutionName,
              photoUrl: _teacherPhotoUrl,
              dashboardData: dashboardData,
              isLoading: isLoading,
              isMobile: isMobileScreen,
            ),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) return _buildLoadingWidget();
    if (errorMessage != null) return _buildErrorWidget();
    if (dashboardData == null) {
      return const SliverFillRemaining(
        child: Center(child: Text('No dashboard data available.')),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(
        left: isMobileScreen ? 16.0 : 24.0,
        right: isMobileScreen ? 16.0 : 24.0,
        top: 16.0,
        bottom: 90,
      ),
      sliver: SliverToBoxAdapter(
        child: Responsive(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        StatsGrid(data: dashboardData!),
        const KVerticalSpacer(height: 24),
        QuickActions(
          teacherId: widget.teacherId,
          institutionName: widget.institutionName,
          teacherName: widget.teacherName,
        ),
        const KVerticalSpacer(height: 24),
        ModernRecentActivity(activities: dashboardData!.recentActivities),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        StatsGrid(data: dashboardData!, crossAxisCount: 4),
        const KVerticalSpacer(height: 24),
        QuickActions(
          teacherId: widget.teacherId,
          institutionName: widget.institutionName,
          teacherName: widget.teacherName,
        ),
        const KVerticalSpacer(height: 24),
        ModernRecentActivity(activities: dashboardData!.recentActivities),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              StatsGrid(data: dashboardData!, crossAxisCount: 4),
              const KVerticalSpacer(height: 24),
              QuickActions(
                teacherId: widget.teacherId,
                institutionName: widget.institutionName,
                teacherName: widget.teacherName,
              ),
            ],
          ),
        ),
        const KHorizontalSpacer(width: 24),
        Expanded(
          flex: 1,
          child: ModernRecentActivity(
            activities: dashboardData!.recentActivities,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: isMobileScreen ? 60 : 70,
                  height: isMobileScreen ? 60 : 70,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                    strokeWidth: 4,
                  ),
                ),
                Icon(
                  Icons.school_rounded,
                  color: AppColors.primaryColor.withOpacity(0.7),
                  size: isMobileScreen ? 24 : 28,
                ),
              ],
            ),
            const KVerticalSpacer(height: 24),
            KText(
              text: 'Preparing your dashboard...',
              fontSize: isMobileScreen ? 16 : 18,
              textColor: AppColors.titleColor,
              fontWeight: FontWeight.w600,
            ),
            const KVerticalSpacer(height: 8),
            KText(
              text: 'Just a moment while we gather your data',
              fontSize: isMobileScreen ? 13 : 14,
              textColor: AppColors.subTitleColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return SliverFillRemaining(
      child: Center(
        child: Container(
          margin: EdgeInsets.all(isMobileScreen ? 24.0 : 32.0),
          padding: EdgeInsets.all(isMobileScreen ? 24 : 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobileScreen ? 20 : 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: isMobileScreen ? 48 : 56,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const KVerticalSpacer(height: 24),
              KText(
                text: 'Oops! Something went wrong',
                fontSize: isMobileScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                textColor: AppColors.titleColor,
                textAlign: TextAlign.center,
              ),
              const KVerticalSpacer(height: 8),
              KText(
                text: errorMessage ?? 'We encountered an unexpected error.',
                fontSize: isMobileScreen ? 14 : 15,
                textAlign: TextAlign.center,
                textColor: AppColors.subTitleColor,
              ),
              const KVerticalSpacer(height: 32),
              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const KText(
                  text: 'Try Again',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  textColor: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, isMobileScreen ? 48 : 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}