import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/config/info_hub_config.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_google_fonts.dart';
import '../../core/widgets/brand_app_bar.dart';
import '../auth/widgets/udaan_auth_widgets.dart';

/// Donate screen: UPI QR + bank transfer details from WordPress config.
class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  void _announce(BuildContext context, String message) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  Future<void> _copyValue(BuildContext context, AppCopy copy, String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!context.mounted) return;
    _announce(context, copy.copiedToClipboard);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(copy.copiedToClipboard)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final donate = ref.watch(remoteConfigProvider)?.infoHub.donate ??
        const DonateConfig();
    final palette = context.udaan;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BrandAppBar(title: copy.donateUs),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          children: [
            if (donate.badge.trim().isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: palette.primary, width: 1.5),
                  ),
                  child: Text(
                    donate.badge,
                    style: udaanGoogleFont(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.onBackground,
                    ),
                  ),
                ),
              ),
            if (donate.badge.trim().isNotEmpty) const SizedBox(height: 16),
            if (donate.headline.trim().isNotEmpty)
              Semantics(
                header: true,
                child: Text(
                  donate.headline,
                  style: udaanGoogleFont(
                    context,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: palette.onBackground,
                  ),
                ),
              ),
            if (donate.intro.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                donate.intro,
                style: udaanGoogleFont(
                  context,
                  fontSize: 16,
                  height: 1.5,
                  color: palette.onSurfaceVariant,
                ),
              ),
            ],
            if (donate.accessibilityNote.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.surfaceContainer,
                  borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                  border: Border(
                    left: BorderSide(color: palette.primary, width: 4),
                  ),
                ),
                child: Text(
                  donate.accessibilityNote,
                  style: udaanGoogleFont(
                    context,
                    fontSize: 15,
                    height: 1.45,
                    color: palette.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 720;
                final qrCard = _ScanCard(
                  copy: copy,
                  donate: donate,
                  onCopyUpi: (value) => _copyValue(context, copy, value),
                );
                final bankCard = _BankCard(
                  copy: copy,
                  bank: donate.bank,
                  onCopy: (value) => _copyValue(context, copy, value),
                );
                if (sideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: qrCard),
                      const SizedBox(width: 16),
                      Expanded(child: bankCard),
                    ],
                  );
                }
                return Column(
                  children: [
                    qrCard,
                    const SizedBox(height: 16),
                    bankCard,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.copy,
    required this.donate,
    required this.onCopyUpi,
  });

  final AppCopy copy;
  final DonateConfig donate;
  final ValueChanged<String> onCopyUpi;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    final qrUrl = donate.qrImageUrl.trim();
    final upi = donate.upiId.trim();

    return _InfoCard(
      title: copy.donateScanTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (qrUrl.isNotEmpty)
            Semantics(
              label: '${copy.donateScanTitle}. ${copy.donateScanCaption}',
              image: true,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: qrUrl,
                  fit: BoxFit.contain,
                  height: 220,
                  memCacheHeight: 440,
                  placeholder: (_, __) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Text(
                    copy.linkUnavailable,
                    style: udaanGoogleFont(context, color: Colors.black87),
                  ),
                ),
              ),
            ),
          if (upi.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              copy.labelUpiId,
              style: udaanGoogleFont(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              upi,
              style: udaanGoogleFont(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            UdaanOutlineButton(
              label: copy.copyValue,
              icon: Icons.copy,
              onPressed: () => onCopyUpi(upi),
            ),
          ],
          if (qrUrl.isNotEmpty || upi.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              copy.donateScanCaption,
              style: udaanGoogleFont(
                context,
                fontSize: 14,
                height: 1.4,
                color: palette.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({
    required this.copy,
    required this.bank,
    required this.onCopy,
  });

  final AppCopy copy;
  final DonateBankConfig bank;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value})>[
      (label: copy.labelAccountName, value: bank.accountName),
      (label: copy.labelAccountNumber, value: bank.accountNumber),
      (label: copy.labelBankName, value: bank.bankName),
      (label: copy.labelBranchName, value: bank.branchName),
      (label: copy.labelIfsc, value: bank.ifsc),
      (label: copy.labelMicr, value: bank.micr),
      (label: copy.labelBankAddress, value: bank.address),
    ].where((row) => row.value.trim().isNotEmpty).toList();

    return _InfoCard(
      title: copy.donateBankDetailsTitle,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _BankFieldRow(
              label: rows[i].label,
              value: rows[i].value,
              highlight: i == 2,
              onCopy: () => onCopy(rows[i].value),
              copyLabel: copy.copyValue,
            ),
            if (i < rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        border: Border.all(color: palette.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: udaanGoogleFont(
                context,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: palette.onBackground,
              ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BankFieldRow extends StatelessWidget {
  const _BankFieldRow({
    required this.label,
    required this.value,
    required this.onCopy,
    required this.copyLabel,
    this.highlight = false,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final String copyLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: palette.primary, width: 1.5)
            : Border.all(color: palette.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: udaanGoogleFont(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: udaanGoogleFont(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.onBackground,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: '$copyLabel $label',
                child: IconButton(
                  constraints: const BoxConstraints(
                    minWidth: BrandTokens.a11yMinTapTarget,
                    minHeight: BrandTokens.a11yMinTapTarget,
                  ),
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
