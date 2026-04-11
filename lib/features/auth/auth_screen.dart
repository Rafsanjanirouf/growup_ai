import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/bottom_action_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/voice_guide_provider.dart';
import '../../shared/widgets/premium_dialog.dart';
import '../../shared/widgets/voice_guide_toggle.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLogin = true;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    
    // Trigger AI Voice Guide with specific script
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceGuideProvider.notifier).speak(
        "Signup now and start journey. You can login with google or email. Also see terms & condition and we are not using your data for illegal activity."
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _handleAuth() async {
    // 1. Terms Validation
    if (!_agreedToTerms) {
      PremiumDialog.show(
        context: context,
        title: "Action Required",
        message: "Please agree to our terms and privacy policy to proceed with your journey.",
        icon: Icons.gavel_rounded,
      );
      return;
    }

    // 2. Name Validation (Sign up only)
    if (!_isLogin && _nameController.text.isEmpty) {
      PremiumDialog.show(
        context: context,
        title: "Name Missing",
        message: "Please enter your name so we can personalize your transformation experience.",
        icon: Icons.person_outline,
      );
      return;
    }

    // 3. Email Validation
    if (_emailController.text.isEmpty) {
      PremiumDialog.show(
        context: context,
        title: "Email Required",
        message: "Please enter your email address to secure your account.",
        icon: Icons.alternate_email,
      );
      return;
    }

    if (!_emailController.text.contains('@')) {
      PremiumDialog.show(
        context: context,
        title: "Invalid Email",
        message: "Please provide a valid email address.",
        icon: Icons.error_outline,
      );
      return;
    }

    // 4. Password Validation
    if (_passwordController.text.isEmpty) {
      PremiumDialog.show(
        context: context,
        title: "Password Missing",
        message: "Your account needs a password to stay safe.",
        icon: Icons.lock_outline,
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      PremiumDialog.show(
        context: context,
        title: "Week Password",
        message: "Password must be at least 6 characters long for security purposes.",
        icon: Icons.security,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text.isEmpty ? 'Glower' : _nameController.text);
      await prefs.setBool('isOnboardingComplete', true);
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/goals');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleSignIn() async {
    if (!_agreedToTerms) {
      PremiumDialog.show(
        context: context,
        title: "Action Required",
        message: "Please agree to our terms and privacy policy before signing in with Google.",
        icon: Icons.gavel_rounded,
      );
      return;
    }
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingComplete', true);
    
    if (mounted) Navigator.of(context).pushReplacementNamed('/goals');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/image/avater_image.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
              ),
            ),
            
            // Blur & Gradient
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Header Section
                    _buildHeader(),
                    
                    const SizedBox(height: 40),
                    
                    // Main Glass Card
                    _buildMainCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Social Sign In
                    _buildSocialSection(),
                    
                    const SizedBox(height: 140), // Bottom space with 10px gap
                  ],
                ),
              ),
            ),

            // Bottom Action Button
            BottomActionButton(
              label: _isLoading ? 'PROCESSING...' : (_isLogin ? 'SIGN IN' : 'CREATE ACCOUNT'),
              icon: _isLogin ? Icons.login : Icons.person_add,
              isPulsing: !_isLoading,
              isLoading: _isLoading,
              onTap: _handleAuth,
            ),

            // Global Voice Toggle
            const VoiceGuideToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.kineticGradient.createShader(bounds),
          child: Text(
            _isLogin ? 'WELCOME BACK' : 'JOIN THE COMMUNITY',
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Your journey to perfection continues.' : 'Start your transformation odyssey today.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                // Toggle
                _buildToggle(),
                const SizedBox(height: 32),
                
                // Form Fields
                if (!_isLogin) ...[
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        PremiumDialog.show(
                          context: context,
                          title: "Reset Password",
                          message: "A password reset link has been sent to your email address.",
                          icon: Icons.mark_email_read_outlined,
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Terms Checkbox
                _buildTermsCheckbox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(true, 'Sign In'),
          ),
          Expanded(
            child: _toggleButton(false, 'Sign Up'),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(bool isLogin, String label) {
    bool active = _isLogin == isLogin;
    return GestureDetector(
      onTap: () {
        if (!active) _toggleAuthMode();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: active ? AppColors.kineticGradient : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelLarge.copyWith(
            color: active ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.7)),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return InkWell(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: _agreedToTerms,
              onChanged: (val) => setState(() => _agreedToTerms = val!),
              activeColor: AppColors.primary,
              checkColor: Colors.black,
              side: const BorderSide(color: Colors.white38),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR CONTINUE WITH', style: AppTypography.eyebrow.copyWith(color: Colors.white38)),
            ),
            const Expanded(child: Divider(color: Colors.white12)),
          ],
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.g_mobiledata, color: Colors.white, size: 32),
                const SizedBox(width: 8),
                Text(
                  'Continue with Google',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
