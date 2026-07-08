import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/accessibility/udaan_semantics.dart';
import '../../../core/api/api_error.dart';
import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
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

class _DonatePayOnlineCardState extends ConsumerState<DonatePayOnlineCard> {
  final _customAmountController = TextEditingController();
  final _customAmountFocus = FocusNode();
  final _panController = TextEditingController();
  final _emailController = TextEditingController();

  int? _selectedPreset;
  bool _want80g = false;
  bool _loading = false;
  bool _awaitingIosVerify = false;
  String? _errorMessage;
  String? _successMessage;
  DonateRazorpayService? _checkout;

  @override
  void initState() {
    super.initState();
    final presets = widget.razorpay.presetAmounts;
    if (presets.isNotEmpty) {
      _selectedPreset = presets.first;
    }
  }

  DonateRazorpayService _service() {
    return _checkout ??= DonateRazorpayService(
      api: ref.read(radioudaanApiProvider),
      copy: widget.copy,
    )
      ..onSuccess = _onPaymentSuccess
      ..onFailure = _onPaymentFailure;
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _customAmountFocus.dispose();
    _panController.dispose();
    _emailController.dispose();
    _checkout?.dispose();
    super.dispose();
  }

  void _onPaymentSuccess(_) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _awaitingIosVerify = false;
      _errorMessage = null;
      _successMessage = widget.copy.donateSuccessMessage;
    });
    announce(context, '${widget.copy.donateSuccessTitle}. ${widget.copy.donateSuccessMessage}');
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

  bool _validateInputs() {
    final amountPaise = _resolveAmountPaise();
    if (amountPaise == null || amountPaise < 100) {
      _showError(widget.copy.donateInvalidAmount);
      return false;
    }

    if (_want80g && widget.razorpay.eightyGEnabled) {
      if (!isValidPan(_panController.text)) {
        _showError(widget.copy.donatePanRequired);
        return false;
      }
      final email = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : (_session?.email?.trim() ?? '');
      if (widget.razorpay.eightyGPdfEmailEnabled && email.isEmpty) {
        _showError(widget.copy.emailInvalid);
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });
    announceValidationError(context, message);
  }

  Future<void> _donate() async {
    dismissKeyboard(context);
    if (!_validateInputs()) return;

    final amountPaise = _resolveAmountPaise()!;
    final session = _session;
    final want80g = _want80g && widget.razorpay.eightyGEnabled;
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (session?.email?.trim() ?? '');

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
      _awaitingIosVerify = false;
    });
    announce(context, widget.copy.donateOpeningPayment);

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
        });
      }
    } on ApiError catch (error) {
      _onPaymentFailure(error.message);
    } catch (_) {
      _onPaymentFailure(widget.copy.donateFailedMessage);
    }
  }

  Future<void> _checkPayment() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    await _service().verifyPendingPayment();
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
    final checkout = _service();

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
          Semantics(
            header: true,
            child: ExcludeSemantics(
              child: Text(
                widget.copy.donatePayOnlineTitle,
                style: udaanGoogleFont(
                  context,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: palette.onBackground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.copy.donatePayOnlineSubtitle,
            style: udaanGoogleFont(
              context,
              fontSize: 15,
              height: 1.45,
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          if (presets.isNotEmpty) ...[
            Text(
              'Amount',
              style: udaanGoogleFont(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.onBackground,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final amount in presets)
                  _AmountChip(
                    label: '₹$amount',
                    selected: _selectedPreset == amount &&
                        _customAmountController.text.trim().isEmpty,
                    onTap: () {
                      setState(() {
                        _selectedPreset = amount;
                        _customAmountController.clear();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          UdaanLabeledField(
            label: widget.copy.donateAmountCustomLabel,
            controller: _customAmountController,
            focusNode: _customAmountFocus,
            keyboardDoneLabel: widget.copy.keyboardDone,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onSubmitted: (_) => _donate(),
          ),
          if (widget.razorpay.eightyGEnabled) ...[
            const SizedBox(height: 16),
            Semantics(
              checked: _want80g,
              label: widget.copy.donate80gCheckbox,
              child: CheckboxListTile(
                value: _want80g,
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _want80g = value == true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  widget.copy.donate80gCheckbox,
                  style: udaanGoogleFont(
                    context,
                    fontSize: 16,
                    color: palette.onBackground,
                  ),
                ),
              ),
            ),
            if (_want80g) ...[
              const SizedBox(height: 8),
              UdaanLabeledField(
                label: widget.copy.donatePanLabel,
                controller: _panController,
                required: true,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.visiblePassword,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              if (_session?.email?.trim().isEmpty ?? true) ...[
                const SizedBox(height: 12),
                UdaanLabeledField(
                  label: widget.copy.emailLabel,
                  controller: _emailController,
                  required: widget.razorpay.eightyGPdfEmailEnabled,
                  keyboardType: TextInputType.emailAddress,
                  hint: widget.copy.emailHint,
                ),
              ],
              const SizedBox(height: 10),
              Text(
                widget.copy.donateForm10beNote,
                style: udaanGoogleFont(
                  context,
                  fontSize: 14,
                  height: 1.4,
                  color: palette.onSurfaceVariant,
                ),
              ),
            ],
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: Text(
                _errorMessage!,
                style: udaanGoogleFont(
                  context,
                  fontSize: 15,
                  color: palette.error,
                ),
              ),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: Text(
                _successMessage!,
                style: udaanGoogleFont(
                  context,
                  fontSize: 15,
                  color: palette.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          UdaanPrimaryButton(
            label: widget.copy.donateNowButton,
            icon: Icons.payments_outlined,
            loading: _loading,
            onPressed: _loading ? null : _donate,
          ),
          if (_awaitingIosVerify && checkout.usesPaymentLink) ...[
            const SizedBox(height: 12),
            UdaanOutlineButton(
              label: widget.copy.donateCheckPayment,
              icon: Icons.check_circle_outline,
              onPressed: _loading ? null : _checkPayment,
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? palette.primary : palette.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? palette.primary : palette.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(
                minWidth: BrandTokens.a11yMinTapTarget,
                minHeight: BrandTokens.a11yMinTapTarget,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              alignment: Alignment.center,
              child: Text(
                label,
                style: udaanGoogleFont(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? palette.onPrimary : palette.onBackground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
