import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:studysync/features/Student/presentation/widgets/code_editor.dart';
import 'package:studysync/features/Student/presentation/widgets/video_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  final String studentId;
  final String difficulty;
  final int questionNumber;
  final String institutionName;
  final String teacherName;

  const VideoPlayerScreen({
    super.key,
    required this.studentId,
    required this.difficulty,
    required this.questionNumber,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoCompleted = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isFullscreen = false;
  double _playbackSpeed = 1.0;
  
  // Timer variables
  Timer? _watchTimer;
  Duration _totalWatchedDuration = Duration.zero;
  bool _hasCompletedOnce = false;
  bool _showCenteredRewatch = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializeVideo();
  }

  /// Get video URL for specific level from .env file
  String? _getVideoUrlForLevel() {
    try {
      // Load the video URL based on difficulty and question number
      // Format: VIDEO_EASY_1, VIDEO_MEDIUM_2, VIDEO_HARD_3, etc.
      final String envKey = 'VIDEO_${widget.difficulty.toUpperCase()}_${widget.questionNumber}';
      final String? videoUrl = dotenv.env[envKey];
      
      if (videoUrl == null || videoUrl.isEmpty) {
        debugPrint('Video URL not found for key: $envKey');
        return null;
      }
      
      return videoUrl;
    } catch (e) {
      debugPrint('Error getting video URL from .env: $e');
      return null;
    }
  }

  /// Convert Google Drive share URL to direct download URL
  String _convertGoogleDriveUrl(String url) {
    // Handle different Google Drive URL formats
    if (url.contains('drive.google.com/file/d/')) {
      // Extract file ID from: https://drive.google.com/file/d/FILE_ID/view?usp=sharing
      final RegExp fileIdRegex = RegExp(r'/file/d/([a-zA-Z0-9-_]+)');
      final Match? match = fileIdRegex.firstMatch(url);
      if (match != null) {
        final String fileId = match.group(1)!;
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    } else if (url.contains('drive.google.com/open?id=')) {
      // Extract file ID from: https://drive.google.com/open?id=FILE_ID
      final RegExp fileIdRegex = RegExp(r'id=([a-zA-Z0-9-_]+)');
      final Match? match = fileIdRegex.firstMatch(url);
      if (match != null) {
        final String fileId = match.group(1)!;
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    } else if (url.contains('uc?export=download&id=') || url.contains('uc?id=')) {
      // URL is already in direct download format
      return url;
    }
    
    // If it's just a file ID
    if (url.length > 10 && !url.contains('/')) {
      return 'https://drive.google.com/uc?export=download&id=$url';
    }
    
    return url; // Return as-is if format is not recognized
  }

  /// Alternative method for larger files (uses Google Drive's direct streaming)
  String _convertGoogleDriveUrlForStreaming(String url) {
    String fileId = '';
    
    if (url.contains('drive.google.com/file/d/')) {
      final RegExp fileIdRegex = RegExp(r'/file/d/([a-zA-Z0-9-_]+)');
      final Match? match = fileIdRegex.firstMatch(url);
      if (match != null) {
        fileId = match.group(1)!;
      }
    } else if (url.contains('drive.google.com/open?id=')) {
      final RegExp fileIdRegex = RegExp(r'id=([a-zA-Z0-9-_]+)');
      final Match? match = fileIdRegex.firstMatch(url);
      if (match != null) {
        fileId = match.group(1)!;
      }
    } else if (url.contains('uc?export=download&id=')) {
      final RegExp fileIdRegex = RegExp(r'id=([a-zA-Z0-9-_]+)');
      final Match? match = fileIdRegex.firstMatch(url);
      if (match != null) {
        fileId = match.group(1)!;
      }
    } else if (url.length > 10 && !url.contains('/')) {
      fileId = url;
    }
    
    return fileId.isNotEmpty 
        ? 'https://drive.google.com/file/d/$fileId/preview'
        : url;
  }

    Future<void> _initializeVideo() async {
  try {
    // Get video URL from .env file using helper
    final String? videoUrl = VideoUrlHelper.getVideoUrl(
      difficulty: widget.difficulty,
      level: widget.questionNumber,
    );
    
    if (videoUrl == null) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Video not found for Level ${widget.questionNumber} in ${widget.difficulty} difficulty. Please check your configuration.';
        });
      }
      return;
    }

    // Get alternative URLs to try
    final List<String> alternativeUrls = VideoUrlHelper.getAlternativeUrls(videoUrl);
    
    // Try each URL until one works
    for (int i = 0; i < alternativeUrls.length; i++) {
      try {
        final String currentUrl = alternativeUrls[i];
        debugPrint('Attempting to load video from URL ${i + 1}/${alternativeUrls.length}: $currentUrl');
        
        _videoController?.dispose();
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(currentUrl),
          videoPlayerOptions: VideoPlayerOptions(
            allowBackgroundPlayback: false,
            mixWithOthers: false,
          ),
          httpHeaders: VideoUrlHelper.getVideoHeaders(),
        );

        // Set a timeout for initialization
        await _videoController!.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Video initialization timeout');
          },
        );
        
        if (mounted && _videoController!.value.isInitialized) {
          setState(() {
            _isVideoInitialized = true;
            _isLoading = false;
            _hasError = false;
          });

          // Listen for video completion
          _videoController!.addListener(_videoListener);
          
          // Auto-play the video and start timer
          _videoController!.play();
          _startWatchTimer();
          
          debugPrint('Video loaded successfully from URL ${i + 1}');
          return; // Success! Exit the method
        }
      } catch (e) {
        debugPrint('Failed to load video from URL ${i + 1}: $e');
        _videoController?.dispose();
        _videoController = null;
        
        // If this is the last URL and it failed, show error
        if (i == alternativeUrls.length - 1) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
              _errorMessage = _getErrorMessage(videoUrl);
            });
          }
        }
      }
    }
  } catch (e) {
    debugPrint('General video initialization error: $e');
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Failed to load video for Level ${widget.questionNumber}. Please check your internet connection.';
      });
    }
  }
}

