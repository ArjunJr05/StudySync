import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:studysync/core/services/auth_service.dart'; // Import for debugPrint

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ... (saveTeacherData and other teacher methods remain the same)
  /// Saves teacher data to Firestore
  static Future<bool> saveTeacherData({
    required String institutionName,
    required String teacherEmail,
    required String teacherName,
    required String teacherId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (institutionName.trim().isEmpty ||
          teacherEmail.trim().isEmpty ||
          teacherId.trim().isEmpty) {
        debugPrint('Invalid input data for saveTeacherData');
        return false;
      }

      final teacherDocRef = _firestore
          .collection('institutions')
          .doc(institutionName.trim())
          .collection('teachers')
          .doc(teacherId);

      final teacherData = {
        'email': teacherEmail.trim().toLowerCase(),
        'name': teacherName.trim(),
        'teacherId': teacherId,
        'institutionName': institutionName.trim(),
        'role': 'teacher',
        'joinedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'lastSignIn': FieldValue.serverTimestamp(),
        'studentCount': 0,
        'searchName': teacherName.trim().toLowerCase(),
        ...?additionalData,
      };

      await teacherDocRef.set(teacherData, SetOptions(merge: true));
      await _updateInstitutionMetadata(institutionName.trim());

      debugPrint('Teacher data saved successfully');
      return true;
    } catch (e) {
      debugPrint('Error saving teacher data: $e');
      return false;
    }
  }

  

  /// MODIFIED: This now just updates the status of the existing student document
  /// and deletes the corresponding request.
  static Future<bool> acceptStudentRequest(
    String studentId,
    String teacherId,
    String institutionName,
  ) async {
    try {
      final batch = _firestore.batch();

      // 1. Update the student's status in their main document
      final studentRef = _firestore
          .collection('institutions')
          .doc(institutionName.trim())
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .doc(studentId);

      batch.update(studentRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'recentActivities': FieldValue.arrayUnion([
          {
            'activity': 'Approved by teacher',
            'timestamp': Timestamp.now(), // ❗️ CORRECTED
            'icon': 'approval',
          }
        ])
      });

      // 2. Delete the request document from the 'requests' collection
      final requestRef = _firestore
          .collection('institutions')
          .doc(institutionName.trim())
          .collection('teachers')
          .doc(teacherId)
          .collection('requests')
          .doc(studentId);

      batch.delete(requestRef);

      await batch.commit();

      // Update counts after successful batch commit
      await _updateTeacherStudentCount(institutionName.trim(), teacherId);
      await _updateInstitutionMetadata(institutionName.trim());

      debugPrint('✅ Student request accepted and status updated.');
      return true;
    } catch (e) {
      debugPrint('❌ Error accepting student request: $e');
      return false;
    }
  }

  /// FIXED: Remove FieldValue.serverTimestamp() from arrays
