import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const Map<String, dynamic> firebaseConfig = {
    'apiKey': 'AIzaSyDRBa_gTJ_NdUy9dcjqBFDfb8ifONwg7lA',
    'authDomain': 'smartfabmaterialtracker.firebaseapp.com',
    'projectId': 'smartfabmaterialtracker',
    'storageBucket': 'smartfabmaterialtracker.firebasestorage.app',
    'messagingSenderId': '1029042391205',
    'appId': '1:1029042391205:web:2172c1de56cda29864254c',
    'measurementId': 'G-39JPXLNEMB',
  };

  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: kIsWeb
            ? FirebaseOptions(
                apiKey: firebaseConfig['apiKey'],
                authDomain: firebaseConfig['authDomain'],
                projectId: firebaseConfig['projectId'],
                storageBucket: firebaseConfig['storageBucket'],
                messagingSenderId: firebaseConfig['messagingSenderId'],
                appId: firebaseConfig['appId'],
                measurementId: firebaseConfig['measurementId'],
              )
            : null,
      );
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization error: $e');
      rethrow;
    }
  }

  static bool validateEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  static bool validatePassword(String password) {
    return password.length >= 6;
  }
}