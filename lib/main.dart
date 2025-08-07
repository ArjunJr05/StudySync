import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:studysync/core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }



  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Study Sync - Department App',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
