import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  
  final Dio _dio = Dio();
  final String _backendUrl = "http://192.168.29.41:5000"; // Your Flask backend
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isLogin) {
        // First authenticate with Firebase
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        final idToken = await userCredential.user!.getIdToken();

        // Then call your backend login endpoint
        final response = await _dio.post(
          '$_backendUrl/login',
          data: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization':  idToken,
            },
          ),
        );
        
        print('Backend login response: ${response.data}');
      } else {
        // First create user in Firebase
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        final idToken = await userCredential.user!.getIdToken();

        // Then call your backend register endpoint
        final response = await _dio.post(
          '$_backendUrl/register',
          data: {
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization':  idToken,
            },
          ),
        );
        
        print('Backend registration response: ${response.data}');
      }
      
      // Navigation handled by AuthWrapper
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } on DioException catch (e) {
      _handleBackendError(e);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String message = 'Authentication failed';
    if (e.code == 'user-not-found') {
      message = 'No user found with this email';
    } else if (e.code == 'wrong-password') {
      message = 'Incorrect password';
    } else if (e.code == 'email-already-in-use') {
      message = 'Email already in use';
    } else if (e.code == 'weak-password') {
      message = 'Password is too weak';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleBackendError(DioException e) {
    String message = 'Server error occurred';
    if (e.response != null) {
      message = e.response?.data['error'] ?? 
               e.response?.statusMessage ?? 
               message;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      _isLogin ? 'Welcome back' : 'Create account',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    if (!_isLogin) ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin 
                          ? "Don't have an account? Sign Up" 
                          : "Already have an account? Sign In",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}