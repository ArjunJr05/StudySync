import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:studysync/core/services/firestore_service.dart';
import 'package:studysync/features/Student/presentation/widgets/question.dart';

extension TestProgressExtension on FirestoreService {
  
  /// Saves an answered question's result and updates the student's main profile stats.
  /// This now includes validation that all test cases passed before marking as correct.
  static Future<bool> saveAnsweredQuestion({
    required String studentId,
    required String subject,
    required String difficulty,
    required int questionNumber,
    required bool isCorrect,
    required List<bool> testCaseResults, // NEW: Individual test case results
    required String userCode, // NEW: Store the user's code
    required int timeTakenSeconds, // NEW: Actual time tracking
    // Pass student's teacher/institution info for updating stats
    required String institutionName,
    required String teacherName,
  }) async {
    // Validate that ALL test cases passed for the question to be marked as correct
    final bool allTestCasesPassed = testCaseResults.every((result) => result);
    final bool finalIsCorrect = isCorrect && allTestCasesPassed;
    
    // First, save the individual question progress
    final bool progressSaved = await _updateQuestionProgressWithTransaction(
      studentId: studentId,
      subject: subject,
      difficulty: difficulty,
      questionNumber: questionNumber,
      isCorrect: finalIsCorrect,
      additionalData: {
        'testCaseResults': testCaseResults,
        'totalTestCases': testCaseResults.length,
        'passedTestCases': testCaseResults.where((r) => r).length,
        'userCode': userCode,
        'timeTakenSeconds': timeTakenSeconds,
        'submittedAt': FieldValue.serverTimestamp(),
        'allTestCasesPassed': allTestCasesPassed,
      },
    );

    // After saving progress, update the main student document's stats
    if (progressSaved) {
      try {
        final teacherData =
            await FirestoreService.findTeacherByName(institutionName, teacherName);
        if (teacherData != null) {
          final teacherId = teacherData['teacherId'];
          final activityText = finalIsCorrect 
              ? "✅ Completed ${difficulty.toLowerCase()} level $questionNumber"
              : "❌ Attempted ${difficulty.toLowerCase()} level $questionNumber";

          // Update overall performance stats (average, time, etc.)
          await FirestoreService.updateStudentPerformance(
            studentId: studentId,
            institutionName: institutionName,
            teacherId: teacherId,
            wasCorrect: finalIsCorrect,
            timeTakenSeconds: timeTakenSeconds,
          );

          // Add this action to the recent activities feed
          await FirestoreService.addRecentActivity(
            studentId: studentId,
            institutionName: institutionName,
            teacherId: teacherId,
            activity: activityText,
            icon: finalIsCorrect ? 'check_circle' : 'cancel',
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
  /// Now includes comprehensive test case tracking and validation.
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
          // If the document doesn't exist, create it with comprehensive structure
          final newProgressData = {
            'studentId': studentId,
            // Initialize all difficulty levels
            'python_easy_completed': 0,
            'python_easy_correct': 0,
            'python_medium_completed': 0,
            'python_medium_correct': 0,
            'python_hard_completed': 0,
            'python_hard_correct': 0,
            'python_easy_answers': {},
            'python_medium_answers': {},
            'python_hard_answers': {},
            // Add the current answer
            answersField: {
              '$questionNumber': {
                'answered': true,
                'correct': isCorrect,
                'timestamp': FieldValue.serverTimestamp(),
                'questionNumber': questionNumber,
                'attempts': 1,
                ...?additionalData,
              },
            },
            completedField: 1, // First question attempted
            '${subject.toLowerCase()}_${difficulty.toLowerCase()}_correct': isCorrect ? 1 : 0,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'totalAttempts': 1,
            'totalCorrect': isCorrect ? 1 : 0,
          };
          transaction.set(docRef, newProgressData);
        } else {
          // If the document exists, update it with comprehensive tracking
          final data = snapshot.data()!;

          final answers = Map<String, dynamic>.from(data[answersField] ?? {});
          final previousAnswer = answers['$questionNumber'];
          final isRetry = previousAnswer != null;
          final previousAttempts = isRetry ? (previousAnswer['attempts'] ?? 1) : 0;
          
          answers['$questionNumber'] = {
            'answered': true,
            'correct': isCorrect,
            'timestamp': FieldValue.serverTimestamp(),
            'questionNumber': questionNumber,
            'attempts': previousAttempts + 1,
            'isRetry': isRetry,
            'previouslyCorrect': isRetry ? (previousAnswer['correct'] ?? false) : false,
            ...?additionalData,
          };

          final completedCount = answers.length;
          final correctCount = answers.values.where((answer) => answer['correct'] == true).length;
          
          // Calculate total attempts and correct answers across all difficulties
          final currentTotalAttempts = data['totalAttempts'] ?? 0;
          final currentTotalCorrect = data['totalCorrect'] ?? 0;
          
          // If this is a retry of a previously incorrect answer that's now correct,
          // we should increment the correct count
          bool shouldIncrementCorrect = isCorrect;
          if (isRetry && previousAnswer['correct'] == true && !isCorrect) {
            // Previously correct, now incorrect - decrement
            shouldIncrementCorrect = false;
          } else if (isRetry && previousAnswer['correct'] == false && isCorrect) {
            // Previously incorrect, now correct - increment
            shouldIncrementCorrect = true;
          } else if (isRetry) {
            // No change in correctness
            shouldIncrementCorrect = false;
          }

          transaction.update(docRef, {
            answersField: answers,
            completedField: completedCount,
            '${subject.toLowerCase()}_${difficulty.toLowerCase()}_correct': correctCount,
            'lastUpdated': FieldValue.serverTimestamp(),
            'totalAttempts': currentTotalAttempts + 1,
            'totalCorrect': shouldIncrementCorrect 
                ? currentTotalCorrect + 1 
                : (isRetry && previousAnswer['correct'] == true && !isCorrect)
                    ? currentTotalCorrect - 1
                    : currentTotalCorrect,
          });
        }
      });

      debugPrint(
          '✅ Transaction successful for: $subject $difficulty Q$questionNumber (Correct: $isCorrect)');
      return true;
    } catch (e) {
      debugPrint('❌ Error in question progress transaction: $e');
      return false;
    }
  }

