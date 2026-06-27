import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import '../../../core/theme/udaan_colors.dart';
import '../../../core/utils/keyboard_dismiss.dart';

/// Six-digit OTP entry with manual SMS entry only (no READ_SMS).
class UdaanOtpPinRow extends StatefulWidget {
  const UdaanOtpPinRow({
    required this.copy,
    required this.controller,
    required this.length,
    this.enabled = true,
    this.semanticsHint,
    super.key,
  });

  final AppCopy copy;
  final TextEditingController controller;
  final int length;
  final bool enabled;
  final String? semanticsHint;

  @override
  State<UdaanOtpPinRow> createState() => _UdaanOtpPinRowState();
}

class _UdaanOtpPinRowState extends State<UdaanOtpPinRow> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCodeChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final cells = List<String>.generate(widget.length, (i) {
      return i < code.length ? code[i] : '';
    });

    return Semantics(
      label: widget.copy.otpPinRowLabel,
      hint: widget.semanticsHint ?? widget.copy.otpPinRowSmsHint(widget.length),
      textField: true,
      value: code.isEmpty
          ? widget.copy.otpPinRowEmpty
          : widget.copy.otpPinRowValue(code),
      child: GestureDetector(
        onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 56,
              width: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
                onTapOutside: (_) => dismissKeyboard(context),
                onSubmitted: (_) => dismissKeyboard(context),
              ),
            ),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.length, (index) {
                final digit = cells[index];
                final filled = digit.isNotEmpty;
                final active = code.length == index && _focusNode.hasFocus;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < widget.length - 1 ? 8 : 0,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 44,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: UdaanColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? UdaanColors.primary
                            : filled
                                ? UdaanColors.primaryGlow
                                : UdaanColors.outlineVariant,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      digit,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: UdaanColors.onBackground,
                      ),
                    ),
                  ),
                );
              }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
