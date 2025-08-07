// Enhanced Student Ranking Page with Alignment Fix
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/core/services/firestore_service.dart';
import 'package:studysync/commons/widgets/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRankingPage extends StatefulWidget {
  final String studentId;
  final String institutionName;
  final String teacherName;

  const StudentRankingPage({
    super.key,
    required this.studentId,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<StudentRankingPage> createState() =>
      _StudentRankingPageState();
}

class _StudentRankingPageState extends State<StudentRankingPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _rankings = [];
  Map<String, dynamic>? _currentStudentData;
  int _currentStudentRank = 0;
  String _selectedPeriod = 'All Time';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _timePeriods = ['This Week', 'This Month', 'All Time'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRankingData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _loadRankingData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email == null) {
        setState(() => _isLoading = false);
        debugPrint("Error: Current user not found.");
        return;
      }

      final students = await FirestoreService.getAllStudentsByTeacherName(
        widget.institutionName,
        widget.teacherName,
      );

      final processedData = _processAndRankStudents(students, currentUser.email!);

      final currentStudentFullData = students.firstWhere(
        (s) => s['email'] == currentUser.email,
        orElse: () => <String, dynamic>{},
      );

      if (mounted) {
        setState(() {
          _rankings = processedData;
          _currentStudentData = currentStudentFullData;
          _currentStudentRank = _findCurrentStudentRank();
          _isLoading = false;
        });

        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('Error loading ranking data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _processAndRankStudents(
    List<Map<String, dynamic>> students,
    String currentUserEmail,
  ) {
    final rankings = <Map<String, dynamic>>[];

    for (final student in students) {
      final performance = student['performance'] as Map<String, dynamic>? ?? {};
      final score = (performance['averageScore'] as num? ?? 0.0).toDouble();
      final testsCompleted = (performance['testsCompleted'] as int? ?? 0);
      final isCurrentUser = student['email'] == currentUserEmail;

      rankings.add({
        'name': isCurrentUser ? 'You' : (student['name'] ?? 'Unknown'),
        'fullName': student['name'] ?? 'Unknown Student',
        'score': score,
        'id': student['studentId'],
        'email': student['email'],
        'isCurrentUser': isCurrentUser,
        'avatar': _getInitials(student['name'] ?? 'S'),
        'testsCompleted': testsCompleted,
        'lastActive': (student['lastSignIn'] as Timestamp?)?.toDate() ??
            DateTime.now().subtract(const Duration(days: 30)),
      });
    }

    rankings.sort((a, b) {
      final scoreComp = (b['score'] as double).compareTo(a['score'] as double);
      if (scoreComp != 0) return scoreComp;
      return (b['testsCompleted'] as int).compareTo(a['testsCompleted'] as int);
    });

    for (int i = 0; i < rankings.length; i++) {
      rankings[i]['rank'] = i + 1;
    }

    return rankings;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  int _findCurrentStudentRank() {
    for (int i = 0; i < _rankings.length; i++) {
      if (_rankings[i]['isCurrentUser'] == true) {
        return _rankings[i]['rank'];
      }
    }
    return 0;
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
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
      body: _isLoading ? _buildLoadingState() : _buildRankingContent(),
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
            text: 'Loading rankings...',
            textColor: AppColors.subTitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingContent() {
    if (_rankings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRankingData,
        child: _buildEmptyState(),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadRankingData,
      color: AppColors.primaryColor,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildEnhancedAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTopRankersSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCurrentStudentCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildPeriodSelector(),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final student = _rankings[index];
              return FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (index * 50)),
                  child: _buildEnhancedRankingItem(student, index),
                ),
              );
            }, childCount: _rankings.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        _buildEnhancedAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),
                  const KText(
                    text: 'No Rankings Yet',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    textColor: AppColors.titleColor,
                  ),
                  const SizedBox(height: 8),
                  KText(
                    text:
                        'Your class ranking will appear here once your teacher has accepted students into the class.',
                    fontSize: 15,
                    textColor: AppColors.subTitleColor,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedAppBar() {
    final isMobile = Responsive.isMobile(context);
    return SliverAppBar(
      expandedHeight: isMobile ? 180 : 220,
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
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      KText(
                        text: 'Class Rankings',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      KText(
                        text: 'Your performance among classmates',
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

  Widget _buildTopRankersSection() {
    if (_rankings.length < 3) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              KText(
                text: 'Top Performers',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_rankings.length > 1) _buildPodiumPlace(_rankings[1], 2),
              if (_rankings.isNotEmpty) _buildPodiumPlace(_rankings[0], 1),
              if (_rankings.length > 2) _buildPodiumPlace(_rankings[2], 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(Map<String, dynamic> student, int position) {
    Color color = Colors.grey;
    double avatarSize = 60;

    switch (position) {
      case 1:
        color = Colors.amber;
        avatarSize = 80;
        break;
      case 2:
        color = Colors.grey.shade400;
        avatarSize = 70;
        break;
      case 3:
        color = const Color(0xFFCD7F32);
        avatarSize = 60;
        break;
    }

    return Column(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(avatarSize / 2),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: KText(
              text: student['avatar'],
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textColor: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: color, size: 20),
              const SizedBox(height: 4),
              KText(
                text: '$position',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                textColor: color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Column(
            children: [
              KText(
                text: student['name'],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
              KText(
                text: '${(student['score'] as double).toStringAsFixed(1)}%',
                fontSize: 11,
                textColor: AppColors.subTitleColor,
              ),
            ],
          ),
        ),
        
      ],
    );
  }

  Widget _buildCurrentStudentCard() {
    if (_currentStudentRank == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: KText(
                text: '#$_currentStudentRank',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                textColor: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KText(
                  text: 'Your Current Rank',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                KText(
                  text: 'Keep studying to improve!',
                  fontSize: 12,
                  textColor: AppColors.subTitleColor,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const KText(text: 'Period: ', fontWeight: FontWeight.w600),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timePeriods.map((period) {
                  final isSelected = period == _selectedPeriod;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: KText(
                        text: period,
                        fontSize: 12,
                        textColor:
                            isSelected ? Colors.white : AppColors.primaryColor,
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedPeriod = period);
                        }
                      },
                      backgroundColor: isSelected
                          ? AppColors.primaryColor
                          : AppColors.primaryColor.withOpacity(0.1),
                      selectedColor: AppColors.primaryColor,
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRankingItem(Map<String, dynamic> student, int index) {
    final bool isCurrentUser = student['isCurrentUser'] ?? false;
    final int rank = student['rank'];
    final String name = student['name'];
    final double score = student['score'];
    final int testsCompleted = student['testsCompleted'];
    final DateTime lastActive = student['lastActive'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: AppColors.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isCurrentUser
                ? AppColors.primaryColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            blurRadius: isCurrentUser ? 15 : 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          // ✨ FIXED: Added this line to vertically center all items in the row.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildRankIndicator(rank, isCurrentUser),
            const SizedBox(width: 16),
            _buildAvatarSection(student['avatar'], isCurrentUser),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStudentInfo(
                name,
                testsCompleted,
                lastActive,
                isCurrentUser,
              ),
            ),
            const SizedBox(width: 12),
            _buildScoreSection(score, isCurrentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildRankIndicator(int rank, bool isCurrentUser) {
    Color color;
    Widget content;

    if (rank == 1) {
      color = Colors.amber;
      content = const Icon(Icons.emoji_events, color: Colors.amber, size: 24);
    } else if (rank == 2) {
      color = Colors.grey.shade400;
      content = Icon(Icons.emoji_events, color: Colors.grey.shade400, size: 24);
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32);
      content = const Icon(
        Icons.emoji_events,
        color: Color(0xFFCD7F32),
        size: 24,
      );
    } else {
      color = isCurrentUser ? AppColors.primaryColor : AppColors.subTitleColor;
      content = KText(
        text: '$rank',
        fontWeight: FontWeight.bold,
        textColor: color,
        fontSize: 16,
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primaryColor, width: 1.5)
            : null,
      ),
      child: Center(child: content),
    );
  }

  Widget _buildAvatarSection(String initials, bool isCurrentUser) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrentUser
              ? [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.7),
                ]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(22),
        border: isCurrentUser
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: Center(
        child: KText(
          text: initials,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          textColor: isCurrentUser ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildStudentInfo(
    String name,
    int testsCompleted,
    DateTime lastActive,
    bool isCurrentUser,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KText(
          text: name,
          fontSize: 16,
          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
          textColor: isCurrentUser ? AppColors.primaryColor : Colors.black87,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: KText(
                text: '$testsCompleted tests',
                fontSize: 11,
                textColor: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            KText(
              text: '•',
              textColor: AppColors.subTitleColor.withOpacity(0.5),
            ),
            KText(
              text: _getTimeAgo(lastActive),
              fontSize: 11,
              textColor: AppColors.subTitleColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreSection(double score, bool isCurrentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        KText(
          text: '${score.toStringAsFixed(1)}%',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          textColor: isCurrentUser ? AppColors.primaryColor : Colors.black87,
        ),
        const SizedBox(height: 2),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score / 100,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}