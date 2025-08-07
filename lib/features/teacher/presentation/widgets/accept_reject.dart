// features/teacher/presentation/accept_reject.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studysync/commons/widgets/k_snack_bar.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/commons/widgets/responsive.dart';
import 'package:studysync/core/services/teacher_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';
import 'package:studysync/features/teacher/presentation/widgets/request_card.dart';

class RequestManagementPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String institutionName;

  const RequestManagementPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.institutionName,
  });

  @override
  State<RequestManagementPage> createState() => _RequestManagementPageState();
}

class _RequestManagementPageState extends State<RequestManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _headerController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _floatingAnimation;

  List<StudentRequest> allRequests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupAnimations();
    _loadRequests();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutExpo),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );

    _floatingAnimation = Tween<double>(begin: -0.015, end: 0.015).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _headerController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final requests = await TeacherService.getAllRequests(
        widget.teacherId,
        widget.institutionName,
      );

      if (mounted) {
        setState(() {
          allRequests = requests;
          isLoading = false;
        });

        _headerController.forward();
        _fadeController.forward();
        _slideController.forward();
        _pulseController.repeat(reverse: true);
        _floatingController.repeat(reverse: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
        _headerController.forward();
      }
    }
  }

  Future<void> _handleRequest(
    StudentRequest request,
    RequestStatus newStatus,
  ) async {
    _showEnhancedLoadingDialog(newStatus);

    try {
      final success = await TeacherService.updateRequestStatus(
        widget.teacherId,
        widget.institutionName,
        request.id,
        newStatus,
      );

      Navigator.pop(context);

      if (success) {
        setState(() {
          final index = allRequests.indexWhere((r) => r.id == request.id);
          if (index != -1) {
            final updatedRequest = request.copyWith(
              status: newStatus,
              processedDate: DateTime.now(),
            );
            allRequests[index] = updatedRequest;
          }
        });

        KSnackBar.success(
          context,
          'Request ${newStatus.name} successfully! 🎉',
        );

        await Future.delayed(const Duration(milliseconds: 500));
        await _loadRequests();
      } else {
        throw Exception('Failed to update request status.');
      }
    } catch (e) {
      Navigator.pop(context);
      KSnackBar.failure(context, 'Error occurred: ${e.toString()}');
      await _loadRequests();
    }
  }

  void _showEnhancedLoadingDialog(RequestStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.95),
                status.color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: status.color.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 15),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      status.color,
                      status.color.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: status.color.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Processing Request',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status.color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Please wait while we ${status.name} this request...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final pending =
        allRequests.where((r) => r.status == RequestStatus.pending).toList();
    final accepted =
        allRequests.where((r) => r.status == RequestStatus.accepted).toList();
    final rejected =
        allRequests.where((r) => r.status == RequestStatus.rejected).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        color: AppColors.primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        child: CustomScrollView(
          slivers: [
            _buildEnhancedSliverAppBar(isMobile, pending, accepted, rejected),
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                _buildEnhancedTabBar(pending, accepted, rejected, isMobile),
              ),
              pinned: true,
            ),
            _buildBody(pending, accepted, rejected, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSliverAppBar(
    bool isMobile,
    List<StudentRequest> pending,
    List<StudentRequest> accepted,
    List<StudentRequest> rejected,
  ) {
    return SliverAppBar(
      expandedHeight: isMobile ? 220 : 250,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
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
                          AppColors.primaryColor.withOpacity(0.9),
                          AppColors.scaffoldBgLightColor.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.7, 1.0],
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
                        Positioned(
                          top: 40,
                          left: 30,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 20 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding:
                                          EdgeInsets.all(isMobile ? 12 : 16),
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
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.assignment_outlined,
                                        color: Colors.white,
                                        size: isMobile ? 24 : 28,
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 16 : 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Request Management',
                                            style: TextStyle(
                                              fontSize: isMobile ? 24 : 32,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.school_rounded,
                                                  color: Colors.white,
                                                  size: isMobile ? 12 : 14,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  widget.institutionName,
                                                  style: TextStyle(
                                                    fontSize:
                                                        isMobile ? 10 : 12,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w600,
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
                                if (!isLoading)
                                  Container(
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatsItem(
                                            '${allRequests.length}',
                                            'Total',
                                            Icons.assignment,
                                            isMobile),
                                        _buildStatsItem('${pending.length}',
                                            'Pending', Icons.pending_actions, isMobile),
                                        _buildStatsItem(
                                            '${accepted.length}',
                                            'Accepted',
                                            Icons.check_circle,
                                            isMobile),
                                        _buildStatsItem(
                                            '${rejected.length}',
                                            'Rejected',
                                            Icons.cancel,
                                            isMobile),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
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

  Widget _buildStatsItem(
      String value, String label, IconData icon, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isMobile ? 12 : 14,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 11,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTabBar(
    List<StudentRequest> pending,
    List<StudentRequest> accepted,
    List<StudentRequest> rejected,
    bool isMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryColor,
        indicatorWeight: 4,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: AppColors.subTitleColor,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: [
          _buildEnhancedTab(
              'Pending', pending.length, Icons.pending_actions, true, isMobile),
          _buildEnhancedTab(
              'Accepted', accepted.length, Icons.check_circle, false, isMobile),
          _buildEnhancedTab(
              'Rejected', rejected.length, Icons.cancel, false, isMobile),
        ],
      ),
    );
  }

  Widget _buildEnhancedTab(
      String title, int count, IconData icon, bool isPending, bool isMobile) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Transform.scale(
                scale: isPending && count > 0 ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPending && count > 0
                          ? [
                              AppColors.primaryColor,
                              AppColors.primaryColor.withOpacity(0.8)
                            ]
                          : [
                              AppColors.primaryColor.withOpacity(0.15),
                              AppColors.primaryColor.withOpacity(0.1)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isPending && count > 0
                        ? [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.bold,
                      color: isPending && count > 0
                          ? Colors.white
                          : AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    List<StudentRequest> pending,
    List<StudentRequest> accepted,
    List<StudentRequest> rejected,
    bool isMobile,
  ) {
    if (isLoading) {
      return SliverFillRemaining(child: _buildEnhancedLoadingWidget(isMobile));
    }
    if (errorMessage != null) {
      return SliverFillRemaining(child: _buildEnhancedErrorWidget(isMobile));
    }

    return SliverFillRemaining(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(pending, RequestListType.pending, isMobile),
              _buildRequestList(accepted, RequestListType.accepted, isMobile),
              _buildRequestList(rejected, RequestListType.rejected, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedLoadingWidget(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 24 : 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.15),
                    AppColors.scaffoldBgLightColor.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                strokeWidth: isMobile ? 4 : 5,
              ),
            ),
            KVerticalSpacer(height: isMobile ? 24 : 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Loading Requests',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fetching student requests from the server...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: AppColors.subTitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedErrorWidget(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(isMobile ? 24 : 32),
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.95),
                AppColors.scaffoldBgLightColor.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.scaffoldBgLightColor.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 15),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.scaffoldBgLightColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.scaffoldBgLightColor.withOpacity(0.15),
                      AppColors.scaffoldBgLightColor.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.scaffoldBgLightColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: isMobile ? 48 : 56,
                  color: AppColors.scaffoldBgLightColor,
                ),
              ),
              KVerticalSpacer(height: isMobile ? 24 : 28),
              Text(
                'Failed to Load Requests',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const KVerticalSpacer(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBgLightColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.scaffoldBgLightColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  errorMessage ??
                      'An unknown error occurred. Please check your connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: AppColors.subTitleColor,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              KVerticalSpacer(height: isMobile ? 24 : 28),
              Container(
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
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _loadRequests,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: isMobile ? 14 : 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Try Again',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList(
    List<StudentRequest> requests,
    RequestListType type,
    bool isMobile,
  ) {
    if (requests.isEmpty) {
      return Center(child: _buildEnhancedEmptyState(type, isMobile));
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.white,
          ],
        ),
      ),
      child: ListView.separated(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        itemCount: requests.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: isMobile ? 12 : 16),
        itemBuilder: (context, index) {
          final request = requests[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 600 + (index * 150)),
            curve: Curves.easeOutCubic,
            child: RequestCard(
              request: request,
              onAccept: type == RequestListType.pending
                  ? () => _handleRequest(request, RequestStatus.accepted)
                  : null,
              onReject: type == RequestListType.pending
                  ? () => _handleRequest(request, RequestStatus.rejected)
                  : null,
              onViewDetails: () => _showEnhancedRequestDetails(request),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedEmptyState(RequestListType type, bool isMobile) {
    String title;
    String subtitle;
    IconData icon;
    Color color;

    switch (type) {
      case RequestListType.pending:
        title = 'No Pending Requests';
        subtitle = 'New student requests will appear here when submitted';
        icon = Icons.inbox_outlined;
        color = AppColors.primaryColor;
        break;
      case RequestListType.accepted:
        title = 'No Accepted Requests';
        subtitle = 'Approved student requests will be displayed here';
        icon = Icons.check_circle_outline;
        color = AppColors.primaryColor;
        break;
      case RequestListType.rejected:
        title = 'No Rejected Requests';
        subtitle = 'Declined student requests will be shown here';
        icon = Icons.cancel_outlined;
        color = AppColors.primaryColor;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 48,
            vertical: 32,
          ),
          padding: EdgeInsets.all(isMobile ? 28 : 36),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 15),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 24 : 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.12),
                      color.withOpacity(0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: isMobile ? 48 : 56,
                  color: color.withOpacity(0.8),
                ),
              ),
              KVerticalSpacer(height: isMobile ? 24 : 28),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const KVerticalSpacer(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: AppColors.subTitleColor,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnhancedRequestDetails(StudentRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedRequestDetailsSheet(
        request: request,
        onAccept: request.status == RequestStatus.pending
            ? () {
                Navigator.pop(context);
                _handleRequest(request, RequestStatus.accepted);
              }
            : null,
        onReject: request.status == RequestStatus.pending
            ? () {
                Navigator.pop(context);
                _handleRequest(request, RequestStatus.rejected);
              }
            : null,
      ),
    );
  }

  void _showEnhancedRequestAnalytics(
    List<StudentRequest> pending,
    List<StudentRequest> accepted,
    List<StudentRequest> rejected,
  ) {
    final total = allRequests.length;
    final isMobile = Responsive.isMobile(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFFAFAFA),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor.withOpacity(0.3),
                              AppColors.primaryColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor.withOpacity(0.1),
                              AppColors.scaffoldBgLightColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryColor,
                                    AppColors.primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Request Analytics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsStatCard(
                              'Total Requests',
                              '$total',
                              Icons.assignment_rounded,
                              AppColors.primaryColor,
                              isMobile,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnalyticsStatCard(
                              'Pending',
                              '${pending.length}',
                              Icons.pending_actions_rounded,
                              AppColors.primaryColor,
                              isMobile,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsStatCard(
                              'Accepted',
                              '${accepted.length}',
                              Icons.check_circle_rounded,
                              AppColors.scaffoldBgLightColor,
                              isMobile,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnalyticsStatCard(
                              'Rejected',
                              '${rejected.length}',
                              Icons.cancel_rounded,
                              AppColors.scaffoldBgLightColor,
                              isMobile,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDetailedAnalyticsCard(total, pending.length,
                          accepted.length, rejected.length, isMobile),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 18 : 20),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: AppColors.subTitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalyticsCard(
      int total, int pending, int accepted, int rejected, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.2),
                      AppColors.primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Detailed Breakdown',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          if (total > 0) ...[
            _buildProgressBar(
                'Pending', pending, total, AppColors.primaryColor, isMobile),
            const SizedBox(height: 12),
            _buildProgressBar('Accepted', accepted, total,
                AppColors.scaffoldBgLightColor, isMobile),
            const SizedBox(height: 12),
            _buildProgressBar('Rejected', rejected, total,
                AppColors.scaffoldBgLightColor, isMobile),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No data available yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
      String label, int value, int total, Color color, bool isMobile) {
    final percentage = total > 0 ? (value / total * 100).round() : 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.titleColor,
              ),
            ),
            Text(
              '$value ($percentage%)',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: total > 0 ? value / total : 0,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final Widget _tabBar;

  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _tabBar;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

enum RequestListType { pending, accepted, rejected }

class EnhancedRequestDetailsSheet extends StatefulWidget {
  final StudentRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const EnhancedRequestDetailsSheet({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
  });

  @override
  State<EnhancedRequestDetailsSheet> createState() =>
      _EnhancedRequestDetailsSheetState();
}

class _EnhancedRequestDetailsSheetState
    extends State<EnhancedRequestDetailsSheet> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return AnimatedBuilder(
          animation: Listenable.merge([_slideController, _fadeController]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.95),
                        Colors.white,
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 25,
                        offset: const Offset(0, -5),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildEnhancedHandle(),
                      _buildEnhancedHeader(),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            _buildPersonalInfoCard(),
                            const SizedBox(height: 20),
                            _buildRequestInfoCard(),
                            if (widget.request.message != null &&
                                widget.request.message!.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildMessageCard(),
                            ],
                            const SizedBox(height: 32),
                            _buildActionSection(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedHandle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.request.status.color.withOpacity(0.3),
              widget.request.status.color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.request.status.color.withOpacity(0.15),
            widget.request.status.color.withOpacity(0.08),
            widget.request.status.color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.request.status.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.request.status.color,
                  widget.request.status.color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.request.status.color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              widget.request.status.icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.request.studentName,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.request.status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.request.status.color.withOpacity(0.2),
              ),
            ),
            child: Text(
              widget.request.status.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: widget.request.status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.subTitleColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildDetailCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      color: AppColors.primaryColor,
      children: [
        _buildDetailItem(
            'Student Name', widget.request.studentName, Icons.person_rounded),
        _buildDetailItem(
            'Email', widget.request.studentEmail, Icons.email_rounded),
        _buildDetailItem(
            'Student ID', widget.request.studentId, Icons.badge_rounded),
      ],
    );
  }

  Widget _buildRequestInfoCard() {
    return _buildDetailCard(
      title: 'Request Information',
      icon: Icons.info_outline,
      color: AppColors.scaffoldBgLightColor,
      children: [
        _buildDetailItem(
            'Date',
            DateFormat('MMM dd, yyyy  •  hh:mm a')
                .format(widget.request.requestDate),
            Icons.calendar_today_rounded),
        _buildDetailItem(
            'Priority', widget.request.priorityLabel, Icons.priority_high_rounded),
        if (widget.request.processedDate != null)
          _buildDetailItem(
              'Processed Date',
              DateFormat('MMM dd, yyyy  •  hh:mm a')
                  .format(widget.request.processedDate!),
              Icons.update_rounded),
      ],
    );
  }

  Widget _buildMessageCard() {
    return _buildDetailCard(
      title: 'Student Message',
      icon: Icons.message_outlined,
      color: AppColors.primaryColor,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.request.message!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.subTitleColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    if (widget.onAccept == null && widget.onReject == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (widget.onReject != null)
          Expanded(
            child: _buildActionButton(
              'Reject',
              Icons.cancel_rounded,
              AppColors.scaffoldBgLightColor,
              widget.onReject!,
            ),
          ),
        if (widget.onAccept != null && widget.onReject != null)
          const SizedBox(width: 16),
        if (widget.onAccept != null)
          Expanded(
            child: _buildActionButton(
              'Accept',
              Icons.check_circle_rounded,
              AppColors.scaffoldBgLightColor,
              widget.onAccept!,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        shadowColor: color.withOpacity(0.3),
      ),
    );
  }
}