import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:studysync/core/services/firestore_service.dart';

extension TestProgressExtension on FirestoreService {
  
  /// Saves an answered question's result and updates the student's main profile stats.
  static Future<bool> saveAnsweredQuestion({
    required String studentId,
    required String subject,
    required String difficulty,
    required int questionNumber,
    required bool isCorrect,
    // NEW: Pass student's teacher/institution info for updating stats
    required String institutionName,
    required String teacherName,
  }) async {
    // First, save the individual question progress
    final bool progressSaved = await _updateQuestionProgressWithTransaction(
      studentId: studentId,
      subject: subject,
      difficulty: difficulty,
      questionNumber: questionNumber,
      isCorrect: isCorrect,
    );

    // After saving progress, update the main student document's stats
    if (progressSaved) {
      try {
        final teacherData =
            await FirestoreService.findTeacherByName(institutionName, teacherName);
        if (teacherData != null) {
          final teacherId = teacherData['teacherId'];
          final activityText =
              "Completed ${difficulty.toLowerCase()} level $questionNumber";

          // Update overall performance stats (average, time, etc.)
          await FirestoreService.updateStudentPerformance(
            studentId: studentId,
            institutionName: institutionName,
            teacherId: teacherId,
            wasCorrect: isCorrect,
            timeTakenSeconds: 30, // Placeholder for time spent on question
          );

          // Add this action to the recent activities feed
          await FirestoreService.addRecentActivity(
            studentId: studentId,
            institutionName: institutionName,
            teacherId: teacherId,
            activity: activityText,
            icon: isCorrect ? 'check_circle' : 'cancel',
          );
        }
      } catch (e) {
        debugPrint('❌ Error updating student stats after test: $e');
        // We don't return false, as the primary action (saving progress) succeeded.
      }
    }
    return progressSaved;
  }

  /// Updates a question's progress using a Firestore Transaction for data consistency.
  static Future<bool> _updateQuestionProgressWithTransaction({
    required String studentId,
    required String subject,
    required String difficulty,
    required int questionNumber,
    required bool isCorrect,
    Map<String, dynamic>? additionalData,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('student_progress').doc(studentId);
    final answersField =
        '${subject.toLowerCase()}_${difficulty.toLowerCase()}_answers';
    final completedField =
        '${subject.toLowerCase()}_${difficulty.toLowerCase()}_completed';

    try {
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          // If the document doesn't exist, create it with the first answer.
          final newProgressData = {
            'studentId': studentId,
            'python_easy_completed': 0,
            'python_medium_completed': 0,
            'python_hard_completed': 0,
            'python_easy_answers': {},
            'python_medium_answers': {},
            'python_hard_answers': {},
            answersField: {
              '$questionNumber': {
                'answered': true,
                'correct': isCorrect,
                'timestamp': FieldValue.serverTimestamp(),
                'questionNumber': questionNumber,
                ...?additionalData,
              },
            },
            completedField: 1, // First question completed
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          };
          transaction.set(docRef, newProgressData);
        } else {
          // If the document exists, update it.
          final data = snapshot.data()!;

          final answers = Map<String, dynamic>.from(data[answersField] ?? {});
          answers['$questionNumber'] = {
            'answered': true,
            'correct': isCorrect,
            'timestamp': FieldValue.serverTimestamp(),
            'questionNumber': questionNumber,
            ...?additionalData,
          };

          final completedCount = answers.length;

          transaction.update(docRef, {
            answersField: answers,
            completedField: completedCount,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      debugPrint(
          '✅ Transaction successful for: $subject $difficulty Q$questionNumber');
      return true;
    } catch (e) {
      debugPrint('❌ Error in question progress transaction: $e');
      return false;
    }
  }

  /// Gets student's overall test progress across all subjects and difficulties.
  static Future<Map<String, dynamic>> getStudentTestProgress(
      String studentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('student_progress')
          .doc(studentId)
          .get();

      if (doc.exists) {
        return doc.data()!;
      }
      return {
        'studentId': studentId,
        'python_easy_completed': 0,
        'python_medium_completed': 0,
        'python_hard_completed': 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting student test progress: $e');
      return {};
    }
  }

  /// Gets answered questions for a specific subject and difficulty.
  static Future<Map<int, Map<String, dynamic>>> getAnsweredQuestions({
    required String studentId,
    required String subject,
    required String difficulty,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('student_progress')
          .doc(studentId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final answersField =
            '${subject.toLowerCase()}_${difficulty.toLowerCase()}_answers';
        final answers = data[answersField] as Map<String, dynamic>? ?? {};

        Map<int, Map<String, dynamic>> result = {};
        answers.forEach((key, value) {
          final questionNumber = int.tryParse(key);
          if (questionNumber != null && value is Map<String, dynamic>) {
            result[questionNumber] = Map<String, dynamic>.from(value);
          }
        });

        return result;
      }
      return {};
    } catch (e) {
      debugPrint('❌ Error getting answered questions: $e');
      return {};
    }
  }
}
