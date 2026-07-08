import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/whats_new_update.dart';
import '../../core/providers/app_providers.dart';

final whatsNewListProvider = FutureProvider<WhatsNewListResponse>((ref) async {
  return ref.read(radioudaanApiProvider).listUpdates(perPage: 50);
});

final whatsNewAnnouncementDetailProvider =
    FutureProvider.family<WhatsNewAnnouncementDetail, int>((ref, id) async {
  return ref.read(radioudaanApiProvider).getWhatsNewDetail(id);
});

final whatsNewInNewsDetailProvider =
    FutureProvider.family<WhatsNewInNewsDetail, int>((ref, id) async {
  return ref.read(radioudaanApiProvider).getInNewsDetail(id);
});
