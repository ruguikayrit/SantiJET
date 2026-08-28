import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';

class DemoIntroState {
  const DemoIntroState({
    this.introCompleted = false,
    this.guideVisible = false,
  });

  final bool introCompleted;
  final bool guideVisible;

  DemoIntroState copyWith({
    bool? introCompleted,
    bool? guideVisible,
    bool clearGuide = false,
  }) {
    return DemoIntroState(
      introCompleted: introCompleted ?? this.introCompleted,
      guideVisible: clearGuide ? false : (guideVisible ?? this.guideVisible),
    );
  }
}

class DemoIntroNotifier extends StateNotifier<DemoIntroState> {
  DemoIntroNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _introKey = 'demo_intro_completed';
  static const _guideKey = 'demo_guide_visible';

  static DemoIntroState _load(Box box) {
    return DemoIntroState(
      introCompleted: box.get(_introKey) == true,
      guideVisible: box.get(_guideKey) == true,
    );
  }

  void completeIntro({bool showGuide = false}) {
    _box.put(_introKey, true);
    if (showGuide) {
      _box.put(_guideKey, true);
    } else {
      _box.delete(_guideKey);
    }
    state = DemoIntroState(introCompleted: true, guideVisible: showGuide);
  }

  void dismissGuide() {
    _box.delete(_guideKey);
    state = state.copyWith(guideVisible: false);
  }

  void resetIntroForReplay() {
    _box.delete(_introKey);
    _box.delete(_guideKey);
    state = const DemoIntroState();
  }

  void showGuideAgain() {
    _box.put(_guideKey, true);
    state = state.copyWith(guideVisible: true);
  }
}

final demoIntroProvider =
    StateNotifierProvider<DemoIntroNotifier, DemoIntroState>((ref) {
  return DemoIntroNotifier(ref.watch(settingsBoxProvider));
});
