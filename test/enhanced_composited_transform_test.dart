import 'package:flutter/material.dart';
import 'package:flutter_portal/enhanced_composited_transform.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tap location', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(300, 300);
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    final containerKey = GlobalKey();
    final link = EnhancedLayerLink();

    const targetSize = Size(20, 20);

    var tapCount = 0;

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
                  theaterGetter: () => containerKey.currentContext?.findRenderObject() as RenderBox?,
                  child: Container(
                    color: Colors.red.withAlpha(150),
                  ),
                ),
              ),
              Positioned(
                left: 30,
                top: 40,
                width: targetSize.width,
                height: targetSize.height,
                child: Container(
                  color: Colors.blue.withAlpha(150),
                  child: EnhancedCompositedTransformFollower(
                    link: link,
                    targetSize: targetSize,
                    anchor: Aligned.center,
                    child: InkWell(
                      onTap: () => tapCount++,
                      child: Container(
                        color: Colors.green.withAlpha(150),
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

    await expectLater(
        find.byKey(containerKey), matchesGoldenFile('enhanced_composited_transform_tap.png'));

    await tester.tapAt(const Offset(35, 45));
    expect(tapCount, 1);

    await tester.tapAt(const Offset(25, 35));
    expect(tapCount, 2);
  });
}
