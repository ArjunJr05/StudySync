import 'package:flutter/material.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';

class AnimatedTeacherHeader extends StatefulWidget {
  final String teacherName;
  final String institutionName;
  final String? photoUrl;
  final TeacherDashboardData? dashboardData;
  final bool isLoading;
  final bool isMobile;

  const AnimatedTeacherHeader({
    super.key,
    required this.teacherName,
    required this.institutionName,
    this.photoUrl,
    this.dashboardData,
    this.isLoading = false,
    this.isMobile = false,
  });

  @override
  State<AnimatedTeacherHeader> createState() => _AnimatedTeacherHeaderState();
}

class _AnimatedTeacherHeaderState extends State<AnimatedTeacherHeader>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _headerController;
  late AnimationController _floatingController;
  late AnimationController _statsController;
  
  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _statsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Main header animation controller
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Floating animation controller
    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    // Stats animation controller
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Header fade animation
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    // Header slide animation
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));

    // Scale animation for avatar
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    // Floating animation for background elements
    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Stats slide animation
    _statsSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    _headerController.forward();
    _floatingController.repeat(reverse: true);
    
    // Start stats animation after header animation completes
    _headerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !widget.isLoading) {
        _statsController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedTeacherHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger stats animation when data becomes available
    if (oldWidget.isLoading && !widget.isLoading && widget.dashboardData != null) {
      _statsController.forward();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _floatingController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'T';
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildStatsItem(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: widget.isMobile ? 16 : 18,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: widget.isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: widget.isMobile ? 10 : 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDecorativeCircles() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _floatingAnimation.value,
          child: Stack(
            children: [
              Positioned(
                top: -40 + (_floatingAnimation.value * 10),
                right: -40 + (_floatingAnimation.value * 15),
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
                bottom: -30 + (_floatingAnimation.value * 8),
                left: -30 + (_floatingAnimation.value * 12),
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
                top: 40 + (_floatingAnimation.value * 5),
                left: 30 + (_floatingAnimation.value * 8),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderContent() {
    return AnimatedBuilder(
      animation: Listenable.merge([_headerController, _statsController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: SlideTransition(
            position: _headerSlideAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 20 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with avatar and title
                  Row(
                    children: [
                      // Animated Avatar container
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: EdgeInsets.all(widget.isMobile ? 4 : 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: widget.isMobile ? 28 : 32,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: widget.photoUrl != null
                                ? NetworkImage(widget.photoUrl!)
                                : null,
                            child: widget.photoUrl == null
                                ? Text(
                                    _getInitials(widget.teacherName),
                                    style: TextStyle(
                                      fontSize: widget.isMobile ? 20 : 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(width: widget.isMobile ? 16 : 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: widget.isMobile ? 14 : 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              widget.teacherName,
                              style: TextStyle(
                                fontSize: widget.isMobile ? 22 : 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    color: Colors.white,
                                    size: widget.isMobile ? 12 : 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      widget.institutionName,
                                      style: TextStyle(
                                        fontSize: widget.isMobile ? 11 : 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Animated Stats container
                  if (!widget.isLoading && widget.dashboardData != null)
                    Transform.translate(
                      offset: Offset(0, _statsSlideAnimation.value),
                      child: Opacity(
                        opacity: (1.0 - (_statsSlideAnimation.value / 50.0)).clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatsItem(
                                '${widget.dashboardData!.totalStudents}',
                                'Students',
                                Icons.people,
                              ),
                              // _buildStatsItem(
                              //   '${widget.dashboardData!.totalClasses}',
                              //   'Classes',
                              //   Icons.class_,
                              // ),
                            
                              _buildStatsItem(
                                _getFormattedDate(),
                                'Today',
                                Icons.today,
                              ),
                              _buildStatsItem(
                              'verified',
                                '',
                                Icons.verified_outlined,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.9),
            AppColors.scaffoldBgLightColor.withOpacity(0.8),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative floating circles
          _buildDecorativeCircles(),
          // Main header content
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildHeaderContent(),
          ),
        ],
      ),
    );
  }
}

// Usage example with SliverAppBar integration
class TeacherHeaderSliverAppBar extends StatelessWidget {
  final String teacherName;
  final String institutionName;
  final String? photoUrl;
  final TeacherDashboardData? dashboardData;
  final bool isLoading;
  final bool isMobile;

  const TeacherHeaderSliverAppBar({
    super.key,
    required this.teacherName,
    required this.institutionName,
    this.photoUrl,
    this.dashboardData,
    this.isLoading = false,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: isMobile ? 280 : 320,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedTeacherHeader(
          teacherName: teacherName,
          institutionName: institutionName,
          photoUrl: photoUrl,
          dashboardData: dashboardData,
          isLoading: isLoading,
          isMobile: isMobile,
        ),
      ),
    );
  }
}