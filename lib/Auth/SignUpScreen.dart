import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hurrey_app/Screens/dashboard.dart';

/// SignUpScreen - A user registration screen with neumorphic design
/// Features user registration with Firebase Auth and Firestore
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Color constants matching the login screen
  static const Color backgroundColor = Color(0xFFE6E9EF);
  static const Color primaryColor = Color(0xFF3B6CFF); // Updated
  static const Color textColor = Color(0xFF3D3D3D);
  
  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // State variables
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  
  // Firebase instances
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  static const String _collectionName = 'users';

  /// Handles the user registration process
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Create user with email and password
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final user = cred.user;
      if (user == null) throw FirebaseAuthException(code: 'user-null', message: 'User not found');

      // Update user profile with display name
      await user.updateDisplayName(_nameController.text.trim());
      
      // Store additional user data in Firestore
      await _db.collection(_collectionName).doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'User',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      // Clear form and show success message
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ User created successfully'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
      
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "Registration failed");
    } catch (_) {
      setState(() => _error = "Something went wrong");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE6E9EF), Color(0xFFD1D9E6)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar-like header
                Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, Color(0xFF3463D1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NeumorphicContainer(
                          width: 80,
                          height: 80,
                          borderRadius: BorderRadius.circular(20),
                          child: const Icon(Icons.person_add, color: primaryColor, size: 40),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Create New User",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Fill in the user details below",
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Form
                        Expanded(
                          child: NeumorphicContainer(
                            padding: const EdgeInsets.all(28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  NeumorphicTextField(
                                    controller: _nameController,
                                    hintText: "Full Name",
                                    prefixIcon: Icons.person_outline,
                                    validator: (v) => v!.trim().isEmpty ? "Enter full name" : null,
                                  ),
                                  const SizedBox(height: 20),
                                  NeumorphicTextField(
                                    controller: _emailController,
                                    hintText: "Email Address",
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return "Enter email";
                                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                                        return "Enter valid email";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  NeumorphicTextField(
                                    controller: _passwordController,
                                    hintText: "Password",
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    onSuffixPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return "Enter password";
                                      if (v.length < 6) return "At least 6 characters";
                                      return null;
                                    },
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  NeumorphicButton(
                                    onPressed: _loading ? null : _signUp,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            "Create User",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "User will be added to the system with default permissions",
                          style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5), height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_loading)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// NEUMORPHIC WIDGETS

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E9EF),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.8), offset: const Offset(-4, -4), blurRadius: 8),
          BoxShadow(color: const Color(0xFFA3B1C6).withOpacity(0.4), offset: const Offset(4, 4), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }
}

class NeumorphicTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final String? Function(String?)? validator;

  const NeumorphicTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixPressed,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF3D3D3D);
    return NeumorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
          border: InputBorder.none,
          prefixIcon: Icon(prefixIcon, color: textColor.withOpacity(0.6)),
          suffixIcon: suffixIcon != null
              ? IconButton(icon: Icon(suffixIcon, color: textColor.withOpacity(0.6)), onPressed: onSuffixPressed)
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}

class NeumorphicButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const NeumorphicButton({super.key, this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3B6CFF); // Updated
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), offset: const Offset(0, 4), blurRadius: 8)],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: child,
      ),
    );
  }
}
