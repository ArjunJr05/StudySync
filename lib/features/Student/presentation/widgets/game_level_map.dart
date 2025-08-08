import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:studysync/core/services/test_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'dart:math' as math;
import 'code_editor.dart';


class KText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final TextAlign? textAlign;
  const KText({super.key, required this.text, this.fontSize, this.fontWeight, this.textColor, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: textColor), textAlign: textAlign);
  }
}



class GameLevelMapScreen extends StatefulWidget {
  final String studentId;
  final String difficulty;
  final int totalQuestions;
  final String institutionName;
  final String teacherName;

  const GameLevelMapScreen({
    super.key,
    required this.studentId,
    required this.difficulty,
    required this.totalQuestions,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<GameLevelMapScreen> createState() => _GameLevelMapScreenState();
}

class _GameLevelMapScreenState extends State<GameLevelMapScreen> {
  late ScrollController _scrollController;
  late ConfettiController _confettiController;
  final Map<int, Map<String, dynamic>> _answeredQuestions = {};
  bool _isLoading = true;
  int? _currentActiveQuestion;
  int _completedCount = 0;
  int _incorrectAnswers = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadAnsweredQuestions(); // This will now call the real Firestore service
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAnsweredQuestions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // **CORE CHANGE**: Call the real Firestore service extension
      final answered = await TestProgressExtension.getAnsweredQuestions(
        studentId: widget.studentId,
        subject: 'python', // Use 'python' as per the extension's design
        difficulty: widget.difficulty.toLowerCase(),
      );

      if (mounted) {
        setState(() {
          _answeredQuestions.clear();
          _answeredQuestions.addAll(answered);
          
          // The logic to calculate counts remains the same, but now uses real data
          _completedCount = answered.values.where((a) => a['correct'] == true).length;
          _incorrectAnswers = answered.values.where((a) => a['correct'] == false).length;
          _currentActiveQuestion = _getNextUnlockedQuestion();
          _isLoading = false;
        });

        // Animate to the current active question after the UI is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 300), _animateToCurrentQuestion);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading answered questions from Firestore: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load your progress. Please try again later.'))
        );
      }
    }
  }

  int? _getNextUnlockedQuestion() {
    for (int i = 1; i <= widget.totalQuestions; i++) {
      // Find the first question that has not been completed correctly.
      if (!_isQuestionCompleted(i)) {
        // It's playable if it's the first level, or the previous was completed, or it's an incorrect retry.
        if (_isQuestionUnlocked(i) || _isQuestionAnsweredIncorrectly(i)) {
          return i;
        }
      }
    }
    // All questions have been completed correctly
    return null;
  }

  // **VERIFIED**: These helper methods work correctly with the Firestore data structure.
  bool _isQuestionCompleted(int qNum) => _answeredQuestions.containsKey(qNum) && _answeredQuestions[qNum]?['correct'] == true;
  bool _isQuestionAnsweredIncorrectly(int qNum) => _answeredQuestions.containsKey(qNum) && _answeredQuestions[qNum]?['correct'] == false;
  bool _isQuestionUnlocked(int qNum) => qNum == 1 || _isQuestionCompleted(qNum - 1);

  /// **MODIFIED**: Refreshes progress after returning from the CodeEditorScreen.
  Future<void> _navigateToQuestion(int levelNumber) async {
    if (!_isQuestionUnlocked(levelNumber) && !_isQuestionAnsweredIncorrectly(levelNumber)) {
      _showEnhancedLockedQuestionDialog(levelNumber);
      return;
    }

    if (_isQuestionAnsweredIncorrectly(levelNumber)) {
      final shouldRetry = await _showRetryDialog(levelNumber);
      if (shouldRetry == null || !shouldRetry) return;
    }

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CodeEditorScreen(
              studentId: widget.studentId,
              difficulty: widget.difficulty,
              questionNumber: levelNumber,
              institutionName: widget.institutionName,
              teacherName: widget.teacherName,
          ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOutCubic));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );

    if (result == true && mounted) {
      await _loadAnsweredQuestions();
      if (_completedCount == widget.totalQuestions) {
        _confettiController.play();
        _showEnhancedLevelCompletedDialog();
      }
    }
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty.toUpperCase()) {
      case 'EASY': return AppColors.primaryColor;
      case 'MEDIUM': return AppColors.primaryGold;
      case 'HARD': return AppColors.ThemeRedColor;
      default: return AppColors.primaryColor;
    }
  }
  
  List<Color> _getDifficultyGradient() {
    switch (widget.difficulty.toUpperCase()) {
      case 'EASY': return [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)];
      case 'MEDIUM': return [AppColors.primaryGold, AppColors.primaryGold.withOpacity(0.8)];
      case 'HARD': return [AppColors.ThemeRedColor, AppColors.ThemeRedColor.withOpacity(0.9)];
      default: return [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)];
    }
  }

  void _animateToCurrentQuestion() {
    if (_currentActiveQuestion != null && _scrollController.hasClients) {
      final offset = (_currentActiveQuestion! - 1) * 180.0;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<bool> _showRetryDialog(int levelNumber) async {
    return await showDialog<bool>(
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
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 25,
                    offset: const Offset(0, 15),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  KText(
                    text: 'Retry Level $levelNumber?',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    textColor: AppColors.titleColor,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBgLightColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.scaffoldBgLightColor.withOpacity(0.2),
                      ),
                    ),
                    child: KText(
                      text:
                          'You answered this question incorrectly. Would you like to try again?',
                      textAlign: TextAlign.center,
                      textColor: AppColors.subTitleColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const KText(
                            text: 'Cancel',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getDifficultyColor(),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            shadowColor: _getDifficultyColor().withOpacity(0.3),
                          ),
                          child: const KText(
                            text: 'Try Again',
                            fontWeight: FontWeight.bold,
                            textColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _showEnhancedLockedQuestionDialog(int levelNumber) {
    showDialog(
      context: context,
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
                Colors.orange.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.15),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange,
                      Colors.orange.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              KText(
                text: 'Level $levelNumber Locked',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                textColor: Colors.orange,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                  ),
                ),
                child: KText(
                  text:
                      'Complete Level ${levelNumber - 1} correctly first to unlock this level.',
                  textAlign: TextAlign.center,
                  textColor: AppColors.subTitleColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.orange.withOpacity(0.3),
                ),
                child: const KText(
                  text: 'Got It!',
                  fontWeight: FontWeight.bold,
                  textColor: Colors.white,
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryLightColor,
        body: _isLoading
            ? _buildEnhancedLoadingScreen()
            : Stack(
                children: [
                  _buildEnhancedBackgroundDecoration(),
                  CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildEnhancedSliverAppBar(),
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryLightColor,
                                AppColors.primaryLightColor.withOpacity(0.8),
                                Colors.white.withOpacity(0.9),
                              ],
                            ),
                          ),
                          child: _buildGameMap(),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: math.pi / 2,
                      maxBlastForce: 5,
                      minBlastForce: 2,
                      emissionFrequency: 0.05,
                      numberOfParticles: 50,
                      gravity: 0.05,
                      colors: [
                        AppColors.primaryColor,
                        _getDifficultyColor(),
                        const Color(0xFFFFD700),
                        Colors.white,
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEnhancedLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.primaryLightColor,
      appBar: AppBar(
        title: KText(text: '${widget.difficulty} Levels'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLightColor,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.15),
                      AppColors.primaryColor.withOpacity(0.1),
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
                  strokeWidth: 5,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    KText(
                      text: 'Loading Your Levels',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      textColor: AppColors.titleColor,
                    ),
                    const SizedBox(height: 8),
                    KText(
                      text: 'Please wait while we prepare your game...',
                      textAlign: TextAlign.center,
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

  Widget _buildEnhancedBackgroundDecoration() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getDifficultyColor().withOpacity(0.05),
            AppColors.primaryColor.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getDifficultyGradient(),
            ),
          ),
          child: Stack(
            children: [
              // Enhanced decorative elements
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                left: 40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
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
                            child: Icon(
                              _getDifficultyIcon(),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                KText(
                                  text: '${widget.difficulty.toUpperCase()} LEVELS',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  textColor: Colors.white,
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
                                        Icons.emoji_events,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      KText(
                                        text:
                                            'Progress: $_completedCount/${widget.totalQuestions}',
                                        fontSize: 12,
                                        textColor: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: KText(
                              text:
                                  '${((_completedCount / widget.totalQuestions) * 100).toInt()}%',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              textColor: _getDifficultyColor(),
                            ),
                          ),
                        ],
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

  IconData _getDifficultyIcon() {
    switch (widget.difficulty.toUpperCase()) {
      case 'EASY':
        return Icons.sentiment_very_satisfied;
      case 'MEDIUM':
        return Icons.psychology;
      case 'HARD':
        return Icons.local_fire_department;
      default:
        return Icons.school;
    }
  }

  Widget _buildGameMap() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: _buildLevelPath(),
      ),
    );
  }

  List<Widget> _buildLevelPath() {
    List<Widget> pathItems = [];
    for (int i = 1; i <= widget.totalQuestions; i++) {
      pathItems.add(
        _buildQuestionNodeWithPath(i),
      );
    }
    return pathItems;
  }

  Widget _buildQuestionNodeWithPath(int levelNumber) {
    final isCompleted = _isQuestionCompleted(levelNumber);
    final isIncorrect = _isQuestionAnsweredIncorrectly(levelNumber);
    final isUnlocked = _isQuestionUnlocked(levelNumber);
    final isActive =
        _currentActiveQuestion == levelNumber && (isUnlocked || isIncorrect);

    final pathPattern = _getPathPattern(levelNumber);

    return Container(
      height: 160, // Increased height to prevent overflow
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Path to next level
          if (levelNumber < widget.totalQuestions)
            Positioned(
              top: 70,
              left: pathPattern.startX < pathPattern.endX
                  ? pathPattern.startX
                  : pathPattern.endX,
              child: CustomPaint(
                size: Size(
                  (pathPattern.endX - pathPattern.startX).abs(),
                  160.0,
                ),
                painter: EnhancedPathPainter(
                  startX: pathPattern.startX < pathPattern.endX
                      ? 0
                      : (pathPattern.startX - pathPattern.endX).abs(),
                  endX: pathPattern.startX < pathPattern.endX
                      ? (pathPattern.endX - pathPattern.startX).abs()
                      : 0,
                  color: isCompleted
                      ? _getDifficultyColor()
                      : Colors.grey.withOpacity(0.3),
                  isCompleted: isCompleted,
                ),
              ),
            ),
          // Level node
          Positioned(
            left: pathPattern.nodeX - 50,
            top: 20,
            child: _buildEnhancedQuestionNode(
                levelNumber, isCompleted, isIncorrect, isActive, isUnlocked),
          ),
          // Level label
          Positioned(
            left: pathPattern.nodeX - 80,
            top: 125, // Adjusted position to prevent overflow
            child: SizedBox(
              width: 160,
              child: Center(
                child: KText(
                  text: 'Level $levelNumber',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  textColor: isCompleted
                      ? _getDifficultyColor()
                      : isIncorrect
                          ? AppColors.ThemeRedColor
                          : isActive
                              ? _getDifficultyColor()
                              : isUnlocked
                                  ? AppColors.subTitleColor
                                  : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PathPattern _getPathPattern(int levelNumber) {
    final screenWidth = MediaQuery.of(context).size.width - 40;
    final centerX = screenWidth / 2;
    final amplitude = screenWidth * 0.35;
    final phase = (levelNumber - 1) * 1.2;
    final nodeX = centerX + amplitude * math.sin(phase);

    double startX = nodeX;
    double endX = nodeX;

    if (levelNumber < widget.totalQuestions) {
      final nextPhase = levelNumber * 1.2;
      endX = centerX + amplitude * math.sin(nextPhase);
    }

    return PathPattern(nodeX, startX, endX);
  }

  Widget _buildEnhancedQuestionNode(int levelNumber, bool isCompleted,
      bool isIncorrect, bool isActive, bool isUnlocked) {
    return GestureDetector(
      onTap: () => _navigateToQuestion(levelNumber),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _getEnhancedNodeGradient(
              isCompleted, isIncorrect, isActive, isUnlocked),
          border: Border.all(
            color: _getEnhancedNodeBorderColor(
                isCompleted, isIncorrect, isActive, isUnlocked),
            width: 4,
          ),
          boxShadow: [
            if (isActive || isCompleted || isIncorrect)
              BoxShadow(
                color: isIncorrect
                    ? AppColors.ThemeRedColor.withOpacity(0.5)
                    : _getDifficultyColor().withOpacity(0.5),
                blurRadius: isActive ? 25 : 15,
                spreadRadius: isActive ? 8 : 4,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
            if (isIncorrect)
              BoxShadow(
                color: AppColors.ThemeRedColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
          ],
        ),
        child: _buildEnhancedNodeContent(
            levelNumber, isCompleted, isIncorrect, isActive, isUnlocked),
      ),
    );
  }

  Widget _buildEnhancedNodeContent(int levelNumber, bool isCompleted,
      bool isIncorrect, bool isActive, bool isUnlocked) {
    if (isCompleted) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 45,
          ),
        ),
      );
    } else if (isIncorrect) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.transparent,
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    } else if (isActive && isUnlocked) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
      );
    } else if (isUnlocked) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: KText(
            text: '$levelNumber',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            textColor: Colors.white,
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.lock_rounded,
            color: Colors.grey[400],
            size: 40,
          ),
        ),
      );
    }
  }

  LinearGradient _getEnhancedNodeGradient(
      bool isCompleted, bool isIncorrect, bool isActive, bool isUnlocked) {
    if (isCompleted) {
      return LinearGradient(
        colors: [
          _getDifficultyColor(),
          _getDifficultyColor().withOpacity(0.8),
          _getDifficultyColor().withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.6, 1.0],
      );
    } else if (isIncorrect) {
      return LinearGradient(
        colors: [
          AppColors.ThemeRedColor,
          AppColors.ThemeRedColor.withOpacity(0.8),
          AppColors.ThemeRedColor.withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.6, 1.0],
      );
    } else if (isActive && isUnlocked) {
      return LinearGradient(
        colors: [
          _getDifficultyColor(),
          _getDifficultyColor().withOpacity(0.8),
          _getDifficultyColor().withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.6, 1.0],
      );
    } else if (isUnlocked) {
      return LinearGradient(
        colors: [
          AppColors.primaryColor.withOpacity(0.7),
          AppColors.primaryColor.withOpacity(0.5),
          AppColors.primaryColor.withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.6, 1.0],
      );
    } else {
      return LinearGradient(
        colors: [
          Colors.grey[300]!,
          Colors.grey[400]!,
          Colors.grey[350]!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.6, 1.0],
      );
    }
  }

  Color _getEnhancedNodeBorderColor(
      bool isCompleted, bool isIncorrect, bool isActive, bool isUnlocked) {
    if (isCompleted) {
      return _getDifficultyColor();
    } else if (isIncorrect) {
      return AppColors.ThemeRedColor;
    } else if (isActive && isUnlocked) {
      return _getDifficultyColor();
    } else if (isUnlocked) {
      return AppColors.primaryColor.withOpacity(0.7);
    } else {
      return Colors.grey[400]!;
    }
  }
void _showEnhancedLevelCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, // Make dialog background transparent
        insetPadding: const EdgeInsets.all(24), // Add some padding around the dialog
        child: Container(
          padding: const EdgeInsets.all(32),
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
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _getDifficultyColor().withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 20),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          // ✅ FIX: Wrap the Column with SingleChildScrollView
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getDifficultyColor(),
                        _getDifficultyColor().withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getDifficultyColor().withOpacity(0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                KText(
                  text: '🎉 All Levels Completed! 🎉',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  textColor: _getDifficultyColor(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getDifficultyColor().withOpacity(0.1),
                        _getDifficultyColor().withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getDifficultyColor().withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      KText(
                        text:
                            'Congratulations! You have successfully completed all ${widget.totalQuestions} levels in the ${widget.difficulty} difficulty.',
                        textAlign: TextAlign.center,
                        textColor: AppColors.subTitleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor.withOpacity(0.15),
                              AppColors.primaryColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events,
                                color: AppColors.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            KText(
                              text: '${widget.difficulty} Mastered!',
                              fontWeight: FontWeight.bold,
                              textColor: AppColors.primaryColor,
                              fontSize: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getDifficultyColor(),
                        _getDifficultyColor().withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getDifficultyColor().withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(); // Closes the dialog
                        // Assuming this dialog was pushed from another screen,
                        // this second pop would take you back further.
                        // Be sure this is the intended navigation behavior.
                        Navigator.of(context).pop(true);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            KText(
                              text: 'Continue to Next Challenge',
                              fontWeight: FontWeight.bold,
                              textColor: Colors.white,
                              fontSize: 16,
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
      ),
    );
  }
}

class PathPattern {
  final double nodeX;
  final double startX;
  final double endX;

  PathPattern(this.nodeX, this.startX, this.endX);
}

class EnhancedPathPainter extends CustomPainter {
  final double startX;
  final double endX;
  final Color color;
  final bool isCompleted;

  EnhancedPathPainter({
    required this.startX,
    required this.endX,
    required this.color,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.moveTo(startX, 0);

    final controlPointX = (startX + endX) / 2;
    final controlPointY = size.height / 2 - 60.0;

    path.quadraticBezierTo(controlPointX, controlPointY, endX, size.height);
    canvas.drawPath(path, paint);

    if (isCompleted) {
      // Add enhanced glow effect for completed paths
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
      canvas.drawPath(path, glowPaint);

      // Add inner glow
      final innerGlowPaint = Paint()
        ..color = color.withOpacity(0.6)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1);
      canvas.drawPath(path, innerGlowPaint);
    } else {
      // Add enhanced dashed pattern for incomplete paths
      final dashPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _drawDashedPath(canvas, path, dashPaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashLength = 12.0;
    const double gapLength = 8.0;
    final PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double nextDistance = distance + dashLength;
        final Path extractedPath = pathMetric.extractPath(
          distance,
          nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
        );
        canvas.drawPath(extractedPath, paint);
        distance = nextDistance + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}