import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:intl/intl.dart';

class StudentHeaderSliverAppBar extends StatefulWidget {
  final String studentName;
  final String institutionName;
  final String? photoUrl;
  final int rank;
  final int testsCompleted;
  final bool isMobile;

  const StudentHeaderSliverAppBar({
    super.key,
    required this.studentName,
    required this.institutionName,
    this.photoUrl,
    required this.rank,
    required this.testsCompleted,
    this.isMobile = false,
  });

  @override
  State<StudentHeaderSliverAppBar> createState() => _StudentHeaderSliverAppBarState();
}

class _StudentHeaderSliverAppBarState extends State<StudentHeaderSliverAppBar>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _floatingController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));

    _floatingAnimation = Tween<double>(
      begin: -0.01,
      end: 0.01,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _headerController.forward();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getFormattedDate() {
    return DateFormat('MMM d, yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: widget.isMobile ? 220 : 260,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryColor,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: widget.isMobile ? 32 : 40,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    backgroundImage: widget.photoUrl != null
                                        ? NetworkImage(widget.photoUrl!)
                                        : null,
                                    child: widget.photoUrl == null
                                        ? KText(
                                            text: _getInitials(widget.studentName),
                                            fontSize: widget.isMobile ? 24 : 30,
                                            textColor: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        KText(
                                          text: _getGreeting(),
                                          fontSize: widget.isMobile ? 14 : 16,
                                          textColor: Colors.white.withOpacity(0.9),
                                        ),
                                        KText(
                                          text: widget.studentName,
                                          fontSize: widget.isMobile ? 20 : 24,
                                          fontWeight: FontWeight.bold,
                                          textColor: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoItem(
                                      icon: Icons.emoji_events,
                                      label: 'Rank #${widget.rank}',
                                      isMobile: widget.isMobile,
                                    ),
                                    Container(width: 1, height: 20, color: Colors.white.withOpacity(0.3)),
                                    _buildInfoItem(
                                      icon: Icons.quiz,
                                      label: '${widget.testsCompleted} Tests',
                                      isMobile: widget.isMobile,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required bool isMobile,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: isMobile ? 14 : 16,
        ),
        const SizedBox(width: 8),
        KText(
          text: label,
          fontSize: isMobile ? 11 : 12,
          textColor: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}