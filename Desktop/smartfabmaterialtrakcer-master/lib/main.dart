import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/firebase_config.dart';
import 'screens/login_screen.dart';
import 'screens/error_screen.dart';

Future<void> main() async {
  // Comprehensive error handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Text(
          'An error occurred: ${details.exception}',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  };

  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Enable verbose logging for debugging
  debugPrint = (String? message, {int? wrapWidth}) {
    print(message ?? '');
  };

  // Capture and log all errors
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Unhandled Flutter Error: ${details.exception}');
    print('Stack Trace: ${details.stack}');
  };


  try {
    // Verbose Firebase initialization logging
    print('Starting Firebase initialization...');

    // Initialize Firebase with comprehensive configuration
    try {
      await FirebaseConfig.initializeFirebase();
      print('Firebase initialization complete');
    } catch (e) {
      print('Critical Firebase initialization failure: $e');
      throw Exception('Firebase initialization failed: $e');
    }

    // Setup comprehensive authentication state listener
    FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        // Log detailed authentication state
        if (user != null) {
          print('User authenticated: ${user.email}');
          print('User UID: ${user.uid}');
          print('Email Verified: ${user.emailVerified}');
          print('Providers: ${user.providerData.map((p) => p.providerId).toList()}');
        } else {
          print('No user is currently signed in');
        }
      },
      onError: (e) {
        print('Authentication state listener error: $e');
      }
    );

    runApp(const SmartFabMaterialTrackerApp());
  } catch (e) {
    print('App initialization failed: $e');
    runApp(ErrorScreen(error: 'Failed to initialize app: $e'));
  }
}

class SmartFabMaterialTrackerApp extends StatelessWidget {
  const SmartFabMaterialTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFab Material Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartFab Material Tracker'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Welcome to Material Tracking',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Streamline your inventory management',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}