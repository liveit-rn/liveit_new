import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_login_button.dart';

@RoutePage()
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final Logger logger = Logger();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim();

      logger.i('📱 UI: Register button pressed');
      logger.d('📋 UI: Email: $email, Has name: ${name != null}');

      context.read<AuthBloc>().add(
        AuthRegisterRequested(email: email, password: password, name: name),
      );
    } else {
      logger.w('⚠️ UI: Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          logger.i('📱 UI: BLoC state changed to ${state.runtimeType}');

          if (state is AuthError) {
            logger.e('📱 UI: Showing error to user: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            logger.i('📱 UI: User authenticated successfully');
            logger.d('📋 UI: User needs username: ${state.user.needsUsername}');
            // Check if user needs username
            if (state.user.needsUsername) {
              logger.i('📱 UI: Navigating to claim username page');
              context.router.pushPath('/claim-username');
            } else {
              logger.i('📱 UI: Navigating to home page');
              context.router.pushPath('/home');
            }
          } else if (state is AuthLoading) {
            logger.i('📱 UI: Auth loading state');
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Header
                  Text(
                    'Mulai Perjalanan Iman',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buat akun untuk membangun kebiasaan rohani yang konsisten',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Name Field (Optional)
                  AuthTextField(
                    label: 'Nama (opsional)',
                    hintText: 'Masukkan nama lengkap',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  AuthTextField(
                    label: 'Email',
                    hintText: 'Masukkan alamat email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email harus diisi';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  AuthTextField(
                    label: 'Kata Sandi',
                    hintText: 'Minimal 8 karakter',
                    controller: _passwordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kata sandi harus diisi';
                      }
                      if (value.length < 8) {
                        return 'Kata sandi minimal 8 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  AuthTextField(
                    label: 'Konfirmasi Kata Sandi',
                    hintText: 'Ulangi kata sandi',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi kata sandi harus diisi';
                      }
                      if (value != _passwordController.text) {
                        return 'Kata sandi tidak sama';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return AuthButton(
                        text: 'Daftar',
                        onPressed: _register,
                        isLoading: state is AuthLoading,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: theme.colorScheme.outline),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'atau',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social Login Buttons (Disabled for now)
                  SocialLoginButton(
                    text: 'Lanjutkan dengan Google',
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    onPressed: null, // TODO: Implement when OAuth is ready
                  ),

                  const SizedBox(height: 16),

                  SocialLoginButton(
                    text: 'Lanjutkan dengan Apple',
                    icon: const Icon(Icons.apple, size: 24),
                    onPressed: null, // TODO: Implement when OAuth is ready
                  ),

                  const SizedBox(height: 32),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.router.pushPath('/'),
                        child: Text(
                          'Masuk di sini',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
