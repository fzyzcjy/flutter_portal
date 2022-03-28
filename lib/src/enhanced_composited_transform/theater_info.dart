import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'flutter_src/rendering_proxy_box.dart';

// ignore: one_member_abstracts
abstract class EnhancedCompositedTransformTheaterInfo {
  const EnhancedCompositedTransformTheaterInfo();

  Rect theaterRectRelativeToLeader(EnhancedRenderLeaderLayer leaderLayer);
}

@immutable
class EnhancedCompositedTransformTheaterInfoLiteral
    extends EnhancedCompositedTransformTheaterInfo {
  const EnhancedCompositedTransformTheaterInfoLiteral(
      {required Rect theaterRectRelativeToLeader})
      : _theaterRectRelativeToLeader = theaterRectRelativeToLeader;

  final Rect _theaterRectRelativeToLeader;

  @override
  Rect theaterRectRelativeToLeader(EnhancedRenderLeaderLayer leaderLayer) =>
      _theaterRectRelativeToLeader;

  @override
  String toString() =>
      'EnhancedCompositedTransformTheaterInfoLiteral{_theaterRectRelativeToLeader: $_theaterRectRelativeToLeader}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedCompositedTransformTheaterInfoLiteral &&
          runtimeType == other.runtimeType &&
          _theaterRectRelativeToLeader == other._theaterRectRelativeToLeader;

  @override
  int get hashCode => _theaterRectRelativeToLeader.hashCode;
}
