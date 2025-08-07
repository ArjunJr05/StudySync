import 'package:flutter/material.dart';
import 'package:studysync/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_router_constants.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Connection is active, waiting for data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. A user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          return child; // User is authorized, show the protected content
        }

        // 3. No user is authenticated
        // Redirect to the login screen if unauthorized.
        // Using a post-frame callback ensures the redirect happens after the build cycle.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            // Using GoRouter to navigate to the entry point for finding a user
            GoRouter.of(context).goNamed(AppRouterConstants.findingUser);
          }
        });
        
        // Show a loading indicator while the redirect happens
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}