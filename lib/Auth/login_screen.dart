import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hurrey_app/Screens/dashboard.dart';

/// LoginScreenModern - A modern authentication screen with neumorphic design
/// Features email/password authentication using Firebase Auth
/// Navigates to AdminDashboard upon successful login
class LoginScreenModern extends StatefulWidget {
  const LoginScreenModern({super.key});

  @override
  State<LoginScreenModern> createState() => _LoginScreenModernState();
}

class _LoginScreenModernState extends State<LoginScreenModern>
    with SingleTickerProviderStateMixin {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for email and password text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State variables
  bool _obscurePassword = true; // Toggles password visibility
  bool _loading = false;        // Shows loading state during authentication
  
  // Animation controllers for entrance animations
  late final AnimationController _ac;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations for smooth entrance effects
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    // Fade animation for the entire content
    _fadeIn = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    
    // Slide up animation for content entrance
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08), // Starts slightly lower
      end: Offset.zero,             // Ends at normal position
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    
    // Start the animation
    _ac.forward();
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _ac.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the sign-in process with Firebase Authentication
  /// Validates form inputs and attempts to authenticate user
  Future<void> _signIn() async {
    // Validate form inputs before proceeding
    if (!_formKey.currentState!.validate()) return;
    
    // Set loading state to true to show progress indicator
    setState(() => _loading = true);
    
    // Get trimmed email and password values
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // Attempt to sign in with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Navigate to dashboard if authentication is successful
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      _showSnack(e.message ?? 'Login failed');
    } catch (_) {
      // Handle generic errors
      _showSnack('Something went wrong');
    } finally {
      // Reset loading state regardless of success or failure
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Displays a snackbar with the provided message
  void _showSnack(String msg) {
    const primaryColor = Color(0xFF3B6CFF);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Color constants for consistent theming
    const backgroundColor = Color(0xFFE6E9EF);    // Light gray background
    const primaryColor = Color(0xFF3B6CFF);       // Blue accent color
    const textColor = Color(0xFF3D3D3D);          // Dark text color

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background with subtle gradient for depth
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE6E9EF), Color(0xFFD1D9E6)],
              ),
            ),
          ),
          
          // Main content area
          SafeArea(
            child: Column(
              children: [
                // Animated content with fade and slide effects
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo and welcome section
                            Column(
                              children: [
                                // App logo with neumorphic container
                                NeumorphicContainer(
                                  width: 100,
                                  height: 100,
                                  borderRadius: BorderRadius.circular(20),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      'image/Logo.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, _, __) => Icon(
                                        Icons.account_circle,
                                        color: primaryColor,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Welcome title
                                Text(
                                  "Welcome Back",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Subtitle
                                Text(
                                  "Sign in to continue",
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Login form with neumorphic design
                            NeumorphicContainer(
                              padding: const EdgeInsets.all(28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Form title
                                    Text(
                                      "Login",
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Email input field
                                    NeumorphicTextField(
                                      controller: _emailController,
                                      hintText: "Email Address",
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return "Please enter your email";
                                        }
                                        final isValidEmail = RegExp(
                                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                        ).hasMatch(v.trim());
                                        return isValidEmail ? null : "Please enter a valid email";
                                      },
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Password input field
                                    NeumorphicTextField(
                                      controller: _passwordController,
                                      hintText: "Password",
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      suffixIcon: _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      onSuffixPressed: () => setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      }),
                                      validator: (v) => (v == null || v.length < 6)
                                          ? "Password must be at least 6 characters"
                                          : null,
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Sign in button
                                    NeumorphicButton(
                                      onPressed: _loading ? null : _signIn,
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
                                              "Sign In",
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
                            
                            const SizedBox(height: 24),
                            
                            // Terms and privacy notice
                            Text(
                              "By continuing, you agree to our Terms of Service and Privacy Policy",
                              style: TextStyle(
                                fontSize: 11,
                                color: textColor.withOpacity(0.5),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// NeumorphicContainer - A custom widget that creates a neumorphic design effect
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
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFFA3B1C6).withOpacity(0.4),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// NeumorphicTextField - A custom text field with neumorphic styling
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
        style: const TextStyle(
          color: textColor,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: textColor.withOpacity(0.5),
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            prefixIcon,
            color: textColor.withOpacity(0.6),
          ),
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(
                    suffixIcon,
                    color: textColor.withOpacity(0.6),
                  ),
                  onPressed: onSuffixPressed,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }
}

/// NeumorphicButton - A custom elevated button with neumorphic styling
class NeumorphicButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const NeumorphicButton({
    super.key,
    this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3B6CFF);
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: child,
      ),
    );
  }
}
