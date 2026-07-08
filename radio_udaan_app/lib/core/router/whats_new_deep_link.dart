import 'package:flutter/material.dart';

import '../models/whats_new_update.dart';
import 'app_router.dart';
import '../../features/about/whats_new_detail_screen.dart';

/// Opens a what's-new detail screen from push or inbox payload.
void openWhatsNewDetailFromData(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? '';
  if (route != 'whats_new_detail') return;

  final type = WhatsNewUpdateType.fromApi(data['post_type']?.toString());
  final postId = int.tryParse(data['post_id']?.toString() ?? '') ?? 0;
  if (type == null || postId < 1) return;

  final context = rootNavigatorKey.currentContext;
  if (context == null) return;

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WhatsNewDetailScreen(type: type, postId: postId),
    ),
  );
}

/// Returns true when [data] targets a what's-new detail screen.
bool isWhatsNewDetailPayload(Map<String, dynamic> data) {
  return data['route']?.toString() == 'whats_new_detail';
}
