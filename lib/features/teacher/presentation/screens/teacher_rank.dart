// Teacher Student Ranking Page with TeacherService Integration
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/core/services/teacher_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';
import 'package:studysync/commons/widgets/responsive.dart';

class TeacherStudentRankingPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String institutionName;

  const TeacherStudentRankingPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.institutionName,
  });

  @override
  State<TeacherStudentRankingPage> createState() =>
      _TeacherStudentRankingPageState();
}

class _TeacherStudentRankingPageState extends State<TeacherStudentRankingPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  
  // Dashboard data
  TeacherDashboardData? _dashboardData;
  
  // Student data
  List<StudentData> _studentRankings = [];
  List<StudentData> _filteredRankings = [];
  
  // Filter and sort options
  List<String> _classes = [];
  String _selectedClass = 'All Classes';
  String _selectedPeriod = 'All Time';
  String _searchQuery = '';
  String _sortBy = 'rank'; // rank, name, score
  bool _sortAscending = true;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _timePeriods = ['This Week', 'This Month', 'All Time'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAllData();
    _searchController.addListener(_onSearchChanged);
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

  Future<void> _loadAllData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Fetch dashboard data and student rankings using TeacherService
      final results = await Future.wait([
        TeacherService.getDashboardData(widget.teacherId, widget.institutionName),
        TeacherService.getStudentRankings(widget.teacherId, widget.institutionName),
      ]);

      final dashboardData = results[0] as TeacherDashboardData;
      final studentRankings = results[1] as List<StudentData>;

      // Extract unique classes from student data
      final classesSet = <String>{};
      for (final student in studentRankings) {
        // Since StudentData might not have className, we'll use a default class system
        // or check if there's an alternative field name like 'grade', 'class', or 'section'
        final classValue = _getStudentClass(student);
        if (classValue.isNotEmpty) {
          classesSet.add(classValue);
        }
      }
      final classes = classesSet.toList()..sort();

      if (mounted) {
        setState(() {
          _dashboardData = dashboardData;
          _studentRankings = studentRankings;
          _filteredRankings = studentRankings;
          _classes = ['All Classes', ...classes];
          _isLoading = false;
        });

        _filterAndSortRankings();
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _filterAndSortRankings();
  }

  void _filterAndSortRankings() {
    List<StudentData> filtered = List.from(_studentRankings);

    // Apply class filter
    if (_selectedClass != 'All Classes') {
      filtered = filtered.where((s) => _getStudentClass(s) == _selectedClass).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.studentId.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      final isAsc = _sortAscending;
      switch (_sortBy) {
        case 'name':
          return isAsc
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name);
        case 'score':
          return isAsc
              ? a.overallScore.compareTo(b.overallScore)
              : b.overallScore.compareTo(a.overallScore);
        case 'rank':
        default:
          return isAsc
              ? a.rank.compareTo(b.rank)
              : b.rank.compareTo(a.rank);
      }
    });

    setState(() {
      _filteredRankings = filtered;
    });
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
    _searchController.dispose();
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
            text: 'Loading student rankings...',
            textColor: AppColors.subTitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingContent() {
    // ✨ WHERE TO ADD: Wrap the CustomScrollView with a RefreshIndicator.
    return RefreshIndicator(
      onRefresh: _loadAllData, // This function fetches the latest data.
      color: AppColors.primaryColor,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        // Use AlwaysScrollableScrollPhysics to ensure refresh is always possible.
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildTeacherAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildStatsOverview(),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTopRankersSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildFilterSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSortHeader(),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final student = _filteredRankings[index];
              return FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (index * 50)),
                  child: _buildStudentRankingItem(student, index),
                ),
              );
            }, childCount: _filteredRankings.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildTeacherAppBar() {
    final isMobile = Responsive.isMobile(context);
    return SliverAppBar(
      expandedHeight: isMobile ? 200 : 240,
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      KText(
                        text: 'Student Rankings',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      KText(
                        text: _dashboardData?.teacherName != null 
                            ? '${_dashboardData!.teacherName} - ${_dashboardData!.institutionName}'
                            : 'Monitor your students\' performance',
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

  Widget _buildStatsOverview() {
    if (_dashboardData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Students', 
              '${_dashboardData!.totalStudents}', 
              Icons.people, 
              Colors.blue
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg Score',
              '${_dashboardData!.averageScore.toStringAsFixed(1)}%', 
              Icons.grade, 
              Colors.green
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Active Today', 
              '${_dashboardData!.activeToday}', 
              Icons.trending_up, 
              Colors.orange
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          KText(
            text: value,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textColor: color,
          ),
          KText(
            text: title,
            fontSize: 12,
            textColor: AppColors.subTitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTopRankersSection() {
    if (_filteredRankings.length < 3) return const SizedBox.shrink();

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
                text: 'Top 3 Performers',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_filteredRankings.length > 1)
                _buildPodiumPlace(_filteredRankings[1], 2),
              if (_filteredRankings.isNotEmpty)
                _buildPodiumPlace(_filteredRankings[0], 1),
              if (_filteredRankings.length > 2)
                _buildPodiumPlace(_filteredRankings[2], 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(StudentData student, int position) {
    Color color = Colors.grey;
    double height = 60;

    switch (position) {
      case 1:
        color = Colors.amber;
        height = 80;
        break;
      case 2:
        color = Colors.grey.shade400;
        height = 70;
        break;
      case 3:
        color = const Color(0xFFCD7F32);
        height = 60;
        break;
    }

    return GestureDetector(
      onTap: () => _showStudentDetails(student),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: KText(
                text: _getInitials(student.name),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                textColor: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: height,
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
                  text: student.name,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                ),
                KText(
                  text: '${student.overallScore.toStringAsFixed(1)}%',
                  fontSize: 11,
                  textColor: AppColors.subTitleColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // Helper method to get student class/grade info
  String _getStudentClass(StudentData student) {
    // Since StudentData might not have className property,
    // we'll try to extract class information from available fields
    // You can modify this based on your actual StudentData model structure
    
    // Option 1: If there's a grade field
    // return student.grade ?? 'Class A';
    
    // Option 2: If there's a class field with different name
    // return student.class ?? 'Class A';
    
    // Option 3: Default class assignment based on student ID pattern
    // This is a fallback approach
    // try {
    //   final id = student.studentId;
    //   if (id.contains('A') || id.contains('10')) return 'Class A';
    //   if (id.contains('B') || id.contains('11')) return 'Class B'; 
    //   if (id.contains('C') || id.contains('12')) return 'Class C';
    //   return 'Class A'; // Default
    // } catch (e) {
    //   return 'Class A'; // Default fallback
    return '';
    // }
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filters Row
          Row(
            children: [
              // Class Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedClass,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _classes.map((String className) {
                      return DropdownMenuItem<String>(
                        value: className,
                        child: Text(className),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedClass = newValue);
                        _filterAndSortRankings();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Period Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _timePeriods.map((String period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedPeriod = newValue);
                        _loadAllData();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const KText(text: 'Sort by: ', fontWeight: FontWeight.w600),
          _buildSortButton('Rank', 'rank'),
          _buildSortButton('Name', 'name'),
          _buildSortButton('Score', 'score'),
          const Spacer(),
          Text('${_filteredRankings.length} students'),
        ],
      ),
    );
  }

  Widget _buildSortButton(String label, String sortKey) {
    final isSelected = _sortBy == sortKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_sortBy == sortKey) {
              _sortAscending = !_sortAscending;
            } else {
              _sortBy = sortKey;
              _sortAscending = true;
            }
          });
          _filterAndSortRankings();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KText(
                text: label,
                fontSize: 12,
                textColor:
                    isSelected ? AppColors.primaryColor : AppColors.subTitleColor,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: AppColors.primaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRankingItem(StudentData student, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStudentDetails(student),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildRankIndicator(student.rank),
                const SizedBox(width: 16),
                _buildAvatarSection(student.name),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStudentInfo(student),
                ),
                const SizedBox(width: 12),
                _buildScoreSection(student.overallScore),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankIndicator(int rank) {
    Color color;
    Widget content;

    if (rank == 1) {
      color = Colors.amber;
      content = const Icon(Icons.emoji_events, color: Colors.amber, size: 20);
    } else if (rank == 2) {
      color = Colors.grey.shade400;
      content = Icon(Icons.emoji_events, color: Colors.grey.shade400, size: 20);
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32);
      content =
          const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20);
    } else {
      color = AppColors.subTitleColor;
      content = KText(
        text: '$rank',
        fontWeight: FontWeight.bold,
        textColor: color,
        fontSize: 14,
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: content),
    );
  }

  Widget _buildAvatarSection(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.7)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: KText(
          text: _getInitials(name),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          textColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStudentInfo(StudentData student) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KText(
        text: student.name,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        textColor: Colors.black87,
      ),
      const SizedBox(height: 4),
      // Replaced Row with Wrap to prevent overflow
      Wrap(
        spacing: 8.0, // Horizontal gap between items
        runSpacing: 4.0,  // Vertical gap between lines
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          KText(
            text: _getStudentClass(student).isNotEmpty ? _getStudentClass(student) : 'No Class',
            fontSize: 12,
            textColor: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.subTitleColor,
              shape: BoxShape.circle,
            ),
          ),
          KText(
            text: '${student.totalActivity} activities',
            fontSize: 12,
            textColor: AppColors.subTitleColor,
          ),
          if (student.isActiveToday)
            // Group the 'Active' indicator and text to keep them together
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const KText(
                  text: 'Active',
                  fontSize: 10,
                  textColor: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

  Widget _buildScoreSection(double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        KText(
          text: '${score.toStringAsFixed(1)}%',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          textColor: Colors.black87,
        ),
        const SizedBox(height: 2),
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score / 100,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showStudentDetails(StudentData student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStudentDetailsModal(student),
    );
  }

  Widget _buildStudentDetailsModal(StudentData student) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      _buildAvatarSection(student.name),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KText(
                              text: student.name,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            // KText(
                            //   text: student.className.isNotEmpty ? student.className : 'No Class',
                            //   textColor: AppColors.primaryColor,
                            //   fontSize: 14,
                            //   fontWeight: FontWeight.w600,
                            // ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: KText(
                          text: 'Rank #${student.rank}',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          textColor: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Performance Overview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const KText(
                          text: 'Performance Overview',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildPerformanceMetric('Overall Score',
                                    '${student.overallScore.toStringAsFixed(1)}%', Icons.grade)),
                            Expanded(
                                child: _buildPerformanceMetric(
                                    'Total Activities',
                                    '${student.totalActivity}',
                                    Icons.assignment)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _buildPerformanceMetric('Completion Rate',
                                    '${student.completionRate.toStringAsFixed(1)}%', Icons.check_circle)),
                            Expanded(
                                child: _buildPerformanceMetric('Status',
                                    student.isActiveToday ? 'Active' : 'Inactive', 
                                    student.isActiveToday ? Icons.online_prediction : Icons.offline_bolt)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Academic Details
                  const KText(
                    text: 'Academic Details',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Email', student.email, Icons.email),
                  _buildDetailRow(
                      'Last Active', student.lastActiveTime, Icons.schedule),

                  const SizedBox(height: 20),

                  // Subject Performance
                  if (student.subjectScores.isNotEmpty) ...[
                    const KText(
                      text: 'Subject Performance',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 12),
                    ...student.subjectScores.entries.map((entry) => 
                      _buildSubjectScore(entry.key, entry.value)
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Recent Activities
                  if (student.recentActivities.isNotEmpty) ...[
                    const KText(
                      text: 'Recent Activities',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: student.recentActivities.take(5).map((activity) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: AppColors.primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: KText(
                                    text: activity,
                                    fontSize: 12,
                                    textColor: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _sendMessageToStudent(student),
                          icon: const Icon(Icons.message),
                          label: const Text('Send Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _contactParent(student),
                          icon: const Icon(Icons.phone),
                          label: const Text('Contact Parent'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: const BorderSide(color: AppColors.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _viewDetailedReport(student),
                      icon: const Icon(Icons.analytics),
                      label: const Text('View Detailed Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primaryColor),
        const SizedBox(height: 8),
        KText(
          text: value,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          textColor: AppColors.primaryColor,
        ),
        KText(
          text: label,
          fontSize: 12,
          textColor: AppColors.subTitleColor,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.subTitleColor),
          const SizedBox(width: 12),
          Expanded(
            child: KText(
                text: label, textColor: AppColors.subTitleColor, fontSize: 14),
          ),
          Expanded(
            child: KText(
              text: value,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectScore(String subject, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: KText(
              text: subject,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      score >= 80 ? Colors.green : 
                      score >= 60 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: KText(
                    text: '${score.toStringAsFixed(1)}%',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessageToStudent(StudentData student) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message ${student.name}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message sent to ${student.name}!'),
                  backgroundColor: AppColors.primaryColor,
                ),
              );
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _contactParent(StudentData student) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Parent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${student.name}'),
            const SizedBox(height: 8),
            Text('Student Email: ${student.email}'),
            const SizedBox(height: 16),
            const Text('Choose contact method:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening phone app...'),
                  backgroundColor: AppColors.primaryColor,
                ),
              );
            },
            icon: const Icon(Icons.phone, color: Colors.white),
            label: const Text('Call', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening SMS app...'),
                  backgroundColor: AppColors.primaryColor,
                ),
              );
            },
            icon: const Icon(Icons.sms, color: Colors.white),
            label: const Text('SMS', style: TextStyle(color: Colors.white)),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }

  void _viewDetailedReport(StudentData student) {
    Navigator.pop(context);
    // Navigate to detailed report page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening detailed report for ${student.name}...'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }
}