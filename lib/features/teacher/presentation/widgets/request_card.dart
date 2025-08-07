// features/teacher/presentation/widgets/request_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studysync/commons/widgets/responsive.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';

class RequestCard extends StatefulWidget {
  final StudentRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback onViewDetails;

  const RequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
    required this.onViewDetails,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> 
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: 8.0, end: 20.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.01).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _slideController.forward();
    if (widget.request.isPending) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Color _getStatusColor() => widget.request.status.color;
  IconData _getStatusIcon() => widget.request.status.icon;

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isActionable = widget.request.isPending && 
        widget.onAccept != null && widget.onReject != null;
    final isMobile = Responsive.isMobile(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _hoverController, 
        _pulseController, 
        _slideController
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.95),
                      _getStatusColor().withOpacity(0.02),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor().withOpacity(0.15),
                      blurRadius: _elevationAnimation.value,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: _elevationAnimation.value * 0.6,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: _getStatusColor().withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                  child: InkWell(
                    onTap: widget.onViewDetails,
                    onHover: (isHovered) {
                      isHovered 
                          ? _hoverController.forward() 
                          : _hoverController.reverse();
                    },
                    borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                    child: Stack(
                      children: [
                        // Background decorative elements
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getStatusColor().withOpacity(0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -15,
                          left: -15,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getStatusColor().withOpacity(0.03),
                            ),
                          ),
                        ),
                        // Main content
                        Column(
                          children: [
                            _buildEnhancedHeader(context, isMobile),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 20 : 24,
                                vertical: isMobile ? 16 : 20,
                              ),
                              child: _buildInfoSection(isMobile),
                            ),
                            if (isActionable) ...[
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      _getStatusColor().withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              _buildEnhancedActionButtons(isMobile),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor().withOpacity(0.12),
            _getStatusColor().withOpacity(0.08),
            _getStatusColor().withOpacity(0.04),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMobile ? 20 : 24),
          topRight: Radius.circular(isMobile ? 20 : 24),
        ),
      ),
      child: Row(
        children: [
          // Enhanced Avatar
          Transform.scale(
            scale: widget.request.isPending ? _pulseAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getStatusColor(),
                    _getStatusColor().withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor().withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: isMobile ? 28 : 32,
                backgroundColor: Colors.transparent,
                child: Text(
                  _getInitials(widget.request.studentName),
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 16 : 20),
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.request.studentName,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.subTitleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.request.studentEmail,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: AppColors.subTitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Enhanced Status Badge
          _buildEnhancedStatusBadge(isMobile),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatusBadge(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 14,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.2),
            _getStatusColor().withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: isMobile ? 14 : 16,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 6),
          Text(
            widget.request.status.displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getStatusColor(),
              fontSize: isMobile ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isMobile) {
    return Column(
      children: [
        _buildEnhancedInfoRow(
          icon: Icons.calendar_today_rounded,
          label: 'Request Date',
          value: DateFormat('MMM dd, yyyy  •  hh:mm a').format(widget.request.requestDate),
          color: AppColors.primaryColor,
          isMobile: isMobile,
        ),
        if (widget.request.processedDate != null) ...[
          SizedBox(height: isMobile ? 12 : 16),
          _buildEnhancedInfoRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Processed Date',
            value: DateFormat('MMM dd, yyyy  •  hh:mm a').format(widget.request.processedDate!),
            color: _getStatusColor(),
            isMobile: isMobile,
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButtons(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Row(
        children: [
          // Reject Button
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.scaffoldBgLightColor,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: widget.onReject,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 12 : 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          color: AppColors.primaryColor,
                          size: isMobile ? 18 : 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reject',
                          style: TextStyle(
                            color: AppColors.primaryColor,
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
          ),
          const SizedBox(width: 16),
          // Accept Button
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: widget.onAccept,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 12 : 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Accept',
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
          ),
        ],
      ),
    );
  }
}