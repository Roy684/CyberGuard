import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:overlay_support/overlay_support.dart';
import 'firebase_options.dart';
import 'login_page.dart'; // Your login page
import 'permissions_page.dart'; // Your permissions page
import 'theme.dart'; // Your app theme
//import 'firebase_auth_service.dart'; // Authentication service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(
    OverlaySupport.global(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        return user == null ? const LoginPage() : const PermissionsPage();
      },
    );
  }
}

// Updated Login Page with Firebase Authentication
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final FirebaseAuthService _authService = FirebaseAuthService();
//   bool _isLoading = false;

//   Future<void> _signIn() async {
//     setState(() => _isLoading = true);

//     try {
//       await _authService.signInAnonymously();
//       Navigator.pushReplacementNamed(context, '/');
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Login error: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Login')),
//       body: Center(
//         child: _isLoading
//             ? const CircularProgressIndicator()
//             : ElevatedButton(
//                 onPressed: _signIn,
//                 child: const Text('Sign In Anonymously'),
//               ),
//       ),
//     );
//   }
// }