  /// Gets student's overall test progress across all subjects and difficulties.
  /// Now includes detailed statistics and performance metrics.
  static Future<Map<String, dynamic>> getStudentTestProgress(
      String studentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('student_progress')
          .doc(studentId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        
        // Calculate additional metrics
        final totalAttempts = data['totalAttempts'] ?? 0;
        final totalCorrect = data['totalCorrect'] ?? 0;
        final successRate = totalAttempts > 0 ? (totalCorrect / totalAttempts * 100) : 0.0;
        
        return {
          ...data,
          'successRate': successRate,
          'hasProgress': totalAttempts > 0,
        };
      }
      
      return {
        'studentId': studentId,
        'python_easy_completed': 0,
        'python_easy_correct': 0,
        'python_medium_completed': 0,
        'python_medium_correct': 0,
        'python_hard_completed': 0,
        'python_hard_correct': 0,
        'totalAttempts': 0,
        'totalCorrect': 0,
        'successRate': 0.0,
        'hasProgress': false,
      };
    } catch (e) {
      debugPrint('❌ Error getting student test progress: $e');
      return {};
    }
  }

  /// Gets answered questions for a specific subject and difficulty.
  /// Now includes detailed attempt history and performance data.
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

  /// Gets detailed statistics for a specific difficulty level.
  static Future<Map<String, dynamic>> getDifficultyStats({
    required String studentId,
    required String subject,
    required String difficulty,
  }) async {
    try {
      final progress = await getStudentTestProgress(studentId);
      final answeredQuestions = await getAnsweredQuestions(
        studentId: studentId,
        subject: subject,
        difficulty: difficulty,
      );

      final completed = progress['${subject.toLowerCase()}_${difficulty.toLowerCase()}_completed'] ?? 0;
      final correct = progress['${subject.toLowerCase()}_${difficulty.toLowerCase()}_correct'] ?? 0;
      final totalQuestions = _getTotalQuestionsForDifficulty(difficulty);
      
      // Calculate detailed metrics
      final completionRate = totalQuestions > 0 ? (completed / totalQuestions * 100) : 0.0;
      final accuracyRate = completed > 0 ? (correct / completed * 100) : 0.0;
      
      // Calculate average attempts
      final attempts = answeredQuestions.values.map((q) => q['attempts'] ?? 1).toList();
      final avgAttempts = attempts.isNotEmpty ? attempts.reduce((a, b) => a + b) / attempts.length : 0.0;
      
      // Find longest streak of correct answers
      int currentStreak = 0;
      int maxStreak = 0;
      for (int i = 1; i <= totalQuestions; i++) {
        if (answeredQuestions[i]?['correct'] == true) {
          currentStreak++;
          maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
        } else {
          currentStreak = 0;
        }
      }

      return {
        'difficulty': difficulty,
        'completed': completed,
        'correct': correct,
        'totalQuestions': totalQuestions,
        'completionRate': completionRate,
        'accuracyRate': accuracyRate,
        'averageAttempts': avgAttempts,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'nextUnlocked': _getNextUnlockedQuestion(answeredQuestions, totalQuestions),
      };
    } catch (e) {
      debugPrint('❌ Error getting difficulty stats: $e');
      return {};
    }
  }

  /// Helper method to get total questions for a difficulty level.
  static int _getTotalQuestionsForDifficulty(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return 5; // Based on our question service
      case 'MEDIUM':
        return 5;
      case 'HARD':
        return 5;
      default:
        return 5;
    }
  }

  /// Helper method to find the next unlocked question.
  static int? _getNextUnlockedQuestion(Map<int, Map<String, dynamic>> answeredQuestions, int totalQuestions) {
    for (int i = 1; i <= totalQuestions; i++) {
      if (!answeredQuestions.containsKey(i)) {
        return i;
      }
      if (answeredQuestions[i]?['correct'] == false) {
        return i; // Can retry incorrect questions
      }
    }
    return null; // All questions completed correctly
  }

  /// Validates that a student can access a specific question level.
  static Future<Map<String, dynamic>> canAccessQuestion({
    required String studentId,
    required String subject,
    required String difficulty,
    required int questionNumber,
  }) async {
    try {
      final answeredQuestions = await getAnsweredQuestions(
        studentId: studentId,
        subject: subject,
        difficulty: difficulty,
      );

      // First question is always accessible
      if (questionNumber == 1) {
        return {
          'canAccess': true,
          'reason': 'First question',
          'status': 'unlocked',
        };
      }

      // Check if previous question was completed correctly
      final previousQuestion = answeredQuestions[questionNumber - 1];
      if (previousQuestion == null) {
        return {
          'canAccess': false,
          'reason': 'Previous question not attempted',
          'status': 'locked',
          'requiredQuestion': questionNumber - 1,
        };
      }

      if (previousQuestion['correct'] != true) {
        return {
          'canAccess': false,
          'reason': 'Previous question not completed correctly',
          'status': 'locked',
          'requiredQuestion': questionNumber - 1,
        };
      }

      // Check current question status
      final currentQuestion = answeredQuestions[questionNumber];
      if (currentQuestion == null) {
        return {
          'canAccess': true,
          'reason': 'Question unlocked and not attempted',
          'status': 'unlocked',
        };
      }

      if (currentQuestion['correct'] == false) {
        return {
          'canAccess': true,
          'reason': 'Question can be retried',
          'status': 'retry',
          'attempts': currentQuestion['attempts'] ?? 1,
        };
      }

      return {
        'canAccess': true,
        'reason': 'Question already completed',
        'status': 'completed',
        'attempts': currentQuestion['attempts'] ?? 1,
      };
    } catch (e) {
      debugPrint('❌ Error checking question access: $e');
      return {
        'canAccess': false,
        'reason': 'Error occurred',
        'status': 'error',
      };
    }
  }

  /// Gets the current question for a student based on their progress.
  static Future<Question?> getCurrentQuestion({
    required String studentId,
    required String difficulty,
  }) async {
    try {
      final answeredQuestions = await getAnsweredQuestions(
        studentId: studentId,
        subject: 'python',
        difficulty: difficulty,
      );

      final nextQuestionNumber = _getNextUnlockedQuestion(
        answeredQuestions, 
        _getTotalQuestionsForDifficulty(difficulty)
      );

      if (nextQuestionNumber == null) {
        return null; // All questions completed
      }

      return QuestionService.getQuestion(difficulty, nextQuestionNumber);
    } catch (e) {
      debugPrint('❌ Error getting current question: $e');
      return null;
    }
  }
}