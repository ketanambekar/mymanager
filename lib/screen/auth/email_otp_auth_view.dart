import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymanager/app/app_controller.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/services/backend_auth_service.dart';
import 'package:mymanager/theme/theme_tokens.dart';

class EmailOtpAuthView extends StatefulWidget {
  const EmailOtpAuthView({super.key});

  @override
  State<EmailOtpAuthView> createState() => _EmailOtpAuthViewState();
}

class _EmailOtpAuthViewState extends State<EmailOtpAuthView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpRequested = false;
  bool _isExistingUser = true;
  bool _keepMeLoggedIn = true;
  String? _dummyOtp;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Please enter a valid email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await BackendAuthService.requestEmailOtp(
        email: email,
        name: name.isEmpty ? null : name,
      );

      setState(() {
        _otpRequested = true;
        _isExistingUser = data['is_existing_user'] == true;
        _dummyOtp = data['otp']?.toString();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    final name = _nameController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() {
        _error = 'Please enter the 6-digit OTP.';
      });
      return;
    }

    if (!_isExistingUser && name.isEmpty) {
      setState(() {
        _error = 'Please enter your name to complete registration.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await BackendAuthService.verifyEmailOtp(
        email: email,
        otp: otp,
        name: name.isEmpty ? null : name,
        keepMeLoggedIn: _keepMeLoggedIn,
      );

      if (Get.isRegistered<AppController>()) {
        await Get.find<AppController>().checkUser();
      }

      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.appBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0B1020), Color(0xFF101A2D)]
                : const [Color(0xFFF6FAFF), Color(0xFFF0F5FF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 920;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 1080 : 480),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.panel.withValues(alpha: isDark ? 0.93 : 0.97),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: context.border.withValues(alpha: 0.65)),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withValues(alpha: isDark ? 0.34 : 0.12),
                            blurRadius: 34,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: wide
                          ? Row(
                              children: [
                                Expanded(child: _brandPanel(context)),
                                Expanded(child: _formPanel(context)),
                              ],
                            )
                          : _formPanel(context, showBrandHeader: true),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _brandPanel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentBlend = Color.lerp(cs.primary, cs.tertiary, 0.35) ?? cs.primary;

    return Container(
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, accentBlend],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            'MyManager',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Secure email OTP access for your project workspace.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          _featureChip('No passwords to remember'),
          const SizedBox(height: 8),
          _featureChip('Fast sign in and registration'),
          const SizedBox(height: 8),
          _featureChip('One-time code verification'),
        ],
      ),
    );
  }

  Widget _featureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formPanel(BuildContext context, {bool showBrandHeader = false}) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBrandHeader) ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'MyManager',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.title,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Welcome back',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.title,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in or create an account using email OTP.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: context.subtitle,
            ),
          ),
          const SizedBox(height: 22),
          _labeledField(
            context: context,
            label: 'Email Address',
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'you@company.com',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _labeledField(
            context: context,
            label: _isExistingUser ? 'Display Name (Optional)' : 'Display Name (Required)',
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Your name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _keepMeLoggedIn,
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Keep me logged in',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.title,
              ),
            ),
            subtitle: Text(
              'If disabled, you will be asked to sign in again after app restart.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: context.subtitle,
              ),
            ),
            onChanged: _isLoading
                ? null
                : (v) {
                    setState(() {
                      _keepMeLoggedIn = v ?? true;
                    });
                  },
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _requestOtp,
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: Text(_isLoading ? 'Please wait...' : 'Send OTP'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_otpRequested) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.tertiary.withValues(alpha: 0.5)),
              ),
              child: Text(
                'Dummy OTP: ${_dummyOtp ?? '------'}\n(Development only)',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: cs.onTertiaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _labeledField(
              context: context,
              label: 'Verification Code',
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: 'Enter 6-digit OTP',
                  counterText: '',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: cs.secondary,
                  foregroundColor: cs.onSecondary,
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                child: Text(_isLoading ? 'Verifying...' : 'Verify & Continue'),
              ),
            ),
          ],
          if ((_error ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.error.withValues(alpha: 0.5)),
              ),
              child: Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _labeledField({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: context.subtitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}
