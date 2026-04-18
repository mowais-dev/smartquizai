import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/glass_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authService = sl<AuthService>();
    if (authService.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await sl<AuthService>().signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await sl<AuthService>().signInWithGoogle();
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: GradientBackground(
        gradient: AppGradients.deepPurpleToBlue,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: AppLogo(size: 44, borderRadius: 14),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Log in to continue and access your AI quiz dashboard.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppPalette.textSecondary,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 22),
                        AppTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.trim().length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        AppButton(
                          text: 'Login',
                          icon: Icons.login,
                          isLoading: _isLoading,
                          onPressed: _login,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppPalette.textPrimary,
                            side: BorderSide(color: Colors.white.withOpacity(0.18)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: const Icon(Icons.login),
                          label: const Text('Continue with Google'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppPalette.textSecondary),
                            ),
                            TextButton(
                              onPressed: () => context.go('/signup'),
                              child: const Text('Sign Up'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
