// Enhanced Student Dashboard Main with Fixed Navigation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studysync/commons/widgets/responsive.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/core/services/auth_service.dart';
import 'package:studysync/core/services/firestore_service.dart';
import 'package:studysync/features/student/presentation/screens/profile.dart';
import 'package:studysync/features/student/presentation/screens/ranking.dart';
import 'package:studysync/features/student/presentation/screens/student_home.dart';
// ✨ Added import for the header widget
import 'package:studysync/features/student/presentation/widgets/student_header.dart';

class StudentDashboardMain extends StatefulWidget {
  final String studentId;
  final String institutionName;
  final String teacherName;

  const StudentDashboardMain({
    super.key,
    required this.studentId,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<StudentDashboardMain> createState() => _StudentDashboardMainState();
}

class _StudentDashboardMainState extends State<StudentDashboardMain>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPageChanging = false;

  late final List<Widget> _pages;
  late final List<BottomNavItem> _navItems;

  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  List<Map<String, dynamic>> _classmates = [];
  int _currentRank = 0;
  String _studentName = '';
  String? _photoUrl; // This will hold the Google Photo URL

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializePages();
    _setupNavItems();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initializePages() {
    _pages = [
      StudentHomePage(
        key: const PageStorageKey('home_page'),
        studentId: widget.studentId,
        institutionName: widget.institutionName,
        teacherName: widget.teacherName,
      ),
      StudentRankingPage(
        key: const PageStorageKey('ranking_page'),
        studentId: widget.studentId,
        institutionName: widget.institutionName,
        teacherName: widget.teacherName,
      ),
      StudentProfilePage(
        key: const PageStorageKey('profile_page'),
        studentId: widget.studentId,
        institutionName: widget.institutionName,
        teacherName: widget.teacherName,
      ),
    ];
  }

  void _setupNavItems() {
    _navItems = [
      BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_filled,
        label: 'Home',
        color: AppColors.primaryColor,
      ),
      BottomNavItem(
        icon: Icons.leaderboard_outlined,
        activeIcon: Icons.leaderboard,
        label: 'Rankings',
        color: AppColors.primaryColor,
      ),
      BottomNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        color: AppColors.primaryColor,
      ),
    ];
  }

  Future<void> _loadDashboardData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final currentUser = AuthService.getCurrentUser();
      final studentData = await FirestoreService.getStudentData(
        currentUser?.email ?? '',
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
          _classmates = classmates;
          _studentName = studentData?['name'] ?? 'Student';
          // ✨ Fetch the photo URL from the authenticated user object
          _photoUrl = currentUser?.photoURL;
          _currentRank = _calculateRank(studentData, classmates);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateRank(Map<String, dynamic>? studentData, List<Map<String, dynamic>> classmates) {
    if (studentData == null || classmates.isEmpty) return 0;
    
    // Sort classmates by performance to determine rank
    classmates.sort((a, b) {
      final scoreA = (a['performance']?['testsCompleted'] ?? 0) as int;
      final scoreB = (b['performance']?['testsCompleted'] ?? 0) as int;
      return scoreB.compareTo(scoreA); // Higher score is better
    });

    final rank = classmates.indexWhere((s) => s['studentId'] == studentData['studentId']) + 1;
    return rank > 0 ? rank : classmates.length + 1;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index || _isPageChanging) return;

    _isPageChanging = true;
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = index);

    _animationController.forward().then((_) {
      if (mounted) {
        _animationController.reverse();
        _isPageChanging = false;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isMobile = Responsive.isMobile(context);

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          _onItemTapped(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBgLightColor,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ✨ Display the header only when data is loaded
                if (!_isLoading)
                SliverFillRemaining(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
            // Floating bottom navigation remains the same
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: SafeArea(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildFloatingBottomNav(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(25),
        splashColor: item.color.withOpacity(0.1),
        highlightColor: item.color.withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? item.color.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey('${item.label}_$isSelected'),
                  color: isSelected ? item.color : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: item.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}