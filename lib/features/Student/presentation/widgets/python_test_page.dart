import 'package:flutter/material.dart';
import 'package:studysync/core/services/test_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/features/Student/presentation/widgets/game_level_map.dart'
    show GameLevelMapScreen;

class PythonTestPage extends StatefulWidget {
  final String studentId;
  final String institutionName;
  final String teacherName;

  const PythonTestPage({
    super.key,
    required this.studentId,
    // NEW: Added to constructor
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<PythonTestPage> createState() => _PythonTestPageState();
}

class _PythonTestPageState extends State<PythonTestPage>
    with SingleTickerProviderStateMixin {
  Map<String, int> _completedQuestions = {
    'EASY': 0,
    'MEDIUM': 0,
    'HARD': 0,
  };

  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProgressFromDatabase();
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
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressFromDatabase() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final progress =
          await TestProgressExtension.getStudentTestProgress(widget.studentId);

      if (mounted) {
        setState(() {
          _completedQuestions = {
            'EASY': progress['python_easy_completed'] ?? 0,
            'MEDIUM': progress['python_medium_completed'] ?? 0,
            'HARD': progress['python_hard_completed'] ?? 0,
          };
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  bool _isLevelUnlocked(String level) {
    switch (level) {
      case 'EASY':
        return true;
      case 'MEDIUM':
        return _completedQuestions['EASY']! >= 10;
      case 'HARD':
        return _completedQuestions['MEDIUM']! >= 10;
      default:
        return false;
    }
  }

  bool _isLevelCompleted(String level) {
    final requiredLevels = level == 'HARD' ? 5 : 10;
    return _completedQuestions[level]! >= requiredLevels;
  }

  String _getLevelStatus(String level) {
    if (_isLevelCompleted(level)) {
      return 'Completed';
    } else if (_isLevelUnlocked(level)) {
      return 'Available';
    } else {
      return 'Locked';
    }
  }

  Future<void> _navigateToLevel(String level, int totalLevels) async {
    if (!_isLevelUnlocked(level)) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GameLevelMapScreen(
          studentId: widget.studentId,
          difficulty: level,
          totalQuestions: totalLevels,
          institutionName: widget.institutionName,
          teacherName: widget.teacherName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutBack,
            )),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutBack,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );

    if (result == true || result == null) {
      await _loadProgressFromDatabase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 32),
                  _buildOverallProgress(),
                  const SizedBox(height: 40),
                  _buildTestLevels(),
                  const SizedBox(height: 40),
                  _buildTipsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.1),
                  ),
                ),
                child: const Column(
                  children: [
                    KText(
                      text: 'Loading Python Tests',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      textColor: AppColors.titleColor,
                    ),
                    SizedBox(height: 8),
                    KText(
                      text: 'Preparing your learning journey...',
                      textColor: AppColors.subTitleColor,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF8FAFC),
              ],
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.code_rounded,
                        color: AppColors.primaryColor,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      KText(
                        text: 'Python Tests',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        textColor: AppColors.titleColor,
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
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.08),
            AppColors.primaryColor.withOpacity(0.03),
            Colors.white.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(
                      text: 'Master Python Programming',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      textColor: AppColors.titleColor,
                    ),
                    SizedBox(height: 4),
                    KText(
                      text: 'Progressive learning through interactive tests',
                      textColor: AppColors.subTitleColor,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
            ),
            child: const KText(
              text:
                  '🎯 Complete levels sequentially to unlock advanced challenges\n'
                  '📚 Each level focuses on specific Python concepts\n'
                  '🏆 Master all difficulties to become a Python expert',
              textColor: AppColors.subTitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    final totalCompleted = _completedQuestions.values.reduce((a, b) => a + b);
    const totalLevels = 30;
    final overallPercentage =
        totalLevels > 0 ? (totalCompleted / totalLevels * 100).round() : 0;


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.2),
                      AppColors.primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(
                      text: 'Overall Progress',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      textColor: AppColors.titleColor,
                    ),
                    KText(
                      text: 'Your learning journey',
                      fontSize: 13,
                      textColor: AppColors.subTitleColor,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: KText(
                  text: '$overallPercentage%',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalLevels > 0 ? totalCompleted / totalLevels : 0,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              KText(
                text: '$totalCompleted of $totalLevels levels completed',
                fontSize: 14,
                textColor: AppColors.subTitleColor,
                fontWeight: FontWeight.w500,
              ),
              KText(
                text: '${totalLevels - totalCompleted} remaining',
                fontSize: 10,
                textColor: AppColors.subTitleColor.withOpacity(0.7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestLevels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KText(
            text: 'Difficulty Levels',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textColor: AppColors.titleColor,
          ),
          const SizedBox(height: 8),
          const KText(
            text: 'Choose your challenge level',
            textColor: AppColors.subTitleColor,
            fontSize: 14,
          ),
          const SizedBox(height: 24),
          _buildEnhancedTestLevelCard(
            context: context,
            level: 'EASY',
            title: 'Easy Level',
            description: 'Perfect for beginners',
            details:
                'Variables, data types, basic operations, and control structures',
            totalLevels: 10,
            color: const Color(0xFF10B981),
            icon: Icons.school_rounded,
            gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
          ),
          const SizedBox(height: 20),
          _buildEnhancedTestLevelCard(
            context: context,
            level: 'MEDIUM',
            title: 'Medium Level',
            description: 'Build your expertise',
            details:
                'Lists, dictionaries, functions, modules, and file handling',
            totalLevels: 10,
            color: AppColors.primaryColor,
            icon: Icons.build_rounded,
            gradientColors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8)
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedTestLevelCard(
            context: context,
            level: 'HARD',
            title: 'Hard Level',
            description: 'Master advanced concepts',
            details:
                'Object-oriented programming, algorithms, and complex data structures',
            totalLevels: 15,
            color: const Color(0xFFEF4444),
            icon: Icons.local_fire_department_rounded,
            gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTestLevelCard({
    required BuildContext context,
    required String level,
    required String title,
    required String description,
    required String details,
    required int totalLevels,
    required Color color,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    final isUnlocked = _isLevelUnlocked(level);
    final isCompleted = _isLevelCompleted(level);
    final completedLevels = _completedQuestions[level]!;
    final status = _getLevelStatus(level);
    final percentage =
        totalLevels > 0 ? (completedLevels / totalLevels * 100).round() : 0;

    Widget titleAndBadgeWidget;
    if (isSmallScreen) {
      // Use a Column for smaller screens
      titleAndBadgeWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KText(
            text: title,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textColor: isUnlocked ? color : Colors.grey[600],
          ),
          const SizedBox(height: 8),
          _buildStatusBadge(status, isUnlocked, color),
        ],
      );
    } else {
      // Use a Row for larger screens
      titleAndBadgeWidget = Row(
        children: [
          Flexible(
            child: KText(
              text: title,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textColor: isUnlocked ? color : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusBadge(status, isUnlocked, color),
        ],
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: isUnlocked ? 8 : 3,
        shadowColor:
            isUnlocked ? color.withOpacity(0.3) : Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isCompleted
                ? color.withOpacity(0.5)
                : isUnlocked
                    ? color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToLevel(level, totalLevels),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  isUnlocked
                      ? color.withOpacity(0.02)
                      : Colors.grey.withOpacity(0.02),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUnlocked
                              ? gradientColors
                              : [Colors.grey[300]!, Colors.grey[400]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isUnlocked
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        icon,
                        color: isUnlocked ? Colors.white : Colors.grey[600],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleAndBadgeWidget, // ✨ Using the responsive widget
                          const SizedBox(height: 4),
                          KText(
                            text: description,
                            fontSize: 14,
                            textColor: AppColors.subTitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(height: 8),
                          KText(
                            text: details,
                            fontSize: 12,
                            textColor: AppColors.subTitleColor.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusIcon(isUnlocked, isCompleted, color),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProgressSection(
                    completedLevels, totalLevels, percentage, color, isUnlocked),
                if (!isUnlocked) ...[
                  const SizedBox(height: 16),
                  _buildLockMessage(level),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isUnlocked, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(status, isUnlocked, color).withOpacity(0.2),
            _getStatusColor(status, isUnlocked, color).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status, isUnlocked, color).withOpacity(0.3),
        ),
      ),
      child: KText(
        text: status,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        textColor: _getStatusColor(status, isUnlocked, color),
      ),
    );
  }

  Widget _buildStatusIcon(bool isUnlocked, bool isCompleted, Color color) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    }
    if (isUnlocked) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.lock_rounded,
        color: Colors.grey[600],
        size: 24,
      ),
    );
  }

  Widget _buildProgressSection(
      int completed, int total, int percentage, Color color, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isUnlocked ? color.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isUnlocked ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              KText(
                text: '$completed / $total levels',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                textColor: isUnlocked ? color : Colors.grey[600],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked ? color : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: KText(
                  text: '$percentage%',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  isUnlocked ? color : Colors.grey[400]!),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockMessage(String level) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KText(
              text: _getUnlockRequirement(level),
              fontSize: 13,
              textColor: Colors.orange[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.08),
            const Color(0xFF3B82F6).withOpacity(0.03),
            Colors.white.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const KText(
                text: 'Success Tips',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                textColor: Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTipItem(
            '🎯',
            'Sequential Learning',
            'Complete levels in order to build strong foundations',
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            '🔍',
            'Review & Practice',
            'Study explanations after each question for better understanding',
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            '🏆',
            'Master All Levels',
            'Complete Easy → Medium → Hard to become a Python expert',
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            '⚡',
            'Stay Consistent',
            'Regular practice leads to mastery and confidence',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
            ),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KText(
                text: title,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                textColor: AppColors.titleColor,
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
    );
  }

  Color _getStatusColor(String status, bool isUnlocked, Color levelColor) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF10B981);
      case 'Available':
        return isUnlocked ? levelColor : Colors.grey[600]!;
      case 'Locked':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getUnlockRequirement(String level) {
    switch (level) {
      case 'MEDIUM':
        return 'Complete all 10 Easy levels to unlock Medium difficulty';
      case 'HARD':
        return 'Complete all 10 Medium levels to unlock Hard difficulty';
      default:
        return '';
    }
  }
}