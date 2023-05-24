import 'package:flutter/material.dart';
import 'package:flutter_portal/enhanced_composited_transform.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tap location', (tester) async {
    tester.view.physicalSize = const Size(300, 300);
    addTearDown(tester.view.resetPhysicalSize);

    final containerKey = GlobalKey();
    final link = EnhancedLayerLink();

    const targetSize = Size(20, 20);

    PointerDownEvent? lastPointerDownEvent;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Container(
          key: containerKey,
          child: Stack(
            children: [
              Positioned(
                left: 20,
                top: 30,
                width: 20,
                height: 20,
                child: EnhancedCompositedTransformTarget(
                  link: link,
                  theaterGetter: () => containerKey.currentContext
                      ?.findRenderObject() as RenderBox?,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                // NOTE should *not* limit size at outside, otherwise has tap problem
                // left: 30,
                // top: 40,
                // width: targetSize.width,
                // height: targetSize.height,
                child: Container(
                  color: Colors.blue.withAlpha(150),
                  child: EnhancedCompositedTransformFollower(
                    link: link,
                    targetSize: targetSize,
                    anchor: Aligned.center,
                    child: Center(
                      child: Listener(
                        onPointerDown: (e) => lastPointerDownEvent = e,
                        child: Container(
                          width: targetSize.width,
                          height: targetSize.height,
                          color: Colors.green.withAlpha(150),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    await expectLater(find.byKey(containerKey),
        matchesGoldenFile('enhanced_composited_transform_tap.png'));

    lastPointerDownEvent = null;
    await tester.tapAt(const Offset(35, 45));
    expect(lastPointerDownEvent, isNotNull);
    expect(lastPointerDownEvent!.position, const Offset(35, 45));
    expect(lastPointerDownEvent!.localPosition, const Offset(15, 15));

    lastPointerDownEvent = null;
    await tester.tapAt(const Offset(25, 35));
    expect(lastPointerDownEvent, isNotNull);
    expect(lastPointerDownEvent!.position, const Offset(25, 35));
    expect(lastPointerDownEvent!.localPosition, const Offset(5, 5));
  });
}
