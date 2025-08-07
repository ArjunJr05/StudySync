// features/teacher/models/model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studysync/core/themes/app_colors.dart'; // Assuming AppColors is in this path

// A helper function to safely parse dates from Firestore
DateTime? _parseDate(dynamic date) {
  if (date is Timestamp) {
    return date.toDate();
  } else if (date is String) {
    return DateTime.tryParse(date);
  } else if (date is DateTime) {
    return date;
  }
  return null;
}

// Enhanced helper function to safely parse numbers
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int _parseInt(dynamic value, [int defaultValue = 0]) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value is bool) return value;
  if (value is String) {
    return value.toUpperCase() == 'true';
  }
  return defaultValue;
}

class TeacherDashboardData {
  final String teacherName;
  final String institutionName;
  final int totalStudents;
  final int activeToday;
  final double averageScore;
  final int pendingRequests;
  final List<String> recentActivities;
  final DateTime lastUpdated;
  final Map<String, dynamic> additionalMetrics;

  TeacherDashboardData({
    required this.teacherName,
    required this.institutionName,
    required this.totalStudents,
    required this.activeToday,
    required this.averageScore,
    required this.pendingRequests,
    required this.recentActivities,
    DateTime? lastUpdated,
    Map<String, dynamic>? additionalMetrics,
  })  : lastUpdated = lastUpdated ?? DateTime.now(),
        additionalMetrics = additionalMetrics ?? {};

