import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/accessibility/udaan_semantics.dart';
import '../../../core/api/api_error.dart';
import '../../../core/config/info_hub_config.dart';
import '../../../core/models/auth_session.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/accessibility_scope.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_google_fonts.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../auth/widgets/udaan_auth_widgets.dart';
import '../donate_razorpay_service.dart';

/// Razorpay pay-online card on the Donate screen (presets, 80G, checkout).
class DonatePayOnlineCard extends ConsumerStatefulWidget {
  const DonatePayOnlineCard({
    required this.copy,
    required this.razorpay,
    super.key,
  });

  final AppCopy copy;
  final RazorpayDonateConfig razorpay;

  @override
  ConsumerState<DonatePayOnlineCard> createState() =>
      _DonatePayOnlineCardState();
}

class _DonatePayOnlineCardState extends ConsumerState<DonatePayOnlineCard>
    with WidgetsBindingObserver {
  final _customAmountController = TextEditingController();
  final _customAmountFocus = FocusNode();
  final _panController = TextEditingController();
  final _panFocus = FocusNode();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  final _amountAnchorKey = GlobalKey();
  final _panAnchorKey = GlobalKey();
  final _emailAnchorKey = GlobalKey();

  int? _selectedPreset;
  bool _want80g = false;
  bool _loading = false;
  bool _awaitingIosVerify = false;
  bool _autoVerifyInFlight = false;
  String? _errorMessage;
  String? _successMessage;
  String? _statusMessage;
  String? _lastAnnouncedAmount;
  DonateRazorpayService? _checkout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final presets = widget.razorpay.presetAmounts;
    if (presets.isNotEmpty) {
      _selectedPreset = presets.first;
      _lastAnnouncedAmount = presets.first.toString();
    }
    _customAmountController.addListener(_onAmountEdited);
  }

  void _onAmountEdited() {
    if (!mounted) return;
    setState(() {});
    final amount = _amountRupeesLabel();
    if (amount == null || amount == _lastAnnouncedAmount) return;
    // Custom field drives amount — announce only when value changes.
    if (_customAmountController.text.trim().isEmpty) return;
    _lastAnnouncedAmount = amount;
    final message = widget.copy.donateCustomAmountSelected
        .replaceAll('{amount}', amount);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      announce(context, message);
    });
  }

  void _selectPreset(int amount) {
    setState(() {
      _selectedPreset = amount;
      _lastAnnouncedAmount = '$amount';
      _customAmountController.clear();
      _errorMessage = null;
      _successMessage = null;
    });
    announce(
      context,
      widget.copy.donateAmountChipSemantics.replaceAll('{amount}', '$amount'),
    );
  }

  DonateRazorpayService _service() {
    return _checkout ??= DonateRazorpayService(
      api: ref.read(radioudaanApiProvider),
      copy: widget.copy,
    )
      ..onSuccess = _onPaymentSuccess
      ..onFailure = _onPaymentFailure;
  }

  bool get _usesPaymentLink {
    if (kIsWeb) return false; // Web preview uses general copy, not Safari handoff.
    try {
      return Platform.isIOS;
    } catch (_) {
      return defaultTargetPlatform == TargetPlatform.iOS;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _customAmountController.removeListener(_onAmountEdited);
    _customAmountController.dispose();
    _customAmountFocus.dispose();
    _panController.dispose();
    _panFocus.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    _checkout?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_autoConfirmAfterReturn());
    }
  }

  /// iOS: after Safari, confirm payment automatically (no manual button).
  Future<void> _autoConfirmAfterReturn() async {
    if (!_awaitingIosVerify || _autoVerifyInFlight || _loading) return;
    if (_service().pendingOrderId == null) return;

    _autoVerifyInFlight = true;
    if (mounted) {
      setState(() {
        _statusMessage = widget.copy.donateIosConfirming;
        _errorMessage = null;
      });
      announce(context, widget.copy.donateIosConfirming);
    }

    final confirmed = await _service().pollConfirmPendingPayment();
    _autoVerifyInFlight = false;
    if (!mounted) return;

    if (!confirmed && _awaitingIosVerify) {
      setState(() {
        _statusMessage = widget.copy.donateIosWaiting;
        _loading = false;
      });
    }
  }

  void _onPaymentSuccess(_) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _awaitingIosVerify = false;
      _statusMessage = null;
      _errorMessage = null;
      _successMessage = widget.copy.donateSuccessMessage;
    });
    announce(
      context,
      '${widget.copy.donateSuccessTitle}. ${widget.copy.donateSuccessMessage}',
    );
  }

  void _onPaymentFailure(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorMessage = message;
      _successMessage = null;
    });
    announceValidationError(context, message);
  }

  AuthSession? get _session => ref.read(authUserProvider);

  int? _resolveAmountPaise() {
    final customPaise = parseDonationAmountPaise(_customAmountController.text);
    if (customPaise != null) return customPaise;
    final preset = _selectedPreset;
    if (preset != null && preset > 0) return preset * 100;
    return null;
  }

  String? _amountRupeesLabel() {
    final paise = _resolveAmountPaise();
    if (paise == null) return null;
    final rupees = paise / 100;
    if (rupees == rupees.roundToDouble()) {
      return rupees.toInt().toString();
    }
    return rupees.toStringAsFixed(2);
  }

  String get _selectedSummary {
    final amount = _amountRupeesLabel();
    if (amount == null) return '';
    return widget.copy.donateSelectedSummary.replaceAll('{amount}', amount);
  }

  String get _sectionSubtitle {
    if (_usesPaymentLink) {
      return widget.copy.donatePayOnlineSubtitleIos;
    }
    return widget.copy.donatePayOnlineSubtitle;
  }

  String get _headerSemanticsLabel =>
      '${widget.copy.donatePayOnlineTitle}. $_sectionSubtitle';

  bool _validateInputs() {
    final amountPaise = _resolveAmountPaise();
    if (amountPaise == null || amountPaise < 100) {
      _showError(
        widget.copy.donateInvalidAmount,
        anchorKey: _amountAnchorKey,
        focusNode: _customAmountFocus,
      );
      return false;
    }

    if (_want80g && widget.razorpay.eightyGEnabled) {
      if (!isValidPan(_panController.text)) {
        _showError(
          widget.copy.donatePanRequired,
          anchorKey: _panAnchorKey,
          focusNode: _panFocus,
        );
        return false;
      }
      final email = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : (_session?.email?.trim() ?? '');
      if (widget.razorpay.eightyGPdfEmailEnabled && email.isEmpty) {
        _showError(
          widget.copy.emailInvalid,
          anchorKey: _emailAnchorKey,
          focusNode: _emailFocus,
        );
        return false;
      }
    }
    return true;
  }

  void _showError(
    String message, {
    GlobalKey? anchorKey,
    FocusNode? focusNode,
  }) {
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });
    announceValidationError(context, message);
    revealFieldForValidation(
      context,
      anchorKey: anchorKey,
      focusNode: focusNode,
    );
  }

  Future<void> _donate() async {
    dismissKeyboard(context);
    if (!_validateInputs()) return;

    final amountPaise = _resolveAmountPaise()!;
    final amountLabel = _amountRupeesLabel() ?? '';
    final session = _session;
    final want80g = _want80g && widget.razorpay.eightyGEnabled;
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (session?.email?.trim() ?? '');

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
      _statusMessage = null;
      _awaitingIosVerify = false;
    });
    announce(
      context,
      widget.copy.donateOpeningWithAmount.replaceAll('{amount}', amountLabel),
    );

    try {
      final order = await _service().createOrder(
        amountPaise: amountPaise,
        want80g: want80g,
        pan: want80g ? normalizePan(_panController.text) : '',
        name: session?.name?.trim() ?? '',
        email: email,
        phone: session?.phoneE164 ?? '',
      );
      if (!mounted) return;
      await _service().startCheckout(order);
      if (!mounted) return;
      if (_service().usesPaymentLink) {
        setState(() {
          _loading = false;
          _awaitingIosVerify = true;
          _statusMessage = widget.copy.donateIosWaiting;
        });
        announce(context, widget.copy.donateIosWaiting);
      }
    } on ApiError catch (error) {
      _onPaymentFailure(error.message);
    } catch (_) {
      _onPaymentFailure(widget.copy.donateFailedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    final presets = widget.razorpay.presetAmounts;
    final session = ref.watch(authUserProvider);
    if (_emailController.text.trim().isEmpty &&
        session?.email?.trim().isNotEmpty == true) {
      _emailController.text = session!.email!.trim();
    }
    final summary = _selectedSummary;
    final customEmpty = _customAmountController.text.trim().isEmpty;
    final accountEmail = session?.email?.trim() ?? '';
    final accountEmailHidden = accountEmail.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        border: Border.all(color: palette.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One spoken header (title + short how-to) — avoids reading every line.
          Semantics(
            header: true,
            label: _headerSemanticsLabel,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.copy.donatePayOnlineTitle,
                    style: udaanGoogleFont(
                      context,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sectionSubtitle,
                    style: udaanGoogleFont(
                      context,
                      fontSize: 15,
                      height: 1.45,
                      color: palette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (presets.isNotEmpty) ...[
            Semantics(
              header: true,
              label: widget.copy.donateAmountHeading,
              child: ExcludeSemantics(
                child: Text(
                  widget.copy.donateAmountHeading,
                  style: udaanGoogleFont(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.onBackground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _AmountPresetGrid(
              amounts: presets,
              selectedAmount:
                  customEmpty ? _selectedPreset : null,
              chipSemantics: widget.copy.donateAmountChipSemantics,
              enabled: !_loading,
              onSelect: _selectPreset,
            ),
            const SizedBox(height: 16),
          ],
          FormFieldAnchor(
            anchorKey: _amountAnchorKey,
            child: UdaanLabeledField(
              label: widget.copy.donateAmountCustomLabel,
              hint: widget.copy.donateAmountCustomHint,
              controller: _customAmountController,
              focusNode: _customAmountFocus,
              keyboardDoneLabel: widget.copy.keyboardDone,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onSubmitted: (_) => _donate(),
            ),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              label: summary,
              child: ExcludeSemantics(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: palette.primaryGlow.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism_outlined,
                        color: palette.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          summary,
                          style: udaanGoogleFont(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: palette.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (widget.razorpay.eightyGEnabled) ...[
            const SizedBox(height: 16),
            Semantics(
              checked: _want80g,
              label: widget.copy.donate80gCheckbox,
              hint: widget.copy.donate80gHint,
              enabled: !_loading,
              onTap: _loading
                  ? null
                  : () => setState(() => _want80g = !_want80g),
              child: ExcludeSemantics(
                child: Material(
                  color: palette.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _loading
                        ? null
                        : () => setState(() => _want80g = !_want80g),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: BrandTokens.a11yMinTapTarget,
                            height: BrandTokens.a11yMinTapTarget,
                            child: Checkbox(
                              value: _want80g,
                              onChanged: _loading
                                  ? null
                                  : (value) => setState(
                                        () => _want80g = value == true,
                                      ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                widget.copy.donate80gCheckbox,
                                style: udaanGoogleFont(
                                  context,
                                  fontSize: 16,
                                  height: 1.35,
                                  color: palette.onBackground,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_want80g) ...[
              const SizedBox(height: 12),
              FormFieldAnchor(
                anchorKey: _panAnchorKey,
                child: UdaanLabeledField(
                  label: widget.copy.donatePanLabel,
                  controller: _panController,
                  focusNode: _panFocus,
                  required: true,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.visiblePassword,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
              ),
              if (accountEmailHidden) ...[
                const SizedBox(height: 12),
                Semantics(
                  label: widget.copy.donateEmailFromAccount,
                  value: session!.email!.trim(),
                  child: ExcludeSemantics(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: palette.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.copy.emailLabel,
                                  style: udaanGoogleFont(
                                    context,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: palette.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  session.email!.trim(),
                                  style: udaanGoogleFont(
                                    context,
                                    fontSize: 16,
                                    color: palette.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                FormFieldAnchor(
                  anchorKey: _emailAnchorKey,
                  child: UdaanLabeledField(
                    label: widget.copy.emailLabel,
                    controller: _emailController,
                    focusNode: _emailFocus,
                    required: widget.razorpay.eightyGPdfEmailEnabled,
                    keyboardType: TextInputType.emailAddress,
                    hint: widget.copy.emailHint,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Semantics(
                label: widget.copy.donateForm10beNote,
                child: ExcludeSemantics(
                  child: Text(
                    widget.copy.donateForm10beNote,
                    style: udaanGoogleFont(
                      context,
                      fontSize: 14,
                      height: 1.4,
                      color: palette.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (_statusMessage != null) ...[
            const SizedBox(height: 14),
            _StatusBanner(
              message: _statusMessage!,
              tone: _StatusTone.info,
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _StatusBanner(
              message: _errorMessage!,
              tone: _StatusTone.error,
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 14),
            _StatusBanner(
              message: _successMessage!,
              tone: _StatusTone.success,
            ),
          ],
          const SizedBox(height: 18),
          UdaanPrimaryButton(
            label: widget.copy.donateNowButton,
            icon: Icons.payments_outlined,
            loading: _loading,
            semanticsLabel: _donateButtonSemantics,
            onPressed: _loading ? null : _donate,
          ),
        ],
      ),
    );
  }

  String get _donateButtonSemantics {
    if (_loading) return widget.copy.donateNowLoading;
    final amount = _amountRupeesLabel();
    if (amount == null) return widget.copy.donateNowButton;
    return widget.copy.donateNowWithAmount.replaceAll('{amount}', amount);
  }
}

enum _StatusTone { info, error, success }

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.tone,
  });

  final String message;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    final Color accent;
    final IconData icon;
    switch (tone) {
      case _StatusTone.error:
        accent = palette.error;
        icon = Icons.error_outline;
      case _StatusTone.success:
        accent = palette.primary;
        icon = Icons.check_circle_outline;
      case _StatusTone.info:
        accent = palette.primaryGlow;
        icon = Icons.info_outline;
    }

    return Semantics(
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.55)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: udaanGoogleFont(
                    context,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountPresetGrid extends StatelessWidget {
  const _AmountPresetGrid({
    required this.amounts,
    required this.selectedAmount,
    required this.chipSemantics,
    required this.onSelect,
    required this.enabled,
  });

  final List<int> amounts;
  final int? selectedAmount;
  final String chipSemantics;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final amount in amounts)
              SizedBox(
                width: tileWidth,
                child: _AmountChip(
                  amountRupees: amount,
                  semanticsLabel: chipSemantics.replaceAll(
                    '{amount}',
                    '$amount',
                  ),
                  selected: selectedAmount == amount,
                  enabled: enabled,
                  onTap: () => onSelect(amount),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.amountRupees,
    required this.semanticsLabel,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int amountRupees;
  final String semanticsLabel;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    final visual = '₹$amountRupees';
    final bg = selected
        ? palette.primary
        : palette.background;
    final border = selected ? palette.primary : palette.primaryGlow;
    final fg = selected ? palette.onPrimary : palette.onBackground;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticsLabel,
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: BrandTokens.a11yMinTapTarget,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: border,
                  width: selected ? 2.5 : 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_circle, size: 18, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      visual,
                      textAlign: TextAlign.center,
                      style: udaanGoogleFont(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
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
