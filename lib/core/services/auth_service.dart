import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studysync/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userIdKey = 'userId';
  static const String _userRoleKey = 'userRole';
  static const String _institutionNameKey = 'institutionName';
  static const String _teacherNameKey = 'teacherName'; // Specific to students

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // --- Public Methods ---

  /// Stream to listen for authentication state changes from Firebase.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Retrieves the currently authenticated user from Firebase.
  static User? getCurrentUser() => _auth.currentUser;

  /// Signs in a student, creating a profile with 'pending' status on the first sign-in.
Future<Map<String, dynamic>> signInWithGoogleStudent({
  required String institutionName,
  required String teacherName,
}) async {
  try {
    debugPrint('=== Starting Student Google Sign In ===');
    debugPrint('Institution: $institutionName');
    debugPrint('Teacher: $teacherName');

    // Validate input parameters
    if (institutionName.trim().isEmpty) {
      return {'success': false, 'message': 'Institution name cannot be empty.'};
    }
    if (teacherName.trim().isEmpty) {
      return {'success': false, 'message': 'Teacher name cannot be empty.'};
    }

    // Step 1: Google Sign In
    debugPrint('🔐 Step 1: Attempting Google Sign In...');
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('❌ Google sign-in was cancelled by user');
      return {'success': false, 'message': 'Google sign-in was cancelled.'};
    }

    debugPrint('✅ Google user obtained: ${googleUser.email}');

    // Step 2: Firebase Authentication
    debugPrint('🔐 Step 2: Authenticating with Firebase...');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user == null) {
      debugPrint('❌ Firebase authentication failed');
      return {'success': false, 'message': 'Failed to authenticate user.'};
    }

    debugPrint('✅ Firebase user authenticated: ${user.email}');

    // Step 3: Check if institution and teacher exist
    debugPrint('🔍 Step 3: Verifying teacher exists...');
    final institutionExists = await FirestoreService.institutionHasTeachers(institutionName.trim());
    if (!institutionExists) {
      return {
        'success': false,
        'message': 'Institution "$institutionName" not found or has no teachers.'
      };
    }

    final teacherData = await FirestoreService.findTeacherByName(
        institutionName.trim(), teacherName.trim());
    if (teacherData == null) {
      return {
        'success': false,
        'message': 'Teacher "$teacherName" not found in "$institutionName". Please check the teacher name and try again.'
      };
    }

    debugPrint('✅ Teacher verified: ${teacherData['teacherId']}');

    // Step 4: Check if student already exists
    debugPrint('🔍 Step 4: Checking if student already exists...');
    final existingStudent = await FirestoreService.getStudentData(
        user.email!, teacherName.trim(), institutionName.trim());

    if (existingStudent != null) {
      // Student exists, just log them in and return their status
      debugPrint('✅ Existing student found with status: ${existingStudent['status']}');
      
      // Update last sign in
      await FirestoreService.updateLastSignIn(
          user.email!, institutionName.trim(), 'student',
          teacherName: teacherName.trim());
      
      // Save session
      await _saveSession(
        userId: existingStudent['studentId'],
        role: 'student',
        institutionName: institutionName.trim(),
        teacherName: teacherName.trim(),
      );

      final status = existingStudent['status'] as String? ?? 'pending';
      String welcomeMessage;
      if (status == 'accepted') {
        welcomeMessage = 'Welcome back!';
      } else if (status == 'pending') {
        welcomeMessage = 'Welcome back! Your request is still pending teacher approval.';
      } else {
        welcomeMessage = 'Welcome back!';
      }

      return {
        'success': true,
        'message': welcomeMessage,
        'studentId': existingStudent['studentId'],
        'userRole': 'student',
        'status': status,
        'institutionName': institutionName.trim(),
        'teacherName': teacherName.trim(),
      };
    } else {
      // Step 5: New student - Create student document and a join request
      debugPrint('✨ Step 5: Creating new student profile...');
      
      final studentId = FirestoreService.generateStudentId(user.email!);
      debugPrint('Generated student ID: $studentId');

      // Prepare additional data
      final additionalData = {
        'uid': user.uid,
        'photoURL': user.photoURL,
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint('📝 Creating student document...');
      // Create the main student document with 'pending' status
      final studentProfileCreated = await FirestoreService.saveStudentData(
        institutionName: institutionName.trim(),
        teacherName: teacherName.trim(),
        studentEmail: user.email!,
        studentName: user.displayName ?? 'New Student',
        studentId: studentId,
        additionalData: additionalData,
      );

      if (!studentProfileCreated) {
        debugPrint('❌ Failed to create student profile');
        return {
          'success': false,
          'message': 'Failed to create your student profile. Please check your internet connection and try again.'
        };
      }

      debugPrint('✅ Student profile created successfully');

      // Step 6: Create a separate request for the teacher to see in their UI
      debugPrint('📨 Step 6: Sending join request to teacher...');
      final requestSent = await FirestoreService.sendStudentRequest(
        institutionName: institutionName.trim(),
        teacherName: teacherName.trim(),
        studentEmail: user.email!,
        studentName: user.displayName ?? 'New Student',
        studentId: studentId,
        additionalData: {
          'photoURL': user.photoURL,
          'uid': user.uid,
        },
      );

      if (!requestSent) {
        debugPrint('❌ Failed to send join request');
        // Even if request sending fails, the student profile was created
        // So we can still proceed, but warn the user
        return {
          'success': false,
          'message': 'Your profile was created but failed to send join request to teacher. Please contact your teacher directly.'
        };
      }

      debugPrint('✅ Join request sent successfully');

      // Save session
      await _saveSession(
        userId: studentId,
        role: 'student',
        institutionName: institutionName.trim(),
        teacherName: teacherName.trim(),
      );

      debugPrint('✅ New student profile and request created: $studentId');

      return {
        'success': true,
        'message': 'Welcome! Your join request has been sent to your teacher. Please wait for approval.',
        'studentId': studentId,
        'userRole': 'student',
        'status': 'pending',
        'institutionName': institutionName.trim(),
        'teacherName': teacherName.trim(),
      };
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Error in signInWithGoogleStudent: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    
    // Provide more specific error messages based on the error type
    String errorMessage = 'An unexpected error occurred during sign-in.';
    
    if (e.toString().contains('network')) {
      errorMessage = 'Network error. Please check your internet connection and try again.';
    } else if (e.toString().contains('permission-denied')) {
      errorMessage = 'Permission denied. Please contact your administrator.';
    } else if (e.toString().contains('sign_in_canceled')) {
      errorMessage = 'Sign-in was cancelled.';
    } else if (e.toString().contains('sign_in_failed')) {
      errorMessage = 'Google sign-in failed. Please try again.';
    }

    return {
      'success': false,
      'message': errorMessage,
      'error': e.toString(),
    };
  }
}

  /// Signs in a teacher, creating a new account if one doesn't exist.
  Future<Map<String, dynamic>> signInWithGoogleTeacher({
    required String institutionName,
    required String teacherName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('=== Starting Teacher Google Sign In ===');
      await _forceSignOut();

      final googleUser = await _performGoogleSignIn();
      if (googleUser == null) {
        return _errorResponse('Sign-in was cancelled.', 'cancelled');
      }

      final user = await _signInToFirebaseWithGoogle(googleUser);
      if (user == null) {
        return _errorResponse('Firebase sign-in failed.', 'firebase_error');
      }

      final existingTeacherData = await FirestoreService.getTeacherData(
        user.email!,
        institutionName.trim(),
      );

      if (existingTeacherData != null) {
        debugPrint('✅ Existing teacher found. Updating last sign-in.');
        await FirestoreService.updateLastSignIn(
          user.email!,
          institutionName.trim(),
          'teacher',
        );

        final teacherId = existingTeacherData['teacherId'];
        await _saveSession(
          userId: teacherId,
          role: 'teacher',
          institutionName: institutionName.trim(),
        );

        return {
          'success': true,
          'teacherId': teacherId,
          'institutionName': institutionName.trim(),
          'userRole': 'teacher',
          'message': 'Welcome back!',
        };
      } else {
        debugPrint('✨ New teacher. Creating record.');
        final teacherId = FirestoreService.generateTeacherId(user.email!);
        final success = await FirestoreService.saveTeacherData(
          institutionName: institutionName.trim(),
          teacherEmail: user.email!,
          teacherName: teacherName.trim(),
          teacherId: teacherId,
          additionalData: _buildUserData(user, 'google', additionalData),
        );

        if (!success) {
          return _errorResponse(
              'Failed to save your data.', 'firestore_save_error');
        }

        await _saveSession(
          userId: teacherId,
          role: 'teacher',
          institutionName: institutionName.trim(),
        );

        return {
          'success': true,
          'teacherId': teacherId,
          'institutionName': institutionName.trim(),
          'userRole': 'teacher',
          'message': 'Account created successfully!',
        };
      }
    } catch (e) {
      return _errorResponse(
        'An unexpected error occurred.',
        'unexpected_error',
        error: e.toString(),
      );
    }
  }

  /// Checks student approval status. Relies on local session data.
  Future<String> checkStudentApprovalStatus(String studentId) async {
    try {
      debugPrint('🔍 Checking approval status for student: $studentId');
      final userDetails = await getUserDetails();
      final institutionName = userDetails['institutionName'];
      final teacherName = userDetails['teacherName'];

      if (institutionName == null || teacherName == null) {
        debugPrint('❌ Missing session info. Defaulting to pending.');
        return 'pending';
      }

      // Check the student document directly for the status
      final studentData = await FirestoreService.getStudentDataById(
        studentId,
        teacherName,
        institutionName,
      );

      return studentData?['status'] as String? ?? 'pending';
    } catch (e) {
      debugPrint('❌ Error checking student approval status: $e');
      return 'pending';
    }
  }

  /// Creates a real-time listener for student approval status.
  Stream<String> streamStudentApprovalStatus(String studentId) {
    // This now streams the student document itself for status changes
    return FirestoreService.streamStudentDocument(studentId).map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data()?['status'] as String? ?? 'pending';
      }
      return 'pending';
    });
  }

  /// Signs out from Firebase, Google, and clears local session.
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _forceSignOut();
    debugPrint('✅ User signed out and session cleared.');
  }

  // --- Session Management ---

  Future<void> _saveSession({
    required String userId,
    required String role,
    required String institutionName,
    String? teacherName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_institutionNameKey, institutionName);
    if (role == 'student' && teacherName != null) {
      await prefs.setString(_teacherNameKey, teacherName);
    }
    debugPrint('💾 Session saved - Role: $role, ID: $userId');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<Map<String, String?>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_userIdKey),
      'role': prefs.getString(_userRoleKey),
      'institutionName': prefs.getString(_institutionNameKey),
      'teacherName': prefs.getString(_teacherNameKey),
    };
  }

  // --- Private Helper Methods ---

  static Future<void> _forceSignOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error during sign out: $e");
    }
  }

  static Future<GoogleSignInAccount?> _performGoogleSignIn() async =>
      await _googleSignIn.signIn();

  static Future<User?> _signInToFirebaseWithGoogle(
      GoogleSignInAccount googleUser) async {
    try {
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return (await _auth.signInWithCredential(cred)).user;
    } catch (e) {
      debugPrint("Firebase sign-in with Google failed: $e");
      return null;
    }
  }

  static Map<String, dynamic> _buildUserData(
    User user,
    String method,
    Map<String, dynamic>? data,
  ) {
    return {
      'uid': user.uid,
      'provider': method,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSignInAt': FieldValue.serverTimestamp(),
      ...?data
    };
  }

  static Map<String, dynamic> _errorResponse(
    String message,
    String step, {
    String? error,
  }) {
    debugPrint(
        '❌ Auth Error [$step]: $message ${error != null ? '($error)' : ''}');
    return {'success': false, 'message': message, 'step': step};
  }
}
