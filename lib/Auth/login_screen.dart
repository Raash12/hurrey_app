import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hurrey_app/pages/dashboard_screen.dart';

/// AuthWrapper - Kani waa logic-ga Facebook camal u shaqaynaya.
/// Wuxuu hubinayaa haddii qofku login yahay wuxuu u gudbinayaa Dashboard,
/// haddii kalena wuxuu tusayaa LoginScreenModern.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Haddii ay Firebase weli hubinayso xogta, loading ha tuso
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
            ),
          );
        }

        // Haddii uu qofku horey u login-gaday, toos ha ugu gudbo Dashboard-ka
        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        // Haddii kale (ama uu logout yiri), ha loo muujiyo Login Screen-ka
        return const LoginScreenModern();
      },
    );
  }
}

/// LoginScreenModern - Matching Dashboard Design
class LoginScreenModern extends StatefulWidget {
  const LoginScreenModern({super.key});

  @override
  State<LoginScreenModern> createState() => _LoginScreenModernState();
}

class _LoginScreenModernState extends State<LoginScreenModern>
    with SingleTickerProviderStateMixin {
  // ==================== COLORS (Matching Dashboard) ====================
  static const primaryColor = Color(0xFF6C63FF);
  static const secondaryColor = Color(0xFF4CAF50);
  static const gradientStart = Color(0xFF6C63FF);
  static const gradientEnd = Color(0xFF4CAF50);
  static const lightBgColor = Color(0xFFF8F9FE);
  static const textColor = Color(0xFF1A1A2E);

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
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;

      // Halkan waxaan u bedelay pushedReplacement una racyey AuthWrapper
      // si uu u maareeyo state-ka marka uu guuleysto login-ku.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCloseIcon: true,
        closeIconColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: lightBgColor,
      body: Stack(
        children: [
          // Background Gradient (Matching Dashboard Style)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.05),
                  secondaryColor.withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Decorative Circles (Matching Dashboard Aesthetic)
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    secondaryColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    secondaryColor.withOpacity(0.1),
                    primaryColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: outerHPad,
                    vertical: 24,
                  ),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo + Headings
                          Column(
                            children: [
                              // Logo Container with Gradient Border (Matching Dashboard)
                              Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [gradientStart, gradientEnd],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    cornerRadius,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      cornerRadius - 4,
                                    ),
                                    child: Image.asset(
                                      'image/Logo.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, _, __) =>
                                          Container(
                                            color: Colors.white,
                                            child: const Icon(
                                              Icons.account_circle,
                                              color: primaryColor,
                                              size: 40,
                                            ),
                                          ),
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

                          // Card with Form (Matching Dashboard Card Style)
                          Container(
                            padding: EdgeInsets.all(
                              (22 * scale).clamp(18, 26).toDouble(),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Login Title with Icon
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              gradientStart,
                                              gradientEnd,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.login_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Login",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: sectionTitleSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: gapMed),

                                  // Email Field
                                  _buildTextField(
                                    controller: _emailController,
                                    hintText: "Email Address",
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    height: fieldHeight,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return "Please enter your email";
                                      }
                                      final ok = RegExp(
                                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                      ).hasMatch(v.trim());
                                      return ok
                                          ? null
                                          : "Please enter a valid email";
                                    },
                                  ),

                                  SizedBox(height: gapSmall),

                                  // Password Field
                                  _buildTextField(
                                    controller: _passwordController,
                                    hintText: "Password",
                                    icon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon: _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    onSuffixPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    height: fieldHeight,
                                    validator: (v) =>
                                        (v == null || v.length < 6)
                                        ? "Password must be at least 6 characters"
                                        : null,
                                  ),

                                  SizedBox(height: gapMed),

                                  // Sign In Button (Matching Dashboard Gradient)
                                  SizedBox(
                                    height: buttonHeight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [gradientStart, gradientEnd],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _signIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                        ),
                                        child: _loading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                "Sign In",
                                                style: TextStyle(
                                                  fontSize: (16 * scale)
                                                      .clamp(14, 18)
                                                      .toDouble(),
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: gapMed),

                          // Terms Text
                          Text(
                            "By continuing, you agree to our Terms of Service and Privacy Policy",
                            style: TextStyle(
                              fontSize: (11 * scale).clamp(10, 12).toDouble(),
                              color: textColor.withOpacity(0.4),
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

  // ==================== CUSTOM TEXT FIELD (Matching Dashboard Style) ====================
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixPressed,
    String? Function(String?)? validator,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: lightBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textColor.withOpacity(0.4), fontSize: 14),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          prefixIcon: Icon(
            icon,
            color: primaryColor.withOpacity(0.6),
            size: 22,
          ),
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(
                    suffixIcon,
                    color: primaryColor.withOpacity(0.6),
                    size: 22,
                  ),
                  onPressed: onSuffixPressed,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }
}
