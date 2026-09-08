import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'kasa_import_service.dart';

/// JPG/PDF içe aktarımından gelen form taslağı (tek kullanımlık).
class BelgeImportDraftNotifier extends StateNotifier<BelgeImportDraft?> {
  BelgeImportDraftNotifier() : super(null);

  void setDraft(BelgeImportDraft draft) => state = draft;

  BelgeImportDraft? take() {
    final current = state;
    state = null;
    return current;
  }

  void clear() => state = null;
}

final belgeImportDraftProvider =
    StateNotifierProvider<BelgeImportDraftNotifier, BelgeImportDraft?>(
  (ref) => BelgeImportDraftNotifier(),
);
