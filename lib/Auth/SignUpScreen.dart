import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hurrey_app/pages/customer_list_page.dart';
import 'package:hurrey_app/pages/dashboard_screen.dart';

/// SignUpScreen - Responsive (like login)
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Theme (match login)
  static const Color backgroundColor = Color(0xFFE6E9EF);
  static const Color primaryColor = Color(0xFF3B6CFF);
  static const Color textColor = Color(0xFF3D3D3D);

  // Form + state
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  // Firebase
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  static const String _collectionName = 'users';

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-null', message: 'User not found');
      }

      await user.updateDisplayName(_nameController.text.trim());

      await _db.collection(_collectionName).doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'User',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

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
    // Responsive sizing (same pattern as login)
    final size = MediaQuery.of(context).size;
    final w = size.width;

    final double scale = (w / 375.0).clamp(0.85, 1.15).toDouble();
    final double outerHPad = (w < 400 ? 20.0 : 24.0);
    final double contentWidth = (w - outerHPad * 2).clamp(300, 380).toDouble();

    final double logoSize = (84 * scale).clamp(68, 110).toDouble();
    final double titleSize = (24 * scale).clamp(20, 26).toDouble();
    final double subTitleSize = (14 * scale).clamp(12, 15).toDouble();
    final double sectionTitleSize = (20 * scale).clamp(18, 22).toDouble();

    final double fieldHeight = (50 * scale).clamp(44, 56).toDouble();
    final double buttonHeight = (50 * scale).clamp(46, 56).toDouble();
    final double gapLarge = (28 * scale).clamp(20, 32).toDouble();
    final double gapMed = (18 * scale).clamp(14, 22).toDouble();
    final double gapSmall = (12 * scale).clamp(8, 14).toDouble();
    final double cornerRadius = (20 * scale).clamp(14, 24).toDouble();
    final EdgeInsets cardPadding = EdgeInsets.all((22 * scale).clamp(18, 26).toDouble());

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background gradient (match login)
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
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: outerHPad, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top: icon in a neumorphic square (acts like logo)
                      NeumorphicContainer(
                        width: logoSize,
                        height: logoSize,
                        borderRadius: BorderRadius.circular(cornerRadius),
                        child: const Icon(Icons.person_add, color: primaryColor, size: 40),
                      ),
                      SizedBox(height: gapMed),

                      // Headings
                      Text(
                        "Create New User",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: (6 * scale).clamp(4, 8).toDouble()),
                      Text(
                        "Fill in the user details below",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: subTitleSize,
                        ),
                      ),

                      SizedBox(height: gapLarge),

                      // Card with form
                      NeumorphicContainer(
                        padding: cardPadding,
                        borderRadius: BorderRadius.circular(cornerRadius),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Sign Up",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: sectionTitleSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: gapMed),

                              // Name
                              NeumorphicTextField(
                                controller: _nameController,
                                hintText: "Full Name",
                                prefixIcon: Icons.person_outline,
                                height: fieldHeight,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? "Enter full name"
                                    : null,
                              ),
                              SizedBox(height: gapSmall),

                              // Email
                              NeumorphicTextField(
                                controller: _emailController,
                                hintText: "Email Address",
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                height: fieldHeight,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Enter email";
                                  }
                                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(v.trim())) {
                                    return "Enter valid email";
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: gapSmall),

                              // Password
                              NeumorphicTextField(
                                controller: _passwordController,
                                hintText: "Password",
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                onSuffixPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                                height: fieldHeight,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return "Enter password";
                                  if (v.length < 6) return "At least 6 characters";
                                  return null;
                                },
                              ),

                              if (_error != null) ...[
                                SizedBox(height: (16 * scale).clamp(12, 18).toDouble()),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: (14 * scale).clamp(12, 16).toDouble(),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],

                              SizedBox(height: gapMed),

                              // Create button
                              SizedBox(
                                height: buttonHeight,
                                child: NeumorphicButton(
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
                                      : Text(
                                          "Create User",
                                          style: TextStyle(
                                            fontSize: (16 * scale).clamp(14, 18).toDouble(),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: gapMed),

                      Text(
                        "User will be added to the system with default permissions",
                        style: TextStyle(
                          fontSize: (12 * scale).clamp(11, 13).toDouble(),
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

          if (_loading)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withOpacity(0.08),
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

/// ---------------- Neumorphic widgets (updated to support fixed height) ----------------

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
          ),
          BoxShadow(
            color: const Color(0xFFA3B1C6).withOpacity(0.4),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
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

  /// Added: fixed height for responsive control sizing
  final double height;

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
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF3D3D3D);

    return NeumorphicContainer(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            prefixIcon: Icon(prefixIcon, color: textColor.withOpacity(0.6)),
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, color: textColor.withOpacity(0.6)),
                    onPressed: onSuffixPressed,
                  )
                : null,
          ),
          validator: validator,
        ),
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
    const primaryColor = Color(0xFF3B6CFF);

    return Container(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: child,
      ),
    );
  }
}
