import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/api/api_error.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_google_fonts.dart';
import '../../core/widgets/brand_app_bar.dart';
import 'donate_screen.dart';

/// Verifies a Razorpay donation after Safari / deep-link return.
class DonateVerifyDeepLinkScreen extends ConsumerStatefulWidget {
  const DonateVerifyDeepLinkScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<DonateVerifyDeepLinkScreen> createState() =>
      _DonateVerifyDeepLinkScreenState();
}

class _DonateVerifyDeepLinkScreenState
    extends ConsumerState<DonateVerifyDeepLinkScreen> {
  bool _loading = true;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    final copy = ref.read(appCopyProvider);
    try {
      final result = await ref.read(radioudaanApiProvider).verifyDonation(
            razorpayOrderId: widget.orderId,
          );
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _loading = false;
          _success = true;
          _message = copy.donateSuccessMessage;
        });
        announce(
          context,
          '${copy.donateSuccessTitle}. ${copy.donateSuccessMessage}',
        );
      } else {
        setState(() {
          _loading = false;
          _success = false;
          _message = copy.donateFailedMessage;
        });
        announceValidationError(context, copy.donateFailedMessage);
      }
    } on ApiError catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = false;
        _message = error.message;
      });
      announceValidationError(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = false;
        _message = copy.donateFailedMessage;
      });
      announceValidationError(context, copy.donateFailedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final palette = context.udaan;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BrandAppBar(title: copy.donateUs),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Text(
                  copy.donateCheckPayment,
                  textAlign: TextAlign.center,
                  style: udaanGoogleFont(
                    context,
                    fontSize: 16,
                    color: palette.onSurfaceVariant,
                  ),
                ),
              ] else if (_message != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _message!,
                    style: udaanGoogleFont(
                      context,
                      fontSize: 18,
                      color: _success ? palette.primary : palette.error,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const DonateScreen(),
                    ),
                  );
                },
                child: Text(copy.donateUs),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(copy.backButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
