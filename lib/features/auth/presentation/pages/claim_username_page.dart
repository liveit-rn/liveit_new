import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

@RoutePage()
class ClaimUsernamePage extends StatefulWidget {
  const ClaimUsernamePage({super.key});

  @override
  State<ClaimUsernamePage> createState() => _ClaimUsernamePageState();
}

class _ClaimUsernamePageState extends State<ClaimUsernamePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _checkUsername(String username) {
    if (username.isNotEmpty && username.length >= 3) {
      setState(() => _isCheckingUsername = true);
      context.read<AuthBloc>().add(
        UsernameAvailabilityCheckRequested(username),
      );
    } else {
      setState(() {
        _isUsernameAvailable = false;
        _isCheckingUsername = false;
      });
    }
  }

  void _claimUsername() {
    if (_formKey.currentState!.validate() && _isUsernameAvailable) {
      context.read<AuthBloc>().add(
        UsernameClaimRequested(_usernameController.text.trim()),
      );
    }
  }

  Widget _buildUsernameStatusIcon() {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();

    if (_isCheckingUsername) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_usernameController.text.isNotEmpty &&
        _usernameController.text.length >= 3) {
      return Icon(
        _isUsernameAvailable ? Icons.check_circle : Icons.cancel,
        color: _isUsernameAvailable
            ? (semantic?.success ?? colorScheme.primary)
            : colorScheme.error,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
            setState(() => _isCheckingUsername = false);
          } else if (state is UsernameAvailable) {
            setState(() {
              _isUsernameAvailable = true;
              _isCheckingUsername = false;
            });
          } else if (state is UsernameUnavailable) {
            setState(() {
              _isUsernameAvailable = false;
              _isCheckingUsername = false;
            });
          } else if (state is UsernameClaimSuccess) {
            context.router.pushPath('/home');
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // Header
                  Text(
                    'Pilih Username Anda',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Username ini akan menjadi identitas unik Anda di LIVEIT. Pilih yang mudah diingat!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Username Field
                  AuthTextField(
                    label: 'Username',
                    hintText: 'contoh: john_doe',
                    controller: _usernameController,
                    suffixIcon: _buildUsernameStatusIcon(),
                    onChanged: (value) {
                      // Debounce username check
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (value == _usernameController.text) {
                          _checkUsername(value);
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username harus diisi';
                      }
                      if (value.length < 3) {
                        return 'Username minimal 3 karakter';
                      }
                      if (value.length > 20) {
                        return 'Username maksimal 20 karakter';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return 'Username hanya boleh mengandung huruf, angka, dan underscore';
                      }
                      if (!_isUsernameAvailable && !_isCheckingUsername) {
                        return 'Username tidak tersedia';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Username Rules
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aturan Username:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 3-20 karakter\n• Hanya huruf, angka, dan underscore (_)\n• Tidak boleh mengandung spasi\n• Harus unik',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Claim Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading =
                          state is UsernameClaimLoading ||
                          state is UsernameCheckLoading;
                      return AuthButton(
                        text: 'Lanjutkan',
                        onPressed: _isUsernameAvailable && !_isCheckingUsername
                            ? _claimUsername
                            : null,
                        isLoading: isLoading,
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
