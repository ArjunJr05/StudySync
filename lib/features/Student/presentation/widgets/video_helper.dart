import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VideoUrlHelper {
  static const List<String> difficulties = ['EASY', 'MEDIUM', 'HARD'];
  static const int maxLevels = 10;

  /// Get video URL for specific difficulty and level
  static String? getVideoUrl({
    required String difficulty,
    required int level,
  }) {
    try {
      final String envKey = 'VIDEO_${difficulty.toUpperCase()}_$level';
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

  /// Extract Google Drive file ID from various URL formats
  static String? extractGoogleDriveFileId(String url) {
    // Pattern 1: https://drive.google.com/file/d/FILE_ID/view?usp=sharing
    RegExp pattern1 = RegExp(r'/file/d/([a-zA-Z0-9-_]+)');
    Match? match = pattern1.firstMatch(url);
    if (match != null) {
      return match.group(1);
    }

    // Pattern 2: https://drive.google.com/open?id=FILE_ID
    RegExp pattern2 = RegExp(r'[?&]id=([a-zA-Z0-9-_]+)');
    match = pattern2.firstMatch(url);
    if (match != null) {
      return match.group(1);
    }

    // Pattern 3: Just the file ID
    if (url.length > 10 && url.length < 100 && !url.contains('/')) {
      return url;
    }

    return null;
  }

  /// Convert Google Drive URL to streaming URL (works better for video playback)
  static String convertToStreamingUrl(String url) {
    final String? fileId = extractGoogleDriveFileId(url);
    
    if (fileId != null) {
      // Use the embed URL which works better for video streaming
      return 'https://drive.google.com/file/d/$fileId/preview';
    }
    
    return url;
  }

  /// Convert to direct download URL (fallback method)
  static String convertToDirectUrl(String url) {
    final String? fileId = extractGoogleDriveFileId(url);
    
    if (fileId != null) {
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    
    return url;
  }

  /// Get alternative URLs for better compatibility
  static List<String> getAlternativeUrls(String originalUrl) {
    final String? fileId = extractGoogleDriveFileId(originalUrl);
    
    if (fileId == null) {
      return [originalUrl];
    }

    return [
      // Method 1: Streaming URL (best for video playback)
      'https://drive.google.com/file/d/$fileId/preview',
      
      // Method 2: Direct download URL
      'https://drive.google.com/uc?export=download&id=$fileId',
      
      // Method 3: Alternative streaming URL
      'https://drive.google.com/uc?id=$fileId',
      
      // Method 4: Original URL
      originalUrl,
    ];
  }

  /// Validate if all required videos are configured
  static Map<String, List<int>> validateVideoConfiguration() {
    final Map<String, List<int>> missingVideos = {};
    
    for (String difficulty in difficulties) {
      final List<int> missingLevels = [];
      
      for (int level = 1; level <= maxLevels; level++) {
        final String? videoUrl = getVideoUrl(
          difficulty: difficulty,
          level: level,
        );
        
        if (videoUrl == null) {
          missingLevels.add(level);
        }
      }
      
      if (missingLevels.isNotEmpty) {
        missingVideos[difficulty] = missingLevels;
      }
    }
    
    return missingVideos;
  }

  /// Get all configured video URLs for debugging
  static Map<String, Map<int, String?>> getAllVideoUrls() {
    final Map<String, Map<int, String?>> allUrls = {};
    
    for (String difficulty in difficulties) {
      final Map<int, String?> difficultyUrls = {};
      
      for (int level = 1; level <= maxLevels; level++) {
        difficultyUrls[level] = getVideoUrl(
          difficulty: difficulty,
          level: level,
        );
      }
      
      allUrls[difficulty] = difficultyUrls;
    }
    
    return allUrls;
  }

  /// Print configuration status for debugging
  static void printConfigurationStatus() {
    debugPrint('=== Video Configuration Status ===');
    
    final Map<String, List<int>> missing = validateVideoConfiguration();
    
    if (missing.isEmpty) {
      debugPrint('✅ All video URLs are configured!');
    } else {
      debugPrint('❌ Missing video URLs:');
      missing.forEach((difficulty, levels) {
        debugPrint('  $difficulty: Levels ${levels.join(', ')}');
      });
    }
    
    // Test file ID extraction
    debugPrint('\n=== Testing URL Conversion ===');
    for (String difficulty in difficulties) {
      final String? url = getVideoUrl(difficulty: difficulty, level: 1);
      if (url != null) {
        final String? fileId = extractGoogleDriveFileId(url);
        debugPrint('$difficulty Level 1:');
        debugPrint('  Original: $url');
        debugPrint('  File ID: $fileId');
        debugPrint('  Streaming: ${convertToStreamingUrl(url)}');
        break;
      }
    }
    
    debugPrint('=== End Configuration Status ===');
  }

  /// Get video title/description for UI
  static String getVideoTitle(String difficulty, int level) {
    return '${difficulty.substring(0, 1).toUpperCase()}${difficulty.substring(1).toLowerCase()} Level $level Tutorial';
  }

  /// Get video description for UI
  static String getVideoDescription(String difficulty, int level) {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return 'Learn the basics in this beginner-friendly tutorial';
      case 'MEDIUM':
        return 'Intermediate concepts and practical applications';
      case 'HARD':
        return 'Advanced techniques and challenging problems';
      default:
        return 'Tutorial video for Level $level';
    }
  }

  /// Check if URL is a Google Drive URL
  static bool isGoogleDriveUrl(String url) {
    return url.contains('drive.google.com');
  }

  /// Get recommended headers for video requests
  static Map<String, String> getVideoHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
      'Accept': 'video/mp4,video/webm,video/*,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'identity',
      'Range': 'bytes=0-',
    };
  }
}