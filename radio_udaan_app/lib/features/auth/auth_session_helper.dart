import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/auth_session.dart';
import '../../core/providers/app_providers.dart';

/// Persists token storage and in-memory auth state after a successful auth call.
Future<void> persistAuthSession(WidgetRef ref, AuthSession session) async {
  if (session.token.isNotEmpty) {
    await ref.read(tokenStorageProvider).saveSession(
          token: session.token,
          phoneE164: session.phoneE164,
          email: session.email,
          name: session.name,
        );
    ref.read(authTokenProvider.notifier).state = session.token;
  }
  ref.read(authUserProvider.notifier).state = session;
  if (session.phoneE164.isNotEmpty) {
    ref.read(authPhoneProvider.notifier).state = session.phoneE164;
  }
}

Future<void> clearAuthSession(WidgetRef ref) async {
  await ref.read(tokenStorageProvider).clear();
  ref.read(authTokenProvider.notifier).state = null;
  ref.read(authUserProvider.notifier).state = null;
  ref.read(authPhoneProvider.notifier).state = null;
}
