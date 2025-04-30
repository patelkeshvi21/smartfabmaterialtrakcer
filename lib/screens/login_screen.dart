import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/firebase_config.dart';
import '../models/user_model.dart';
import 'admin/admin_dashboard.dart';
import 'operator/operator_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    // Reset any previous error states
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    // Ensure Firebase is fully initialized
    await FirebaseConfig.initializeFirebase();

    // Validate input fields before attempting login
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    // Extensive logging for debugging
    if (kDebugMode) {
      print('Login attempt started');
    }
    // Ensure Firebase is initialized
    await FirebaseConfig.initializeFirebase();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // Validate inputs
        if (!FirebaseConfig.validateEmail(email)) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Invalid email format',
          );
        }

        if (!FirebaseConfig.validatePassword(password)) {
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'Password must be at least 6 characters',
          );
        }

        // Attempt sign-in
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Verify user in Firestore
        if (kDebugMode) {
          print('User authenticated. UID: ${userCredential.user!.uid}');
        }
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (kDebugMode) {
          print('Firestore user document exists: ${userDoc.exists}');
          if (userDoc.exists) {
            print('User document data: ${userDoc.data()}');
          }
        }

        if (!userDoc.exists) {
          // Attempt to create user profile if it doesn't exist
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'email': email,
              'name': email.split('@').first, // Use email username as default name
              'role': 'operator', // Default role
              'createdAt': FieldValue.serverTimestamp(),
            });
            
            if (kDebugMode) {
              print('Created new user profile for $email');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to create user profile: $e');
            }
            throw FirebaseAuthException(
              code: 'user-profile-error',
              message: 'Could not create user profile',
            );
          }
        }

        UserModel currentUser = UserModel.fromFirestore(userDoc);

        // Navigate to appropriate dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => currentUser.role == UserRole.admin
                ? const AdminDashboardScreen()
                : const OperatorDashboardScreen(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
          _isLoading = false;
        });
      } catch (e) {
        // Comprehensive error handling
        String errorMessage = 'Login failed. Please try again.';
        
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'No account found with this email.';
              break;
            case 'wrong-password':
              errorMessage = 'Incorrect password. Please try again.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many login attempts. Please try again later.';
              break;
            case 'network-request-failed':
              errorMessage = 'Network error. Please check your connection.';
              break;
            default:
              errorMessage = 'Authentication error: ${e.message}';
          }
        } else if (e is FirebaseException) {
          errorMessage = 'Firebase error: ${e.message ?? 'Unknown error'}';
        }

        // Update UI with error
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });

        // Log detailed error for debugging
        if (kDebugMode) {
          print('Login Error: $e');
          print('Error Type: ${e.runtimeType}');
          print('Error Details: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Google login error: $e');
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This user account has been disabled';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartFab Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SmartFab Material Tracker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Email Input
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!FirebaseConfig.validateEmail(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (!FirebaseConfig.validatePassword(value)) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 20),

                // Login Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                const SizedBox(height: 20),

                // Google Login Button
                ElevatedButton.icon(
                  onPressed: _loginWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Login with Google'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Signup Navigation
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printAllUsers() async {
    try {
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersCollection.get();
      
      print('Total users in Firestore: ${querySnapshot.docs.length}');
      for (var doc in querySnapshot.docs) {
        print('User ID: ${doc.id}');
        print('User Data: ${doc.data()}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  @override
  void dispose() {
    // Debug method to print all users in Firestore
    if (kDebugMode) {
      _printAllUsers();
    }
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Navigator.of(context).pop();
      } catch (e) {
        print('Signup error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Enter an email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Password too short' : null,
              ),
              ElevatedButton(
                onPressed: _signup,
                child: const Text('Signup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
