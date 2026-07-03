import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Shared VoiceOver / TalkBack helpers for Radio Udaan.
void announce(BuildContext context, String message) {
  if (message.trim().isEmpty) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message.trim(),
      Directionality.of(context),
    );
  });
}

/// Speaks for screen readers and shows a SnackBar for sighted users.
void announceAndSnack(BuildContext context, String message) {
  if (message.trim().isEmpty) return;
  announce(context, message);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message.trim())),
  );
}

/// One spoken node; descendants are not separate focus stops.
class UdaanLabeledRegion extends StatelessWidget {
  const UdaanLabeledRegion({
    required this.label,
    required this.child,
    this.header = false,
    this.liveRegion = false,
    super.key,
  });

  final String label;
  final Widget child;
  final bool header;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: header,
      label: label,
      liveRegion: liveRegion,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Screen title landmark for rotor / TalkBack headings.
class UdaanScreenHeader extends StatelessWidget {
  const UdaanScreenHeader({
    required this.title,
    required this.style,
    this.textAlign,
    super.key,
  });

  final String title;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: title,
      child: ExcludeSemantics(
        child: Text(
          title,
          style: style,
          textAlign: textAlign,
        ),
      ),
    );
  }
}

/// Bottom sheet scaffold with route semantics (modal context for screen readers).
class UdaanModalSheet extends StatelessWidget {
  const UdaanModalSheet({
    required this.title,
    required this.child,
    this.decoration,
    this.padding,
    super.key,
  });

  final String title;
  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      child: Container(
        decoration: decoration,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Button with [Semantics.onTap] so VoiceOver/TalkBack can activate wrapped controls.
class UdaanAccessibleButton extends StatelessWidget {
  const UdaanAccessibleButton({
    required this.label,
    required this.child,
    this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String label;
  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && onPressed != null;
    return Semantics(
      button: true,
      label: label,
      enabled: canPress,
      onTap: canPress ? onPressed : null,
      child: ExcludeSemantics(child: child),
    );
  }
}