  factory TeacherDashboardData.fromMap(Map<String, dynamic> map) {
    return TeacherDashboardData(
      teacherName: map['teacherName']?.toString() ?? 'Unknown Teacher',
      institutionName:
          map['institutionName']?.toString() ?? 'Unknown Institution',
      totalStudents: _parseInt(map['totalStudents']),
      activeToday: _parseInt(map['activeToday']),
      averageScore: _parseDouble(map['averageScore']),
      pendingRequests: _parseInt(map['pendingRequests']),
      recentActivities: (map['recentActivities'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      lastUpdated: _parseDate(map['lastUpdated']) ?? DateTime.now(),
      additionalMetrics:
          Map<String, dynamic>.from(map['additionalMetrics'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherName': teacherName,
      'institutionName': institutionName,
      'totalStudents': totalStudents,
      'activeToday': activeToday,
      'averageScore': averageScore,
      'pendingRequests': pendingRequests,
      'recentActivities': recentActivities,
      'lastUpdated': lastUpdated.toIso8601String(),
      'additionalMetrics': additionalMetrics,
    };
  }

  // Helper getters for enhanced functionality
  double get studentGrowthRate {
    return _parseDouble(additionalMetrics['studentGrowthRate']);
  }

  double get engagementRate {
    return totalStudents > 0 ? (activeToday / totalStudents * 100) : 0.0;
  }

  String get performanceGrade {
    if (averageScore >= 90) return 'Excellent';
    if (averageScore >= 80) return 'Very Good';
    if (averageScore >= 70) return 'Good';
    if (averageScore >= 60) return 'Average';
    return 'Needs Improvement';
  }
}

class StudentData {
  final String studentId;
  final String name;
  final String email;
  final int rank;
  final double overallScore;
  final int totalActivity;
  final double completionRate;
  final bool isActiveToday;
  final String lastActiveTime;
  final DateTime lastActiveDate;
  final Map<String, double> subjectScores;
  final List<String> recentActivities;
  final String profileImageUrl;
  final Map<String, dynamic> metadata;

  StudentData({
    required this.studentId,
    required this.name,
    required this.email,
    required this.rank,
    required this.overallScore,
    required this.totalActivity,
    required this.completionRate,
    required this.isActiveToday,
    required this.lastActiveTime,
    DateTime? lastActiveDate,
    Map<String, double>? subjectScores,
    List<String>? recentActivities,
    String? profileImageUrl,
    Map<String, dynamic>? metadata,
  })  : lastActiveDate = lastActiveDate ?? DateTime.now(),
        subjectScores = subjectScores ?? {},
        recentActivities = recentActivities ?? [],
        profileImageUrl = profileImageUrl ?? '',
        metadata = metadata ?? {};

  StudentData copyWith({
    String? studentId,
    String? name,
    String? email,
    int? rank,
    double? overallScore,
    int? totalActivity,
    double? completionRate,
    bool? isActiveToday,
    String? lastActiveTime,
    DateTime? lastActiveDate,
    Map<String, double>? subjectScores,
    List<String>? recentActivities,
    String? profileImageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return StudentData(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      email: email ?? this.email,
      rank: rank ?? this.rank,
      overallScore: overallScore ?? this.overallScore,
      totalActivity: totalActivity ?? this.totalActivity,
      completionRate: completionRate ?? this.completionRate,
      isActiveToday: isActiveToday ?? this.isActiveToday,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      subjectScores: subjectScores ?? Map.from(this.subjectScores),
      recentActivities: recentActivities ?? List.from(this.recentActivities),
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  factory StudentData.fromMap(Map<String, dynamic> map) {
    // Safely access the nested performance map
    final performance = map['performance'] as Map<String, dynamic>? ?? {};

    // Safely parse recent activities which is a List<Map<String, dynamic>>
    List<String> activities = [];
    if (map['recentActivities'] is List) {
      for (var item in (map['recentActivities'] as List)) {
        if (item is Map && item.containsKey('activity')) {
          activities.add(item['activity'].toString());
        } else if (item is String) {
          activities.add(item); // Handle cases where it might already be a string
        }
      }
    }


    return StudentData(
      studentId: map['studentId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Student',
      email: map['email']?.toString() ?? 'No Email',
      rank: _parseInt(map['rank']),
      overallScore: _parseDouble(map['overallScore']),
      totalActivity: _parseInt(map['totalActivity']),
      completionRate: _parseDouble(map['completionRate']),
      isActiveToday: _parseBool(map['isActiveToday']),
      lastActiveTime: map['lastActiveTime']?.toString() ?? 'Never',
      lastActiveDate: _parseDate(map['lastActiveDate']) ?? _parseDate(map['lastSignIn']) ?? DateTime.now(),
      subjectScores: (map['subjectScores'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, _parseDouble(value))) ??
          {},
      recentActivities: activities,
      profileImageUrl: map['profileImageUrl']?.toString() ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'email': email,
      'rank': rank,
      'overallScore': overallScore,
      'totalActivity': totalActivity,
      'completionRate': completionRate,
      'isActiveToday': isActiveToday,
      'lastActiveTime': lastActiveTime,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'subjectScores': subjectScores,
      'recentActivities': recentActivities,
      'profileImageUrl': profileImageUrl,
      'metadata': metadata,
    };
  }

  String get performanceLevel {
    if (overallScore >= 90) return 'Outstanding';
    if (overallScore >= 80) return 'Excellent';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 60) return 'Satisfactory';
    return 'Needs Improvement';
  }

  String get activityLevel {
    if (totalActivity >= 100) return 'Very High';
    if (totalActivity >= 50) return 'High';
    if (totalActivity >= 25) return 'Moderate';
    if (totalActivity >= 10) return 'Low';
    return 'Very Low';
  }

  Color get performanceColor {
    if (overallScore >= 90) return const Color(0xFF4CAF50); // Green
    if (overallScore >= 80) return const Color(0xFF8BC34A); // Light Green
    if (overallScore >= 70) return const Color(0xFFFF9800); // Orange
    if (overallScore >= 60) return const Color(0xFFFF5722); // Deep Orange
    return const Color(0xFFF44336); // Red
  }

  bool get isTopPerformer => rank <= 10;
  bool get needsAttention => overallScore < 60 || completionRate < 50;

  String get initials {
    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return '?';
  }

  Duration get timeSinceLastActive {
    return DateTime.now().difference(lastActiveDate);
  }
}

enum RequestStatus { pending, accepted, rejected, cancelled, expired }

extension RequestStatusExtension on RequestStatus {
  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending Review';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.cancelled:
        return 'Cancelled';
      case RequestStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case RequestStatus.pending:
        return AppColors.primaryColor;
      case RequestStatus.accepted:
        return AppColors.primaryColor;
      case RequestStatus.rejected:
        return AppColors.primaryColor;
      case RequestStatus.cancelled:
        return Colors.grey;
      case RequestStatus.expired:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case RequestStatus.pending:
        return Icons.pending_actions_outlined;
      case RequestStatus.accepted:
        return Icons.check_circle_outline;
      case RequestStatus.rejected:
        return Icons.cancel_outlined;
      case RequestStatus.cancelled:
        return Icons.block_outlined;
      case RequestStatus.expired:
        return Icons.access_time_outlined;
    }
  }
}

class StudentRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String institutionName;
  final String teacherName;
  final String teacherId;
  final RequestStatus status;
  final DateTime requestDate;
  final DateTime? processedDate;
  final DateTime? expiryDate;
  final String? message;
  final String? rejectionReason;
  final String? processedByTeacherId;
  final String? processedByTeacherName;
  final Map<String, dynamic>? additionalInfo;
  final int priority;
  final List<String> tags;
  final bool isStudentCreated;

  StudentRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.institutionName,
    required this.teacherName,
    required this.teacherId,
    required this.status,
    required this.requestDate,
    this.processedDate,
    this.expiryDate,
    this.message,
    this.rejectionReason,
    this.processedByTeacherId,
    this.processedByTeacherName,
    this.additionalInfo,
    this.priority = 1,
    List<String>? tags,
    this.isStudentCreated = false,
  }) : tags = tags ?? [];

  factory StudentRequest.fromMap(Map<String, dynamic> map) {
    return StudentRequest(
      id: map['id']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? 'Unknown Student',
      studentEmail: map['studentEmail']?.toString() ?? 'No Email',
      institutionName:
          map['institutionName']?.toString() ?? 'Unknown Institution',
      teacherName: map['teacherName']?.toString() ?? 'Unknown Teacher',
      teacherId: map['teacherId']?.toString() ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      requestDate: _parseDate(map['requestDate']) ?? DateTime.now(),
      processedDate: _parseDate(map['processedDate']),
      expiryDate: _parseDate(map['expiryDate']),
      message: map['message']?.toString(),
      rejectionReason: map['rejectionReason']?.toString(),
      processedByTeacherId: map['processedByTeacherId']?.toString(),
      processedByTeacherName: map['processedByTeacherName']?.toString(),
      additionalInfo: map['additionalInfo'] != null
          ? Map<String, dynamic>.from(map['additionalInfo'])
          : null,
      priority: _parseInt(map['priority'], 1),
      tags: (map['tags'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      isStudentCreated: _parseBool(map['isStudentCreated'], false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'institutionName': institutionName,
      'teacherName': teacherName,
      'teacherId': teacherId,
      'status': status.name,
      'requestDate': requestDate.toIso8601String(),
      'processedDate': processedDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'message': message,
      'rejectionReason': rejectionReason,
      'processedByTeacherId': processedByTeacherId,
      'processedByTeacherName': processedByTeacherName,
      'additionalInfo': additionalInfo,
      'priority': priority,
      'tags': tags,
      'isStudentCreated': isStudentCreated,
    };
  }

  StudentRequest copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? institutionName,
    String? teacherName,
    String? teacherId,
    RequestStatus? status,
    DateTime? requestDate,
    DateTime? processedDate,
    DateTime? expiryDate,
    String? message,
    String? rejectionReason,
    String? processedByTeacherId,
    String? processedByTeacherName,
    Map<String, dynamic>? additionalInfo,
    int? priority,
    List<String>? tags,
    bool? isStudentCreated,
  }) {
    return StudentRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      institutionName: institutionName ?? this.institutionName,
      teacherName: teacherName ?? this.teacherName,
      teacherId: teacherId ?? this.teacherId,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      processedDate: processedDate ?? this.processedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      message: message ?? this.message,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      processedByTeacherId: processedByTeacherId ?? this.processedByTeacherId,
      processedByTeacherName:
          processedByTeacherName ?? this.processedByTeacherName,
      additionalInfo: additionalInfo ??
          (this.additionalInfo != null
              ? Map.from(this.additionalInfo!)
              : null),
      priority: priority ?? this.priority,
      tags: tags ?? List.from(this.tags),
      isStudentCreated: isStudentCreated ?? this.isStudentCreated,
    );
  }

  // Helper getters for enhanced functionality
  bool get isPending => status == RequestStatus.pending;
  bool get isAccepted => status == RequestStatus.accepted;
  bool get isRejected => status == RequestStatus.rejected;
  bool get isCancelled => status == RequestStatus.cancelled;
  bool get isExpired => status == RequestStatus.expired;

  bool get isProcessed => processedDate != null;

  Duration get timeSinceRequest => DateTime.now().difference(requestDate);

  Duration? get processingTime {
    if (processedDate != null) {
      return processedDate!.difference(requestDate);
    }
    return null;
  }

  bool get isHighPriority => priority >= 3;
  bool get isUrgent => timeSinceRequest.inDays >= 7 && isPending;

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Normal';
      case 3:
        return 'High';
      case 4:
        return 'Critical';
      default:
        return 'Normal';
    }
  }

  String get timeAgo {
    final duration = timeSinceRequest;
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String get studentInitials {
    final nameParts = studentName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return '?';
  }

  String get statusDescription {
    switch (status) {
      case RequestStatus.pending:
        return 'Awaiting teacher approval';
      case RequestStatus.accepted:
        return isStudentCreated
            ? 'Student added to class successfully'
            : 'Request approved, student creation pending';
      case RequestStatus.rejected:
        return rejectionReason != null && rejectionReason!.isNotEmpty
            ? 'Rejected: $rejectionReason'
            : 'Request was declined';
      case RequestStatus.cancelled:
        return 'Request was cancelled';
      case RequestStatus.expired:
        return 'Request has expired';
    }
  }

  String get processedBy {
    if (processedByTeacherName != null && processedByTeacherName!.isNotEmpty) {
      return processedByTeacherName!;
    } else if (processedByTeacherId != null &&
        processedByTeacherId!.isNotEmpty) {
      return 'Teacher ID: $processedByTeacherId';
    }
    return 'Unknown';
  }
}