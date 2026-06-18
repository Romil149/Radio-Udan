import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/email_login_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/auth/phone_login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/bootstrap/bootstrap_screen.dart';
import '../../features/events/event_deep_link_screen.dart';
import '../../features/shell/main_shell_screen.dart';
import '../models/otp_purpose.dart';
import '../providers/app_providers.dart';
import 'event_deep_link.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notifies [GoRouter] to re-run redirects without recreating the router.
final _routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  ref.listen(authTokenProvider, (_, _) => notifier.refresh());
  ref.listen(authUserProvider, (_, _) => notifier.refresh());
  ref.listen(remoteConfigProvider, (_, _) => notifier.refresh());
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refresh,
    initialLocation: '/bootstrap',
    redirect: (context, state) {
      final normalized = normalizeEventDeepLinkUri(state.uri);
      if (normalized != null) {
        return normalized;
      }

      final authToken = ref.read(authTokenProvider);
      final authUser = ref.read(authUserProvider);
      final config = ref.read(remoteConfigProvider);
      final path = state.matchedLocation;
      final eventId = parseEventDeepLinkPath(path);
      if (eventId != null) {
        ref.read(pendingEventDeepLinkProvider.notifier).state = eventId;
      }
      final loggedIn = authToken != null && authToken.isNotEmpty;
      final user = authUser;
      final requireEmail =
          config?.authPolicy.requireEmailVerification ?? false;

      if (path == '/bootstrap') return null;

      if (config == null) {
        return '/bootstrap';
      }

      if (!loggedIn && !_isAuthRoute(path)) {
        return '/login';
      }

      if (loggedIn && user == null && path != '/bootstrap') {
        return '/login';
      }

      if (loggedIn && user != null) {
        if (!user.phoneVerified &&
            path != '/otp' &&
            path != '/login-otp') {
          return '/otp';
        }
        if (requireEmail &&
            !user.emailVerified &&
            path != '/verify-email') {
          return '/verify-email';
        }
      }

      if (loggedIn && _isAuthRoute(path)) {
        if (path == '/verify-email' &&
            user != null &&
            requireEmail &&
            !user.emailVerified) {
          return null;
        }
        if (path == '/otp' &&
            user != null &&
            !user.phoneVerified) {
          return null;
        }
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/bootstrap',
        builder: (context, state) => const BootstrapScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login-email',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/otp-login',
        builder: (context, state) {
          final extra = state.extra as PhoneLoginRouteArgs?;
          return PhoneLoginScreen(args: extra);
        },
      ),
      GoRoute(
        path: '/login-otp',
        builder: (context, state) {
          final extra = state.extra as PhoneLoginRouteArgs?;
          return PhoneLoginScreen(args: extra);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as OtpRouteArgs?;
          return OtpVerifyScreen(args: extra);
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final extra = state.extra as VerifyEmailRouteArgs?;
          return VerifyEmailScreen(args: extra);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final extra = state.extra as ResetPasswordRouteArgs?;
          return ResetPasswordScreen(
            initialToken: extra?.token,
            phoneE164: extra?.phoneE164,
            otp: extra?.otp,
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/event/:eventId',
        builder: (context, state) {
          final rawId = state.pathParameters['eventId'] ?? '';
          final eventId = int.tryParse(rawId) ?? 0;
          return EventDeepLinkScreen(eventId: eventId);
        },
      ),
    ],
  );
});

class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

bool _isAuthRoute(String path) {
  return path == '/login' ||
      path == '/login-email' ||
      path == '/login-otp' ||
      path == '/register' ||
      path == '/otp' ||
      path == '/verify-email' ||
      path == '/forgot-password' ||
      path == '/reset-password' ||
      path == '/otp-login';
}

class PhoneLoginRouteArgs {
  const PhoneLoginRouteArgs({this.initialPhoneInput = ''});

  /// Raw international phone text to prefill from the login screen.
  final String initialPhoneInput;
}

class OtpRouteArgs {
  const OtpRouteArgs({
    required this.requestId,
    required this.phoneE164,
    required this.resendAfterSec,
    required this.purpose,
    this.devOtp,
  });

  final String requestId;
  final String phoneE164;
  final int resendAfterSec;
  final OtpPurpose purpose;
  final String? devOtp;
}

class VerifyEmailRouteArgs {
  const VerifyEmailRouteArgs({this.email = ''});

  final String email;
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({
    this.token,
    this.phoneE164,
    this.otp,
  });

  final String? token;
  final String? phoneE164;
  final String? otp;
}
