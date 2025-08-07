import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_router_constants.dart';
import 'package:studysync/features/Student/presentation/screens/student_main.dart';
import 'package:studysync/features/authLogin/presentation/screens/authlogin.dart';
import 'package:studysync/features/authLogin/presentation/screens/waiting.dart';
import 'package:studysync/features/finding_user/presentation/screens/finding_user.dart';
import 'package:studysync/features/on_boarding/presentation/screens/on_boarding_screen.dart';
import 'package:studysync/features/teacher/presentation/screens/teacher_main.dart';
import 'package:studysync/features/verfication/presentation/screens/student_verify.dart';
import 'package:studysync/features/verfication/presentation/screens/teacher_verify.dart';
import 'package:studysync/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/on-boarding',
      name: AppRouterConstants.onBoarding,
      builder: (context, state) => const OnBoardingScreen(),
    ),
    GoRoute(
      path: '/finding-user',
      name: AppRouterConstants.findingUser,
      builder: (context, state) => const FindingUser(),
    ),
    GoRoute(
      path: '/teacher-verify',
      name: AppRouterConstants.teacherVerify,
      builder: (context, state) => const TeacherVerify(),
    ),
    GoRoute(
      path: '/student-verify',
      name: AppRouterConstants.studentVerify,
      builder: (context, state) => const StudentVerify(),
    ),
    GoRoute(
      path: '/auth-signin/:role',
      name: AppRouterConstants.authSignIn,
      builder: (context, state) {
        final role = state.pathParameters['role'];
        return AuthSignIn(role: role);
      },
    ),
    GoRoute(
      path: '/studentMain/:studentId/:institutionName/:teacherName',
      name: AppRouterConstants.studentMain,
      builder: (context, state) {
        final studentId = state.pathParameters['studentId'] ?? '';
        final institutionName = state.pathParameters['institutionName'] ?? '';
        final teacherName = state.pathParameters['teacherName'] ?? '';
        return StudentDashboardMain(
          studentId: studentId,
          institutionName: institutionName,
          teacherName: teacherName,
        );
      },
    ),
    GoRoute(
      path: '/teacherMain/:teacherId/:institutionName',
      name: AppRouterConstants.teacherMain,
      builder: (context, state) {
        final teacherId = state.pathParameters['teacherId'] ?? '';
        final institutionName = state.pathParameters['institutionName'] ?? '';
        final teacherName = state.pathParameters['teacherName'] ?? '';
        return TeacherDashboardMain(
          teacherId: teacherId,
          institutionName: institutionName, teacherName: teacherName,
        );
      },
    ),
    GoRoute(
  name: AppRouterConstants.studentWaiting,
  path: '/student-waiting/:studentId/:institutionName/:teacherName',
  builder: (context, state) {
    final studentId = state.pathParameters['studentId']!;
    final institutionName = state.pathParameters['institutionName']!;
    final teacherName = state.pathParameters['teacherName']!;
    
    return StudentWaitingPage(
      studentId: studentId,
      institutionName: institutionName,
      teacherName: teacherName,
    );
  },
),
  ],
);
