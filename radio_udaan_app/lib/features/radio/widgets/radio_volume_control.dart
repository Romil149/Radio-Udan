import 'package:flutter/material.dart';

import '../../../core/accessibility/udaan_semantics.dart';
import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';
import '../../../core/theme/udaan_google_fonts.dart';

/// Live radio volume — Material slider for sighted users; one adjustable node
/// for VoiceOver/TalkBack (swipe up/down) plus vertical drag on the track.
class RadioVolumeControl extends StatefulWidget {
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

  @override
  State<RadioVolumeControl> createState() => _RadioVolumeControlState();
}

class _RadioVolumeControlState extends State<RadioVolumeControl> {
  static const _verticalDragThreshold = 12.0;
  double _verticalDragAccum = 0;

  AppCopy get copy => widget.copy;

  void _commitVolume(
    double next, {
    required bool speak,
  }) {
    final stepped = RadioVolumeControl.snapToStep(next);
    final percent = (stepped * 100).round();
    widget.onChanged(stepped);
    if (speak && mounted) {
      announce(context, copy.radioVolumeAnnounce(percent));
    }
  }

  void _bumpByStep(int direction) {
    final stepped = RadioVolumeControl.snapToStep(widget.value);
    final percent = (stepped * 100).round();
    final nextPercent = (percent + (direction * 10)).clamp(0, 100);
    if (nextPercent == percent) return;
    _commitVolume(nextPercent / 100, speak: true);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _verticalDragAccum += details.delta.dy;
    while (_verticalDragAccum <= -_verticalDragThreshold) {
      _verticalDragAccum += _verticalDragThreshold;
      _bumpByStep(1);
    }
    while (_verticalDragAccum >= _verticalDragThreshold) {
      _verticalDragAccum -= _verticalDragThreshold;
      _bumpByStep(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepped = RadioVolumeControl.snapToStep(widget.value);
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
            enabled: true,
            label: copy.radioVolume,
            hint: copy.radioVolumeSliderHint,
            value: semanticValue,
            increasedValue: '$nextPercent percent',
            decreasedValue: '$prevPercent percent',
            onIncrease:
                percent < 100 ? () => _bumpByStep(1) : null,
            onDecrease: percent > 0 ? () => _bumpByStep(-1) : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              child: ExcludeSemantics(
                child: SizedBox(
                  height: BrandTokens.a11yMinTapTarget,
                  child: Slider(
                    value: stepped,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: '$percent%',
                    onChanged: (v) => _commitVolume(v, speak: false),
                    onChangeEnd: (v) => _commitVolume(v, speak: true),
                    activeColor: context.udaan.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