String _getErrorMessage(String videoUrl) {
  if (VideoUrlHelper.isGoogleDriveUrl(videoUrl)) {
    return '''
Video loading failed. This might be due to:

• Google Drive sharing restrictions
• Large .mov file size limitations  
• Network connectivity issues

Recommendations:
• Ensure the Google Drive file is publicly accessible
• Try converting .mov to .mp4 format
• Use a different video hosting service like Firebase Storage or YouTube

Current video: Level ${widget.questionNumber} (${widget.difficulty})
''';
  } else {
    return 'Failed to load video for Level ${widget.questionNumber}. Please check the video URL and your internet connection.';
  }
}
void _retryVideoLoad() {
  setState(() {
    _isLoading = true;
    _hasError = false;
  });
  
  // Add a small delay before retrying
  Future.delayed(const Duration(milliseconds: 500), () {
    _initializeVideo();
  });
}

  void _startWatchTimer() {
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_videoController != null && _videoController!.value.isPlaying) {
        setState(() {
          _totalWatchedDuration = Duration(seconds: _totalWatchedDuration.inSeconds + 1);
        });
        
        if (_videoController!.value.isInitialized && !_hasCompletedOnce) {
          final videoDuration = _videoController!.value.duration;
          if (_totalWatchedDuration.inSeconds >= videoDuration.inSeconds) {
            _markAsCompleted();
          }
        }
      }
    });
  }

  void _videoListener() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      
      if (position.inMilliseconds >= (duration.inMilliseconds - 1000) && !_hasCompletedOnce) {
        _markAsCompleted();
      }
      
      final isAtEnd = position.inMilliseconds >= (duration.inMilliseconds - 1000);
      if (isAtEnd && !_videoController!.value.isPlaying && _hasCompletedOnce) {
        setState(() {
          _showCenteredRewatch = true;
        });
      } else {
        setState(() {
          _showCenteredRewatch = false;
        });
      }
      
      setState(() {
        _isVideoCompleted = _hasCompletedOnce || 
            (position.inMilliseconds >= (duration.inMilliseconds - 1000));
      });
    }
  }

  void _markAsCompleted() {
    if (!_hasCompletedOnce) {
      if (mounted) {
        setState(() {
          _hasCompletedOnce = true;
          _isVideoCompleted = true;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
      setState(() {
        _showCenteredRewatch = false;
      });
      if (!_hasCompletedOnce && (_watchTimer?.isActive != true)) {
        _startWatchTimer();
      }
    }
    setState(() {});
  }

  void _skipForward() {
    final currentPosition = _videoController!.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final maxPosition = _videoController!.value.duration;
    
    _videoController!.seekTo(
      newPosition > maxPosition ? maxPosition : newPosition,
    );
  }

  void _skipBackward() {
    final currentPosition = _videoController!.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    
    _videoController!.seekTo(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  void _changePlaybackSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    
    setState(() {
      _playbackSpeed = speeds[nextIndex];
    });
    
    _videoController!.setPlaybackSpeed(_playbackSpeed);
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isFullscreen) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _restartVideo() {
    _videoController?.seekTo(Duration.zero);
    _videoController?.play();
    setState(() {
      _showCenteredRewatch = false;
    });
    if (!_hasCompletedOnce) {
      setState(() {
        _totalWatchedDuration = Duration.zero;
      });
      _startWatchTimer();
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _pulseController.dispose();
    _hideControlsTimer?.cancel();
    _watchTimer?.cancel();
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty.toUpperCase()) {
      case 'EASY': return AppColors.primaryColor;
      case 'MEDIUM': return AppColors.primaryGold;
      case 'HARD': return AppColors.ThemeRedColor;
      default: return AppColors.primaryColor;
    }
  }

  void _navigateToCodeEditor() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        settings: const RouteSettings(name: '/code'),
        pageBuilder: (context, animation, secondaryAnimation) => CodeEditorScreen(
          studentId: widget.studentId,
          difficulty: widget.difficulty,
          questionNumber: widget.questionNumber,
          institutionName: widget.institutionName,
          teacherName: widget.teacherName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: Curves.easeInOutCubic),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildTimerDisplay() {
    if (!_isVideoInitialized || _videoController == null) {
      return const SizedBox.shrink();
    }

    final videoDuration = _videoController!.value.duration;
    final progress = _hasCompletedOnce 
        ? 1.0 
        : (_totalWatchedDuration.inSeconds / videoDuration.inSeconds);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getDifficultyColor().withOpacity(0.1),
            _getDifficultyColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getDifficultyColor().withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const KText(
                text: 'Watch Progress',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                textColor: AppColors.titleColor,
              ),
              KText(
                text: _hasCompletedOnce 
                    ? 'Completed ✓' 
                    : '${_formatDuration(_totalWatchedDuration)} / ${_formatDuration(videoDuration)}',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                textColor: _hasCompletedOnce ? AppColors.ThemeGreenColor : _getDifficultyColor(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _hasCompletedOnce ? AppColors.ThemeGreenColor : _getDifficultyColor(),
            ),
            minHeight: 6,
          ),
          if (_hasCompletedOnce)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.ThemeGreenColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const KText(
                    text: 'Video Completed',
                    fontSize: 12,
                    textColor: AppColors.ThemeGreenColor,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (!_isVideoInitialized || _videoController == null) {
      return _buildLoadingWidget();
    }

    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(_videoController!),
                
                // Centered Rewatch Icon - Shows when video ends
                if (_showCenteredRewatch)
                  Center(
                    child: GestureDetector(
                      onTap: _restartVideo,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.replay,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                
                // Video controls overlay
                AnimatedOpacity(
                  opacity: _showControls && !_showCenteredRewatch ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Top controls
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: KText(
                                  text: '${_playbackSpeed}x',
                                  fontSize: 12,
                                  textColor: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: _toggleFullscreen,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Center play/pause button
                        Center(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Bottom controls
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Progress bar
                              VideoProgressIndicator(
                                _videoController!,
                                allowScrubbing: true,
                                colors: VideoProgressColors(
                                  playedColor: _getDifficultyColor(),
                                  bufferedColor: Colors.white.withOpacity(0.3),
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              
                              // Control buttons row
                              Row(
                                children: [
                                  // Skip backward
                                  GestureDetector(
                                    onTap: _skipBackward,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.replay_10,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Play/Pause button
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _videoController!.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Skip forward
                                  GestureDetector(
                                    onTap: _skipForward,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.forward_10,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Speed control
                                  GestureDetector(
                                    onTap: _changePlaybackSpeed,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: KText(
                                        text: '${_playbackSpeed}x',
                                        fontSize: 12,
                                        textColor: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  
                                  const Spacer(),
                                  
                                  // Time display
                                  ValueListenableBuilder(
                                    valueListenable: _videoController!,
                                    builder: (context, VideoPlayerValue value, child) {
                                      return KText(
                                        text: '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                        fontSize: 12,
                                        textColor: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      );
                                    },
                                  ),
                                ],
                              ),
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
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBgLightColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            const KText(
              text: 'Loading video...',
              fontSize: 14,
              textColor: AppColors.subTitleColor,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.ThemeRedColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.ThemeRedColor.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.ThemeRedColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: AppColors.ThemeRedColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: KText(
                text: _errorMessage,
                fontSize: 14,
                textColor: AppColors.ThemeRedColor,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _initializeVideo();
              },
              child: KText(
                text: 'Retry',
                fontSize: 14,
                textColor: AppColors.ThemeRedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _buildVideoPlayer(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isFullscreen) {
          _toggleFullscreen();
          return false;
        }
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBgLightColor,
        appBar: AppBar(
          title: KText(
            text: 'Level ${widget.questionNumber} Tutorial',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: _getDifficultyColor()),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                AppColors.scaffoldBgLightColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
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
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              KText(
                                text: 'Watch Tutorial Video',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                textColor: AppColors.titleColor,
                              ),
                              const SizedBox(height: 4),
                              KText(
                                text: _hasCompletedOnce 
                                    ? 'You can now proceed to the coding challenge'
                                    : 'Complete the video to proceed to the coding challenge',
                                fontSize: 12,
                                textColor: AppColors.subTitleColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Timer display
                  if (_isVideoInitialized) _buildTimerDisplay(),

                  // Video player section
                  Expanded(
                    child: _buildVideoPlayer(),
                  ),

                  const SizedBox(height: 24),

                  // Next button section - Always show if completed once
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _hasCompletedOnce ? 60 : 0,
                    child: _hasCompletedOnce
                        ? AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
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
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap: _navigateToCodeEditor,
                                      borderRadius: BorderRadius.circular(16),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 18),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.code,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            SizedBox(width: 12),
                                            KText(
                                              text: 'Start Coding Challenge',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              textColor: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Instruction text when video is not completed
                  if (!_hasCompletedOnce && !_isLoading && !_hasError)
                    Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            KText(
                              text: 'Watch the complete video to continue',
                              fontSize: 12,
                              textColor: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}