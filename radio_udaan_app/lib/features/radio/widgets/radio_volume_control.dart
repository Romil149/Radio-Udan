import 'package:flutter/material.dart';

import '../../../core/accessibility/udaan_semantics.dart';
import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';
import '../../../core/theme/udaan_google_fonts.dart';

/// Live radio volume slider — one VoiceOver/TalkBack focus, 10% steps.
class RadioVolumeControl extends StatelessWidget {
  const RadioVolumeControl({
    super.key,
    required this.copy,
    required this.value,
    required this.onChanged,
  });

  final AppCopy copy;
  final double value;
  final ValueChanged<double> onChanged;

  static double snapToStep(double raw) {
    return ((raw.clamp(0.0, 1.0) * 10).round() / 10).clamp(0.0, 1.0);
  }

  void _commitVolume(
    BuildContext context,
    double next, {
    required bool speak,
  }) {
    final stepped = snapToStep(next);
    final percent = (stepped * 100).round();
    onChanged(stepped);
    if (speak) {
      announce(context, copy.radioVolumeAnnounce(percent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepped = snapToStep(value);
    final percent = (stepped * 100).round();
    final semanticValue = '$percent percent';
    final nextPercent = (percent + 10).clamp(0, 100);
    final prevPercent = (percent - 10).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: context.udaan.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.udaan.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    copy.radioVolume,
                    style: udaanGoogleFont(
                      context,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.udaan.onBackground,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: udaanGoogleFont(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.udaan.primaryGlow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            slider: true,
            label: copy.radioVolume,
            hint: copy.radioVolumeSliderHint,
            value: semanticValue,
            increasedValue: '$nextPercent percent',
            decreasedValue: '$prevPercent percent',
            onIncrease: percent < 100
                ? () => _commitVolume(
                      context,
                      nextPercent / 100,
                      speak: true,
                    )
                : null,
            onDecrease: percent > 0
                ? () => _commitVolume(
                      context,
                      prevPercent / 100,
                      speak: true,
                    )
                : null,
            child: ExcludeSemantics(
              child: SizedBox(
                height: BrandTokens.a11yMinTapTarget,
                child: Slider(
                  value: stepped,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: '$percent%',
                  onChanged: (v) => _commitVolume(context, v, speak: false),
                  onChangeEnd: (v) => _commitVolume(context, v, speak: true),
                  activeColor: context.udaan.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
