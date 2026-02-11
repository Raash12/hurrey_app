import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:hurrey_app/pages/customer_list_page.dart';
import 'package:hurrey_app/pages/dashboard_screen.dart';

/// LoginScreenModern - responsive sizes for mobile (type-safe clamp + full file)
class LoginScreenModern extends StatefulWidget {
  const LoginScreenModern({super.key});

  @override
  State<LoginScreenModern> createState() => _LoginScreenModernState();
}

class _LoginScreenModernState extends State<LoginScreenModern>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  late final AnimationController _ac;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Login failed');
    } catch (_) {
      _showSnack('Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
    // Theme
    const backgroundColor = Color(0xFFE6E9EF);
    const primaryColor = Color(0xFF3B6CFF);
    const textColor = Color(0xFF3D3D3D);

    // --- Responsive sizing ---
    final size = MediaQuery.of(context).size;
    final w = size.width;

    final double scale = (w / 375.0).clamp(0.85, 1.15).toDouble();

    final double logoSize = (88 * scale).clamp(68, 110).toDouble();
    final double outerHPad = (w < 400 ? 20.0 : 24.0);
    final double contentWidth = (w - outerHPad * 2).clamp(300, 380).toDouble();

    final double titleSize = (24 * scale).clamp(20, 26).toDouble();
    final double subTitleSize = (14 * scale).clamp(12, 15).toDouble();
    final double sectionTitleSize = (20 * scale).clamp(18, 22).toDouble();

    final double fieldHeight = (50 * scale).clamp(44, 56).toDouble();
    final double buttonHeight = (50 * scale).clamp(46, 56).toDouble();
    final double gapLarge = (28 * scale).clamp(20, 32).toDouble();
    final double gapMed = (18 * scale).clamp(14, 22).toDouble();
    final double gapSmall = (12 * scale).clamp(8, 14).toDouble();

    final double cornerRadius = (20 * scale).clamp(14, 24).toDouble();
    final double spaceBelowLogo = (20 * scale).clamp(14, 24).toDouble();
    final double spaceBelowTitle = (6 * scale).clamp(4, 8).toDouble();
    final EdgeInsets cardPadding = EdgeInsets.all((22 * scale).clamp(18, 26).toDouble());

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE6E9EF), Color(0xFFD1D9E6)],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: outerHPad, vertical: 24),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo + headings
                          Column(
                            children: [
                              NeumorphicContainer(
                                width: logoSize,
                                height: logoSize,
                                borderRadius: BorderRadius.circular(cornerRadius),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(cornerRadius),
                                  child: Image.asset(
                                    'image/Logo.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) => const Icon(
                                      Icons.account_circle,
                                      color: primaryColor,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: spaceBelowLogo),
                              Text(
                                "Hurey App",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: spaceBelowTitle),
                              Text(
                                "Sign in to continue",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: subTitleSize,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: gapLarge),

                          // Card with form
                          NeumorphicContainer(
                            padding: cardPadding,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "Login",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: sectionTitleSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: gapMed),

                                  // Email
                                  NeumorphicTextField(
                                    controller: _emailController,
                                    hintText: "Email Address",
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    height: fieldHeight,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return "Please enter your email";
                                      }
                                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                          .hasMatch(v.trim());
                                      return ok ? null : "Please enter a valid email";
                                    },
                                  ),

                                  SizedBox(height: gapSmall),

                                  // Password
                                  NeumorphicTextField
                                  (
                                    controller: _passwordController,
                                    hintText: "Password",
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon:
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    onSuffixPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                    height: fieldHeight,
                                    validator: (v) =>
                                        (v == null || v.length < 6)
                                            ? "Password must be at least 6 characters"
                                            : null,
                                  ),

                                  SizedBox(height: gapMed),

                                  // Button (fixed, responsive height)
                                  SizedBox(
                                    height: buttonHeight,
                                    child: NeumorphicButton(
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
                                          : Text(
                                              "Sign In",
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
                            "By continuing, you agree to our Terms of Service and Privacy Policy",
                            style: TextStyle(
                              fontSize: (11 * scale).clamp(10, 12).toDouble(),
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
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- Neumorphic primitives ----------------

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

  /// Fixed height for responsive control sizing
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
