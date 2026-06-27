import 'package:flutter/material.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/accessibility_scope.dart';
import '../../../core/theme/udaan_text_styles.dart';
import '../../auth/widgets/udaan_auth_widgets.dart';

/// Prominent submit-error banner shown at the top of the registration form.
class RegistrationErrorBanner extends StatelessWidget {
  const RegistrationErrorBanner({
    required this.copy,
    required this.message,
    super.key,
  });

  final AppCopy copy;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;

    return Semantics(
      liveRegion: true,
      label: '${copy.registrationErrorTitle}. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          border: Border.all(color: palette.error.withValues(alpha: 0.65)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: palette.error, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.registrationErrorTitle,
                      style: udaanTextStyle(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.onBackground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: udaanTextStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: palette.onBackground,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen success state after a registration is accepted.
class RegistrationSuccessView extends StatelessWidget {
  const RegistrationSuccessView({
    required this.copy,
    required this.eventTitle,
    required this.entryId,
    required this.onBack,
    super.key,
  });

  final AppCopy copy;
  final String eventTitle;
  final int entryId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    final reference = copy.registrationSuccessReference(entryId);
    final body = copy.registrationSuccessBody(eventTitle);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BrandTokens.screenPadding,
        24,
        BrandTokens.screenPadding,
        32,
      ),
      children: [
        Semantics(
          liveRegion: true,
          label:
              '${copy.registrationSuccessTitle}. $body $reference',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: palette.secondary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.secondary.withValues(alpha: 0.55),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 52,
                      color: palette.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ExcludeSemantics(
                child: Text(
                  copy.registrationSuccessTitle,
                  textAlign: TextAlign.center,
                  style: udaanTextStyle(
                    context,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: palette.onBackground,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: udaanTextStyle(
                    context,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: palette.primaryGlow,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ExcludeSemantics(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceContainer,
                    borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                    border: Border.all(color: palette.outlineVariant),
                  ),
                  child: Text(
                    reference,
                    textAlign: TextAlign.center,
                    style: udaanTextStyle(
                      context,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: palette.onBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        UdaanPrimaryButton(
          label: copy.registrationSuccessBack,
          icon: Icons.event_outlined,
          onPressed: onBack,
        ),
      ],
    );
  }
}
