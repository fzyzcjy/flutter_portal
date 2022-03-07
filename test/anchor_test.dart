import 'package:flutter/material.dart';
import 'package:flutter_portal/src/anchor.dart';
import 'package:flutter_portal/src/portal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('$Anchor is passed proper constraints', (tester) async {
    Size? constraintsTargetSize;
    BoxConstraints? constraintsOverlayConstraints;
    Size? offsetSourceSize;
    Size? offsetTargetSize;
    Rect? offsetTheaterRect;
    final anchor = _TestAnchor(
      constraints: const BoxConstraints.tightFor(
        width: 42,
        height: 42,
      ),
      onGetSourceConstraints: (targetSize, overlayConstraints) {
        constraintsTargetSize = targetSize;
        constraintsOverlayConstraints = overlayConstraints;
      },
      onGetSourceOffset: (sourceSize, targetSize, theaterRect) {
        offsetSourceSize = sourceSize;
        offsetTargetSize = targetSize;
        offsetTheaterRect = theaterRect;
      },
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: ColoredBox(
              color: Colors.green,
              child: Portal(
                child: Center(
                  child: ColoredBox(
                    color: Colors.white,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: PortalTarget(
                        anchor: anchor,
                        portalFollower: const ColoredBox(
                          color: Colors.red,
                        ),
                        child: const Center(
                          child: ColoredBox(
                            color: Colors.black,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));

    expect(constraintsTargetSize, const Size(50, 50));
    expect(
      constraintsOverlayConstraints,
      BoxConstraints.tight(const Size(100, 100)),
    );
    expect(constraintsTargetSize, offsetTargetSize);
    expect(offsetSourceSize, const Size(42, 42));
    expect(offsetTheaterRect, const Offset(-25, -25) & const Size(100, 100));
  });

  testWidgets('$Aligned defers to backup if needed', (tester) async {
    var offsetAccessed = false;
    final backupAligned = _TestAligned(
      source: Alignment.bottomLeft,
      target: Alignment.topLeft,
      onGetSourceOffset: () => offsetAccessed = true,
    );
    final entry = PortalTarget(
      anchor: Aligned(
        follower: Alignment.topLeft,
        target: Alignment.bottomLeft,
        backup: backupAligned,
      ),
      portalFollower: const SizedBox(
        width: 20,
        height: 20,
      ),
      child: const SizedBox(
        width: 10,
        height: 10,
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: Portal(
              child: Center(
                child: entry,
              ),
            ),
          ),
        ),
      ),
    ));

    expect(offsetAccessed, false);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 50,
            height: 49,
            child: Portal(
              child: Center(
                child: entry,
              ),
            ),
          ),
        ),
      ),
    ));

    expect(offsetAccessed, true);
  });
}

class _TestAnchor extends Anchor {
  const _TestAnchor({
    required this.constraints,
    required this.onGetSourceConstraints,
    required this.onGetSourceOffset,
  });

  final BoxConstraints constraints;

  final void Function(
    Size targetSize,
    BoxConstraints overlayConstraints,
  ) onGetSourceConstraints;
  final void Function(
    Size sourceSize,
    Size targetSize,
    Rect theaterRect,
  ) onGetSourceOffset;

  @override
  BoxConstraints getFollowerConstraints({
    required Size targetSize,
    required BoxConstraints portalConstraints,
  }) {
    onGetSourceConstraints(targetSize, portalConstraints);
    return constraints;
  }

  @override
  Offset getFollowerOffset({
    required Size followerSize,
    required Size targetSize,
    required Rect portalRect,
  }) {
    onGetSourceOffset(followerSize, targetSize, portalRect);
    return Offset.zero;
  }
}

class _TestAligned extends Aligned {
  const _TestAligned({
    required Alignment source,
    required Alignment target,
    Offset offset = Offset.zero,
    double? widthFactor,
    double? heightFactor,
    required this.onGetSourceOffset,
  }) : super(
            follower: source,
            target: target,
            offset: offset,
            widthFactor: widthFactor,
            heightFactor: heightFactor);

  final VoidCallback onGetSourceOffset;

  @override
  Offset getFollowerOffset({
    required Size followerSize,
    required Size targetSize,
    required Rect portalRect,
  }) {
    onGetSourceOffset();
    return super.getFollowerOffset(
      followerSize: followerSize,
      targetSize: targetSize,
      portalRect: portalRect,
    );
  }
}
