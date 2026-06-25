import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_user_settings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_text_styles.dart';
import '../auth/widgets/udaan_auth_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  late AppUserSettings _draft;
  late AppUserSettings _savedBaseline;
  bool _saving = false;
  bool _saved = false;
  Timer? _textScaleAnnounceTimer;

  @override
  void initState() {
    super.initState();
    _savedBaseline = ref.read(appSettingsProvider);
    _draft = _savedBaseline;
  }

  @override
  void dispose() {
    _textScaleAnnounceTimer?.cancel();
    super.dispose();
  }

  void _announce(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  void _updateDraft(AppUserSettings next) {
    setState(() => _draft = next);
    ref.read(appSettingsProvider.notifier).preview(next);
  }

  Future<void> _restoreBaseline() async {
    await ref.read(appSettingsProvider.notifier).load();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final token = ref.read(authTokenProvider);
      if (token != null && token.isNotEmpty) {
        await ref.read(radioudaanApiProvider).updateNotificationPreferences(
              liveBroadcastsEnabled: _draft.notifyLiveBroadcasts,
              eventsEnabled: _draft.notifyEventAlerts,
              promotionsEnabled: _draft.notifyPromotions,
            );
      }
      await ref.read(appSettingsProvider.notifier).save(_draft);
      _saved = true;
      if (!mounted) return;
      _announce(_copy.preferencesSaved);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        _announce(_copy.preferencesSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final palette = context.udaan;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            label: title,
            child: Text(
              title,
              style: udaanTextStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: palette.primaryGlow, height: 1),
        ],
      ),
    );
  }

  Widget _toggleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    final palette = context.udaan;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outlineVariant),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: icon != null
            ? Icon(icon, color: palette.primaryGlow)
            : null,
        title: Text(
          title,
          style: udaanTextStyle(
            context,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: udaanTextStyle(
            context,
            fontSize: 14,
            color: palette.onSurfaceVariant,
          ),
        ),
        value: value,
        activeThumbColor: palette.onPrimary,
        activeTrackColor: palette.primary,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    ref.watch(appSettingsProvider);
    final palette = context.udaan;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_saved) {
          _restoreBaseline();
          _announce(_copy.preferencesDiscarded);
        }
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BrandTokens.screenPadding,
                ),
                child: UdaanAuthTopBar(
                copy: copy,
                title: _copy.settingsTitle,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(BrandTokens.screenPadding),
                  children: [
                    Text(
                      _copy.settingsIntro,
                      style: udaanTextStyle(
                        context,
                        fontSize: 16,
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                    _sectionTitle(context, _copy.accessibilitySection),
                    _toggleCard(
                      context: context,
                      title: _copy.highContrastMode,
                      subtitle: _copy.highContrastModeHint,
                      value: _draft.highContrast,
                      onChanged: (v) =>
                          _updateDraft(_draft.copyWith(highContrast: v)),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _copy.textSize,
                                  style: udaanTextStyle(
                                    context,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${_draft.textScale.toStringAsFixed(1)}x',
                                style: udaanTextStyle(
                                  context,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: palette.primaryGlow,
                                ),
                              ),
                            ],
                          ),
                          Semantics(
                            label: _copy.textSize,
                            hint: _copy.textSizeSliderHint,
                            value: '${_draft.textScale.toStringAsFixed(1)}x',
                            child: Slider(
                              min: 1.0,
                              max: 1.4,
                              divisions: 4,
                              value: _draft.textScale.clamp(1.0, 1.4),
                              activeColor: palette.primary,
                              onChanged: (v) {
                                _updateDraft(_draft.copyWith(textScale: v));
                                _textScaleAnnounceTimer?.cancel();
                                _textScaleAnnounceTimer = Timer(
                                  const Duration(milliseconds: 400),
                                  () => _announce(
                                    '${_copy.textSize} ${v.toStringAsFixed(1)}x',
                                  ),
                                );
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _copy.textSizeSlower,
                                style: udaanTextStyle(
                                  context,
                                  fontSize: 13,
                                  color: palette.primaryGlow,
                                ),
                              ),
                              Text(
                                _copy.textSizeNormal,
                                style: udaanTextStyle(
                                  context,
                                  fontSize: 13,
                                  color: palette.primaryGlow,
                                ),
                              ),
                              Text(
                                _copy.textSizeFaster,
                                style: udaanTextStyle(
                                  context,
                                  fontSize: 13,
                                  color: palette.primaryGlow,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _toggleCard(
                      context: context,
                      title: _copy.boldText,
                      subtitle: _copy.boldTextHint,
                      value: _draft.boldText,
                      onChanged: (v) =>
                          _updateDraft(_draft.copyWith(boldText: v)),
                    ),
                    _toggleCard(
                      context: context,
                      title: _copy.reduceMotion,
                      subtitle: _copy.reduceMotionHint,
                      value: _draft.reduceMotion,
                      onChanged: (v) =>
                          _updateDraft(_draft.copyWith(reduceMotion: v)),
                    ),
                    _sectionTitle(context, _copy.notificationsSection),
                    _toggleCard(
                      context: context,
                      title: _copy.notifyLiveBroadcasts,
                      subtitle: _copy.tabRadio,
                      icon: Icons.radio,
                      value: _draft.notifyLiveBroadcasts,
                      onChanged: (v) => _updateDraft(
                        _draft.copyWith(notifyLiveBroadcasts: v),
                      ),
                    ),
                    _toggleCard(
                      context: context,
                      title: _copy.notifyEventAlerts,
                      subtitle: _copy.tabEvents,
                      icon: Icons.event,
                      value: _draft.notifyEventAlerts,
                      onChanged: (v) =>
                          _updateDraft(_draft.copyWith(notifyEventAlerts: v)),
                    ),
                    _toggleCard(
                      context: context,
                      title: _copy.notifyPromotions,
                      subtitle: _copy.joinCommunity,
                      icon: Icons.campaign_outlined,
                      value: _draft.notifyPromotions,
                      onChanged: (v) =>
                          _updateDraft(_draft.copyWith(notifyPromotions: v)),
                    ),
                    const SizedBox(height: 16),
                    UdaanPrimaryButton(
                      label: _copy.savePreferences,
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
