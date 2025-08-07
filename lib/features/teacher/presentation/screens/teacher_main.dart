import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/teacher/presentation/screens/teacher_home.dart';
import 'package:studysync/features/teacher/presentation/screens/teacher_profile.dart';
import 'package:studysync/features/teacher/presentation/screens/teacher_rank.dart';
import 'package:studysync/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherDashboardMain extends StatefulWidget {
  final String teacherId;
  final String institutionName;
  final String teacherName;

  const TeacherDashboardMain({
    super.key,
    required this.teacherId,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<TeacherDashboardMain> createState() => _TeacherDashboardMainState();
}

class _TeacherDashboardMainState extends State<TeacherDashboardMain>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPageChanging = false;
  
  // User data
  User? _currentUser;
  String? _displayName;
  String? _photoUrl;

  late final List<Widget> _pages;
  late final List<BottomNavItem> _navItems;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupAnimations();
    _initializePages();
    _setupNavItems();
  }

  // Load current user data
  void _loadUserData() {
    try {
      _currentUser = AuthService.getCurrentUser();
      if (_currentUser != null) {
        _displayName = _currentUser!.displayName ?? widget.teacherName;
        _photoUrl = _currentUser!.photoURL;
        print('✅ User data loaded in main - Name: $_displayName, Photo: ${_photoUrl != null ? 'Available' : 'Not available'}');
      } else {
        _displayName = widget.teacherName;
        _photoUrl = null;
        print('⚠️ No current user found in main, using fallback name');
      }
    } catch (e) {
      print('❌ Error loading user data in main: $e');
      _displayName = widget.teacherName;
      _photoUrl = null;
    }
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
      TeacherHomePage(
        key: const PageStorageKey('teacher_home_page'),
        teacherId: widget.teacherId,
        institutionName: widget.institutionName,
        teacherName: _displayName ?? widget.teacherName,
      ),
      TeacherStudentRankingPage(
      key: const PageStorageKey('teacher_ranking_page'),
      teacherId: widget.teacherId,
      teacherName: _displayName ?? widget.teacherName,
      institutionName: widget.institutionName,
    ),
      TeacherProfilePage(
        key: const PageStorageKey('teacher_profile_page'),
        teacherId: widget.teacherId,
        institutionName: widget.institutionName,
        teacherName: _displayName ?? widget.teacherName,
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

  // Method to refresh user data and pages
  void _refreshUserData() {
    _loadUserData();
    // Reinitialize pages with updated user data
    _initializePages();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _isPageChanging = false;
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          _onItemTapped(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: _pages),
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
            color: isSelected ? item.color.withOpacity(0.1) : Colors.transparent,
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

// Helper class for the Bottom Navigation Bar
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