static Future<bool> saveStudentData({
  required String institutionName,
  required String teacherName,
  required String studentEmail,
  required String studentName,
  required String studentId,
  Map<String, dynamic>? additionalData,
}) async {
  try {
    debugPrint('Creating initial student profile...');
    debugPrint('Institution: ${institutionName.trim()}');
    debugPrint('Teacher: ${teacherName.trim()}');
    debugPrint('Student Email: ${studentEmail.trim()}');
    debugPrint('Student ID: $studentId');

    // Validate input parameters
    if (institutionName.trim().isEmpty ||
        teacherName.trim().isEmpty ||
        studentEmail.trim().isEmpty ||
        studentId.trim().isEmpty) {
      debugPrint('❌ Invalid input data for saveStudentData');
      return false;
    }

    // Find teacher
    final teacherData = await findTeacherByName(
      institutionName.trim(),
      teacherName.trim(),
    );

    if (teacherData == null) {
      debugPrint('❌ Teacher not found: $teacherName in institution: $institutionName');
      return false;
    }

    final teacherId = teacherData['teacherId'];
    if (teacherId == null || teacherId.toString().trim().isEmpty) {
      debugPrint('❌ Teacher data is missing teacherId field');
      return false;
    }

    debugPrint('✅ Teacher found: $teacherId');

    // Create student document reference
    final studentDocRef = _firestore
        .collection('institutions')
        .doc(institutionName.trim())
        .collection('teachers')
        .doc(teacherId)
        .collection('students')
        .doc(studentId);

    // FIXED: Use DateTime.now() instead of FieldValue.serverTimestamp() inside arrays
    final now = DateTime.now();
    final studentData = {
      'email': studentEmail.trim().toLowerCase(),
      'name': studentName.trim().isNotEmpty ? studentName.trim() : 'New Student',
      'studentId': studentId,
      'teacherName': teacherName.trim(),
      'teacherId': teacherId,
      'institutionName': institutionName.trim(),
      'role': 'student',
      'joinedAt': FieldValue.serverTimestamp(), // OK: Not in array
      'lastSignIn': FieldValue.serverTimestamp(), // OK: Not in array
      'searchName': (studentName.trim().isNotEmpty ? studentName.trim() : 'New Student').toLowerCase(),
      'status': 'pending',
      'photoURL': additionalData?['photoURL'],
      'uid': additionalData?['uid'],
      'provider': additionalData?['provider'] ?? 'google',

      // Performance stats
      'performance': {
        'averageScore': 0.0,
        'streaks': 0,
        'timeSpentSeconds': 0,
        'testsCompleted': 0,
      },
      
      // FIXED: Use DateTime.now() instead of FieldValue.serverTimestamp() inside array
      'recentActivities': [
        {
          'activity': 'Joined the class',
          'timestamp': now, // ❗️ CORRECTED
          'icon': 'join',
        }
      ],
    };

    // Add any additional data if provided
    if (additionalData != null) {
      studentData.addAll(additionalData);
    }

    debugPrint('📝 Attempting to save student document...');
    await studentDocRef.set(studentData, SetOptions(merge: true));

    debugPrint('✅ Student profile created successfully under teacher: $teacherName with status: pending');
    return true;
  } catch (e, stackTrace) {
    debugPrint('❌ Error saving student data: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    return false;
  }
}

/// ALSO FIX: Update addRecentActivity method to use DateTime.now()
static Future<void> addRecentActivity({
  required String studentId,
  required String institutionName,
  required String teacherId,
  required String activity,
  required String icon,
}) async {
  try {
    final studentRef = _firestore
        .collection('institutions')
        .doc(institutionName)
        .collection('teachers')
        .doc(teacherId)
        .collection('students')
        .doc(studentId);

    // FIXED: Use DateTime.now() instead of FieldValue.serverTimestamp()
    final newActivity = {
      'activity': activity,
      'timestamp': DateTime.now(), // ❗️ CORRECTED
      'icon': icon,
    };

    // Get current activities to manage the array size
    final studentDoc = await studentRef.get();
    if (studentDoc.exists) {
      final data = studentDoc.data()!;
      List<dynamic> activities = List.from(data['recentActivities'] ?? []);
      
      // Add new activity at the beginning
      activities.insert(0, newActivity);
      
      // Keep only the last 5 activities
      if (activities.length > 5) {
        activities = activities.sublist(0, 5);
      }
      
      // Update the document with the new activities array
      await studentRef.update({'recentActivities': activities});
    } else {
      // Document doesn't exist, create it with the new activity
      await studentRef.update({
        'recentActivities': [newActivity]
      });
    }
  } catch (e) {
    debugPrint('Error adding recent activity: $e');
  }
}

  /// NEW: Transactionally updates student performance stats after a test.
  static Future<void> updateStudentPerformance({
    required String studentId,
    required String institutionName,
    required String teacherId,
    required bool wasCorrect,
    required int timeTakenSeconds,
  }) async {
    final studentRef = _firestore
        .collection('institutions')
        .doc(institutionName)
        .collection('teachers')
        .doc(teacherId)
        .collection('students')
        .doc(studentId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(studentRef);
      if (!snapshot.exists) {
        throw Exception("Student document does not exist!");
      }

      final data = snapshot.data()!;
      final performance = Map<String, dynamic>.from(data['performance'] ?? {});

      // Update stats
      final int testsCompleted = (performance['testsCompleted'] ?? 0) + 1;
      final int timeSpent =
          (performance['timeSpentSeconds'] ?? 0) + timeTakenSeconds;
      final double currentTotalScore =
          (performance['averageScore'] ?? 0.0) * (testsCompleted - 1);
      final double newScore = wasCorrect ? 100.0 : 0.0;
      final double newAverage = (currentTotalScore + newScore) / testsCompleted;
      final int streaks = performance['streaks'] ?? 0; // Placeholder for now

      transaction.update(studentRef, {
        'performance.testsCompleted': testsCompleted,
        'performance.timeSpentSeconds': timeSpent,
        'performance.averageScore': newAverage,
        'performance.streaks': streaks,
      });
    });
  }
  
  /// NEW: Creates a real-time stream for a single student document.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamStudentDocument(
      String studentId) async* {
    final authService = AuthService();
    final details = await authService.getUserDetails();
    if (details['institutionName'] != null && details['teacherName'] != null) {
      final teacher = await findTeacherByName(
          details['institutionName']!, details['teacherName']!);
      if (teacher != null) {
        yield* _firestore
            .collection('institutions')
            .doc(details['institutionName'])
            .collection('teachers')
            .doc(teacher['teacherId'])
            .collection('students')
            .doc(studentId)
            .snapshots();
      }
    }
  }


  // ... Other methods like getStudentData, findTeacherByName, etc., remain unchanged ...
  static Future<Map<String, dynamic>?> getTeacherDataById(
    String teacherId,
    String institutionName,
  ) async {
    try {
      final doc = await _firestore
          .collection('institutions')
          .doc(institutionName.trim())
          .collection('teachers')
          .doc(teacherId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting teacher data by ID: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentsByTeacherName(
    String institutionName,
    String teacherName,
  ) async {
    try {
      final teacherData = await findTeacherByName(institutionName, teacherName);

      if (teacherData == null) {
        debugPrint(
          'Could not find teacher "$teacherName" in "$institutionName".',
        );
        return [];
      }

      final teacherId = teacherData['teacherId'];
      if (teacherId == null) {
        debugPrint('Teacher document is missing a teacherId.');
        return [];
      }
      return await getTeacherStudents(institutionName, teacherId);
    } catch (e) {
      debugPrint('Error getting students by teacher name: $e');
      return [];
    }
  }

  static Future<bool> sendStudentRequest({
    required String institutionName,
    required String teacherName,
    required String studentEmail,
    required String studentName,
    required String studentId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final teacherData = await findTeacherByName(institutionName, teacherName);
      if (teacherData == null) {
        debugPrint('Teacher not found, cannot send request.');
        return false;
      }
      final teacherId = teacherData['teacherId'];

      final requestDocRef = _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('requests')
          .doc(studentId);

      final requestData = {
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'institutionName': institutionName,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        ...additionalData ?? {},
      };

      await requestDocRef.set(requestData);
      debugPrint('Student request sent successfully.');
      return true;
    } catch (e) {
      debugPrint('Error sending student request: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getTeacherData(
    String teacherEmail,
    String institutionName,
  ) async {
    try {
      final teachersQuery = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .where('email', isEqualTo: teacherEmail.toLowerCase())
          .limit(1)
          .get();

      if (teachersQuery.docs.isNotEmpty) {
        final teacherData = teachersQuery.docs.first.data();
        if (teacherData['teacherId'] == null) {
          debugPrint(
            "Warning: 'teacherId' field is missing in the document for email: $teacherEmail",
          );
        }
        return teacherData;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting teacher data: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> findTeacherByName(
    String institutionName,
    String teacherName,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .where('searchName', isEqualTo: teacherName.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error finding teacher by name: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStudentData(
    String studentEmail,
    String teacherName,
    String institutionName,
  ) async {
    try {
      final teacherData = await findTeacherByName(institutionName, teacherName);
      if (teacherData == null) return null;

      final teacherId = teacherData['teacherId'];
      final studentsQuery = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .where('email', isEqualTo: studentEmail.toLowerCase())
          .limit(1)
          .get();

      if (studentsQuery.docs.isNotEmpty) {
        final data = studentsQuery.docs.first.data();
        data['documentId'] = studentsQuery.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting student data: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStudentDataById(
    String studentId,
    String teacherName,
    String institutionName,
  ) async {
    try {
      final teacherData = await findTeacherByName(institutionName, teacherName);
      if (teacherData == null) return null;

      final teacherId = teacherData['teacherId'];
      final doc = await _firestore
          .collection('institutions')
          .doc(institutionName.trim())
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .doc(studentId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['documentId'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting student data by ID: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStudentRequest(
    String studentId,
    String teacherId,
    String institutionName,
  ) async {
    try {
      final requestDoc = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('requests')
          .doc(studentId)
          .get();

      if (requestDoc.exists) {
        final data = requestDoc.data()!;
        debugPrint(
          'Found existing request for student $studentId with status: ${data['status']}',
        );
        return data;
      }

      debugPrint('No request found for student: $studentId');
      return null;
    } catch (e) {
      debugPrint('Error getting student request: $e');
      return null;
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamStudentRequest(
    String studentId,
    String teacherId,
    String institutionName,
  ) {
    return _firestore
        .collection('institutions')
        .doc(institutionName.trim())
        .collection('teachers')
        .doc(teacherId)
        .collection('requests')
        .doc(studentId)
        .snapshots();
  }

  static Future<bool> updateStudentRequestStatus(
    String studentId,
    String teacherId,
    String institutionName,
    String status,
  ) async {
    try {
      final docRef = _firestore
          .collection('institutions')
          .doc(institutionName.trim())
          .collection('teachers')
          .doc(teacherId)
          .collection('requests')
          .doc(studentId);

      await docRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Updated student request status to: $status');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating student request status: $e');
      return false;
    }
  }

  static Future<bool> rejectStudentRequest(
    String studentId,
    String teacherId,
    String institutionName, {
    String? rejectionReason,
  }) async {
    try {
      final docRef = _firestore
          .collection('institutions')
          .doc(institutionName.trim())
          .collection('teachers')
          .doc(teacherId)
          .collection('requests')
          .doc(studentId);

      final updateData = {
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectedAt': FieldValue.serverTimestamp(),
      };

      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await docRef.update(updateData);

      debugPrint('✅ Student request rejected');
      return true;
    } catch (e) {
      debugPrint('❌ Error rejecting student request: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingStudentRequests(
    String teacherId,
    String institutionName,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('institutions')
          .doc(institutionName.trim())
          .collection('teachers')
          .doc(teacherId)
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting pending student requests: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllStudentRequests(
    String teacherId,
    String institutionName, {
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('institutions')
          .doc(institutionName.trim())
          .collection('teachers')
          .doc(teacherId)
          .collection('requests');

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot =
          await query.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)})
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting student requests: $e');
      return [];
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamPendingRequests(
    String teacherId,
    String institutionName,
  ) {
    return _firestore
        .collection('institutions')
        .doc(institutionName.trim())
        .collection('teachers')
        .doc(teacherId)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<bool> updateLastSignIn(
    String userEmail,
    String institutionName,
    String userRole, {
    String? teacherName,
  }) async {
    try {
      if (userRole.toLowerCase() == 'teacher') {
        final teachersQuery = await _firestore
            .collection('institutions')
            .doc(institutionName)
            .collection('teachers')
            .where('email', isEqualTo: userEmail.toLowerCase())
            .limit(1)
            .get();

        if (teachersQuery.docs.isNotEmpty) {
          await teachersQuery.docs.first.reference.update({
            'lastSignIn': FieldValue.serverTimestamp(),
          });
          return true;
        }
      } else if (userRole.toLowerCase() == 'student' && teacherName != null) {
        final studentData = await getStudentData(
          userEmail,
          teacherName,
          institutionName,
        );
        if (studentData != null) {
          final teacherId = studentData['teacherId'];
          final studentId = studentData['studentId'];
          await _firestore
              .collection('institutions')
              .doc(institutionName)
              .collection('teachers')
              .doc(teacherId)
              .collection('students')
              .doc(studentId)
              .update({'lastSignIn': FieldValue.serverTimestamp()});
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error updating last sign in: $e');
      return false;
    }
  }

  static String generateTeacherId(String email) {
    final sanitizedEmail =
        email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'teacher_${sanitizedEmail}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String generateStudentId(String email) {
    final sanitizedEmail =
        email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'student_${sanitizedEmail}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<bool> institutionHasTeachers(String institutionName) async {
    try {
      final teachersQuery = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .limit(1)
          .get();

      return teachersQuery.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if institution has teachers: $e');
      return false;
    }
  }

  static Future<List<String>> getAllInstitutionNames() async {
    try {
      final snapshot = await _firestore.collection('institutions').get();
      if (snapshot.docs.isEmpty) return [];
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting all institution names: $e');
      return [];
    }
  }

  

  static Future<void> _updateInstitutionMetadata(String institutionName) async {
    try {
      final institutionDocRef =
          _firestore.collection('institutions').doc(institutionName);

      final teachersSnapshot =
          await institutionDocRef.collection('teachers').get();

      final teacherCount = teachersSnapshot.docs.length;

      final teacherNames = teachersSnapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? 'Unknown Teacher')
          .toList();

      int totalStudentCount = 0;
      for (var teacherDoc in teachersSnapshot.docs) {
        final studentsSnapshot = await teacherDoc.reference
            .collection('students')
            .where('status', isEqualTo: 'accepted')
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

  static Future<List<String>> getTeacherNamesForInstitution(
    String institutionName,
  ) async {
    try {
      final institutionDoc = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .get();

      if (institutionDoc.exists &&
          institutionDoc.data()!.containsKey('teacherNames')) {
        return List<String>.from(institutionDoc.data()!['teacherNames']);
      }
      return [];
    } catch (e) {
      debugPrint('Error getting teacher names for institution: $e');
      return [];
    }
  }

  // This method remains, as it's used by the teacher's side.
  static Future<List<Map<String, dynamic>>> getTeacherStudents(
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
          .where('status', isEqualTo: 'accepted') // Only fetch accepted students
          .orderBy('name')
          .get();

      return studentsQuery.docs.map((doc) {
        final data = doc.data();
        data['documentId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting teacher students: $e');
      return [];
    }
  }

  /// ✨ NEW: Fetches ALL students (pending and accepted) for the Student Ranking Page.
  static Future<List<Map<String, dynamic>>> getAllStudentsByTeacherName(
    String institutionName,
    String teacherName,
  ) async {
    try {
      final teacherData = await findTeacherByName(institutionName, teacherName);

      if (teacherData == null) {
        debugPrint(
          'Could not find teacher "$teacherName" in "$institutionName".',
        );
        return [];
      }

      final teacherId = teacherData['teacherId'];
      if (teacherId == null) {
        debugPrint('Teacher document is missing a teacherId.');
        return [];
      }
      return await getAllTeacherStudents(institutionName, teacherId);
    } catch (e) {
      debugPrint('Error getting all students by teacher name: $e');
      return [];
    }
  }

  /// ✨ NEW: Helper method to get all students without filtering by status.
  static Future<List<Map<String, dynamic>>> getAllTeacherStudents(
    String institutionName,
    String teacherId,
  ) async {
    try {
      final studentsQuery = await _firestore
          .collection('institutions')
          .doc(institutionName)
          .collection('teachers')
          .doc(teacherId)
          .collection('students') // No .where('status', ...) filter
          .orderBy('name')
          .get();

      return studentsQuery.docs.map((doc) {
        final data = doc.data();
        data['documentId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting all teacher students: $e');
      return [];
    }
  }

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
          .where('status', isEqualTo: 'accepted')
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
}