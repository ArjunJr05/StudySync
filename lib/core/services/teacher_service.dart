import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studysync/features/teacher/presentation/widgets/model.dart';
import 'package:flutter/material.dart';

class TeacherService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches all the necessary data for the teacher's dashboard.
  static Future<TeacherDashboardData> getDashboardData(
    String teacherId,
    String institutionName,
  ) async {
    try {
      final teacherDoc = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .get();

      if (!teacherDoc.exists) {
        throw Exception('Teacher not found');
      }

      final teacherData = teacherDoc.data()!;

      final studentsQuery = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .get();

      final students = studentsQuery.docs;
      final totalStudents = students.length;

      int activeToday = 0;
      double totalScore = 0;

      for (var studentDoc in students) {
        final studentData = studentDoc.data();
        // Use the consistent DateUtils.isSameDay method for checking activity
        if (studentData['lastSignIn'] != null &&
            DateUtils.isSameDay(
              (studentData['lastSignIn'] as Timestamp).toDate(),
              DateTime.now(),
            )) {
          activeToday++;
        }
        // MODIFIED: Get score from the performance sub-map
        final performance = studentData['performance'] as Map<String, dynamic>? ?? {};
        totalScore += (performance['averageScore'] ?? 0.0).toDouble();
      }

      final averageScore = totalStudents > 0 ? totalScore / totalStudents : 0.0;

      final requestsQuery = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .get();

      final pendingRequests = requestsQuery.docs.length;
      final recentActivities = await _getRecentActivities(
        teacherId,
        institutionName,
      );

      return TeacherDashboardData(
        teacherName: teacherData['name'] ?? 'Teacher',
        institutionName: institutionName,
        totalStudents: totalStudents,
        activeToday: activeToday,
        averageScore: averageScore,
        pendingRequests: pendingRequests,
        recentActivities: recentActivities,
      );
    } catch (e) {
      debugPrint('Error getting dashboard data: $e');
      throw Exception('Failed to load dashboard data. Please try again.');
    }
  }

  static Future<List<StudentData>> getStudentRankings(
  String teacherId,
  String institutionName,
) async {
  try {
    final studentsQuery = await _firestore
        .collection('institutions')
        .doc(institutionName)
        .collection('teachers')
        .doc(teacherId)
        .collection('students')
        .where('status', isEqualTo: 'accepted')
        .get();

    List<StudentData> students = studentsQuery.docs.map((doc) {
      final data = doc.data();
      final performance = data['performance'] as Map<String, dynamic>? ?? {};

      data['studentId'] = doc.id;
      data['overallScore'] = (performance['averageScore'] ?? 0.0).toDouble();
      data['totalActivity'] = performance['testsCompleted'] ?? 0;
      
      // Add className data
      data['className'] = data['className'] ?? 'Class A';
        
        // Example logic for completion rate. Assumes 150 total possible activities.
        // This should be adjusted based on your actual course structure.
        final totalPossibleActivities = 150.0;
        double completionRate = ((performance['testsCompleted'] ?? 0) / totalPossibleActivities * 100.0);
        data['completionRate'] = completionRate.clamp(0.0, 100.0); // Ensure it's between 0 and 100

        // Keep existing helper logic
        data['isActiveToday'] = _checkIfActiveToday(data);
        data['lastActiveTime'] = _formatLastActiveTime(data);
        data['subjectScores'] = _getSubjectScores(data);
        
        // The fromMap factory will now correctly parse the activities
        return StudentData.fromMap(data);
      }).toList();

      // Sort students by score in descending order
      students.sort((a, b) => b.overallScore.compareTo(a.overallScore));

      // Assign ranks to each student
      List<StudentData> rankedStudents = [];
      for (int i = 0; i < students.length; i++) {
        rankedStudents.add(students[i].copyWith(rank: i + 1));
      }

      return rankedStudents;
    } catch (e) {
      debugPrint('Error getting student rankings: $e');
      throw Exception('Failed to load student rankings.');
    }
  }


  /// Fetches all student requests (pending, accepted, rejected).
  static Future<List<StudentRequest>> getAllRequests(
    String teacherId,
    String institutionName,
  ) async {
    try {
      final requestsQuery = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('requests')
          .orderBy('requestDate', descending: true)
          .get();

      return requestsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return StudentRequest.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting requests: $e');
      throw Exception('Failed to load requests.');
    }
  }

  /// Updates a request's status and processes it if accepted.
  static Future<bool> updateRequestStatus(
    String teacherId,
    String institutionName,
    String requestId, // This is the student's ID
    RequestStatus newStatus,
  ) async {
    try {
      final requestRef = _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('requests')
          .doc(requestId);

      final requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
        throw Exception("Request not found.");
      }

      final requestData = requestDoc.data()!;

      if (newStatus == RequestStatus.accepted) {
        final success = await _processAcceptedRequest(
          teacherId,
          institutionName,
          requestId,
          requestData,
        );

        if (success) {
          await requestRef.update({
            'status': newStatus.name,
            'processedDate': Timestamp.now(),
            'isStudentCreated':
                true, // Mark that the student record was created
          });
          debugPrint('Request accepted and status updated.');
        }

        return success;
      } else if (newStatus == RequestStatus.rejected) {
        // When rejecting, also update the main student document to 'rejected'
        final studentDocRef = _firestore
            .collection('institutions')
            .doc(institutionName)
            .collection('teachers')
            .doc(teacherId)
            .collection('students')
            .doc(requestId);

        await studentDocRef.update({'status': 'rejected'});

        await requestRef.update({
          'status': newStatus.name,
          'processedDate': Timestamp.now(),
        });
        debugPrint('Request rejected and status updated.');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating request status: $e');
      return false;
    }
  }

  /// Creates a student record from an accepted request.
  static Future<bool> _processAcceptedRequest(
    String teacherId,
    String institutionName,
    String studentId,
    Map<String, dynamic> requestData,
  ) async {
    try {
      final teacherDoc = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .get();

      if (!teacherDoc.exists) {
        debugPrint('Teacher document not found');
        return false;
      }

      final teacherName = teacherDoc.data()!['name'] ?? 'Unknown Teacher';

      final studentDocRef = _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .doc(studentId);

      // --- This part is now handled by FirestoreService.saveStudentData ---
      // For consistency, we are just updating the status here as student doc is pre-created
       await studentDocRef.update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        // Add an activity log for the approval
        'recentActivities': FieldValue.arrayUnion([
          {
            'activity': 'Approved by teacher and joined the class',
            'timestamp': Timestamp.now(), // ❗️ CORRECTED
            'icon': 'approval',
          }
        ])
      });


      await _updateTeacherAfterStudentAcceptance(
        teacherId,
        institutionName,
        requestData['studentEmail'] ?? '',
      );

      await _updateInstitutionMetadata(institutionName);

      debugPrint('Successfully updated student record for ID: $studentId to accepted.');
      return true;
    } catch (e) {
      debugPrint('Error processing accepted request: $e');
      return false;
    }
  }

  /// Updates teacher data after accepting a student
  static Future<void> _updateTeacherAfterStudentAcceptance(
    String teacherId,
    String institutionName,
    String studentEmail,
  ) async {
    try {
      final teacherDocRef = _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId);

      await _updateTeacherStudentCount(institutionName, teacherId);

      if (studentEmail.isNotEmpty) {
        final sanitizedEmailKey = studentEmail.replaceAll('.', ',');
        await teacherDocRef.update({
          'studentLoginRecords.$sanitizedEmailKey': {
            'email': studentEmail.toLowerCase(),
            'loginTimestamp': FieldValue.serverTimestamp(),
          },
        });
      }
    } catch (e) {
      debugPrint('Error updating teacher after student acceptance: $e');
    }
  }

  /// Updates teacher's student count
  static Future<void> _updateTeacherStudentCount(
    String institutionName,
    String teacherId,
  ) async {
    try {
      final studentsQuery = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .where('status', isEqualTo: 'accepted') // Only count accepted students
          .get();

      final studentCount = studentsQuery.docs.length;

      await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .update({'studentCount': studentCount});

      debugPrint('Updated teacher student count: $studentCount');
    } catch (e) {
      debugPrint('Error updating teacher student count: $e');
    }
  }

  /// Updates institution metadata
  static Future<void> _updateInstitutionMetadata(String institutionName) async {
    try {
      final institutionDocRef = _firestore
          .collection('institutions')
          .doc(institutionName);

      final teachersSnapshot = await institutionDocRef
          .collection('teachers')
          .get();
      final teacherCount = teachersSnapshot.docs.length;

      final teacherNames = teachersSnapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? 'Unknown Teacher')
          .toList();

      int totalStudentCount = 0;
      for (var teacherDoc in teachersSnapshot.docs) {
        final studentsSnapshot = await teacherDoc.reference
            .collection('students')
            .where('status', isEqualTo: 'accepted') // Only count accepted students
            .get();
        totalStudentCount += studentsSnapshot.docs.length;
      }

      await institutionDocRef.set({
        'institutionName': institutionName,
        'teacherCount': teacherCount,
        'studentCount': totalStudentCount,
        'teacherNames': teacherNames,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        'Updated institution metadata - Teachers: $teacherCount, Students: $totalStudentCount',
      );
    } catch (e) {
      debugPrint('Error updating institution metadata: $e');
    }
  }

  // --- PRIVATE HELPER & PLACEHOLDER METHODS ---

    /// Fetches the most recent activities from all students under this teacher.
  static Future<List<String>> _getRecentActivities(
    String teacherId,
    String institutionName,
  ) async {
    try {
      // 1. Get all accepted students for the teacher
      final studentsSnapshot = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .where('status', isEqualTo: 'accepted')
          .get();

      // 2. Create a list to hold all valid activities
      final List<Map<String, dynamic>> allActivities = [];

      // 3. Loop through each student document
      for (final studentDoc in studentsSnapshot.docs) {
        // Safely get the student's data and name
        final studentData = studentDoc.data();
        final studentName = studentData['name'] as String? ?? 'A student';

        // SAFETY CHECK: Ensure the 'recentActivities' field exists and is a List
        if (studentData['recentActivities'] is List) {
          // Cast the activities to a generic List to avoid type errors
          final activitiesList = studentData['recentActivities'] as List;

          // Loop through each activity in the student's list
          for (final activity in activitiesList) {
            // SAFETY CHECK: Ensure the activity is a Map and has a timestamp
            if (activity is Map && activity['timestamp'] is Timestamp) {
              allActivities.add({
                'studentName': studentName,
                'text': activity['activity'] as String? ?? 'completed a task.',
                'timestamp': activity['timestamp'] as Timestamp,
              });
            }
          }
        }
      }

      // 4. Sort all collected activities by timestamp (most recent first)
      allActivities.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      // 5. Take the 5 most recent activities and format them for display
      return allActivities
          .take(5) // You can change this number to show more or fewer activities
          .map((activity) => "${activity['studentName']}: ${activity['text']}")
          .toList();

    } catch (e) {
      debugPrint('Error fetching recent student activities: $e');
      // Return a user-friendly error message if something goes wrong
      return ['Could not load recent activities.'];
    }
  }


  // This function is no longer the primary source for score, but can be a fallback.
  static double _calculateOverallScore(Map<String, dynamic> data) {
    final subjectScoresMap = data['subjectScores'];
    if (subjectScoresMap == null || subjectScoresMap.isEmpty) {
      return (data['overallScore'] ?? 0.0).toDouble();
    }
    final scores = Map<String, dynamic>.from(
      subjectScoresMap,
    ).values.map((score) => (score ?? 0.0).toDouble()).toList();

    if (scores.isEmpty) return 0.0;

    final average = scores.reduce((a, b) => a + b) / scores.length;
    return double.parse(
      average.toStringAsFixed(1),
    ); // Return score with 1 decimal place
  }

  static bool _checkIfActiveToday(Map<String, dynamic> data) {
    if (data['lastSignIn'] == null) return false;
    final lastSignIn = (data['lastSignIn'] as Timestamp).toDate();
    return DateUtils.isSameDay(lastSignIn, DateTime.now());
  }

  static String _formatLastActiveTime(Map<String, dynamic> data) {
    if (data['lastSignIn'] == null) return 'Never';
    final lastSignIn = (data['lastSignIn'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSignIn);

    if (difference.inDays > 1) return '${difference.inDays} days ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  static Map<String, double> _getSubjectScores(Map<String, dynamic> data) {
    if (data['subjectScores'] != null && data['subjectScores'] is Map) {
      return Map<String, dynamic>.from(
        data['subjectScores'],
      ).map((key, value) => MapEntry(key, (value ?? 0.0).toDouble()));
    }
    return {};
  }
}

class DateUtils {
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}