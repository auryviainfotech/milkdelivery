import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';

/// OTP verification screen
class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        return true;
      }
      return false;
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _handleVerify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Verifying OTP: $_otp for phone: ${widget.phoneNumber}'); // Debug log
      
      // TEST BYPASS: Accept 123456 for test phone number
      if (widget.phoneNumber == '+919876543210' && _otp == '123456') {
        print('TEST MODE: Bypassing Supabase OTP verification');
        if (mounted) {
          setState(() => _isLoading = false);
          // In test mode, we just check if any user is logged in
          final userId = SupabaseService.currentUser?.id;
          if (userId != null) {
            final exists = await UserRepository.profileExists(userId);
            if (mounted) {
              if (exists) {
                context.go('/dashboard');
              } else {
                context.go('/complete-profile');
              }
            }
          } else {
            // For pure testing with no supabase session, just go to dashboard
            context.go('/dashboard');
          }
        }
        return;
      }
      
      await SupabaseService.verifyOTP(
        phone: widget.phoneNumber,
        token: _otp,
      );
      print('OTP verified successfully'); // Debug log

      if (mounted) {
        setState(() => _isLoading = false);
        
        // CHECK IF PROFILE EXISTS
        final userId = SupabaseService.currentUser?.id;
        if (userId != null) {
          final exists = await UserRepository.profileExists(userId);
          if (mounted) {
            if (exists) {
              context.go('/dashboard');
            } else {
              context.go('/complete-profile');
            }
          }
        }
      }
    } catch (e) {
      print('OTP verification error: $e'); // Debug log
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP: ${e.toString()}')),
        );
      }
    }
  }

  void _handleResend() async {
    if (_resendTimer > 0) return;

    try {
      await SupabaseService.signInWithPhone(widget.phoneNumber);
      setState(() => _resendTimer = 30);
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend OTP: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Title
              Text(
                'Verify OTP',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n${widget.phoneNumber}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // OTP input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: theme.textTheme.headlineSmall,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        // Auto verify when complete
                        if (_otp.length == 6) {
                          _handleVerify();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Verify button
              FilledButton(
                onPressed: _isLoading ? null : _handleVerify,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: 24),

              // Resend OTP
              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Resend OTP in ${_resendTimer}s',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : TextButton(
                        onPressed: _handleResend,
                        child: const Text('Resend OTP'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
