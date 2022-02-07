import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

// This implements Medium's clap button

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Example'),
          ),
          body: const Center(child: ClapButton()),
        ),
      ),
    );
  }
}

class ClapButton extends StatefulWidget {
  const ClapButton({Key? key}) : super(key: key);

  @override
  _ClapButtonState createState() => _ClapButtonState();
}

class _ClapButtonState extends State<ClapButton> {
  int clapCount = 0;
  bool hasClappedRecently = false;
  Timer? resetHasClappedRecentlyTimer;

  @override
  Widget build(BuildContext context) {
    return PortalTarget(
      visible: hasClappedRecently,
      // aligns the top-center of `child` with the bottom-center of `portal`
      anchor: const Aligned(
        target: Alignment.topCenter,
        follower: Alignment.bottomCenter,
      ),
      closeDuration: kThemeChangeDuration,
      portalFollower: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: hasClappedRecently ? 1 : 0),
        duration: kThemeChangeDuration,
        builder: (context, progress, child) {
          return Material(
            elevation: 8 * progress,
            animationDuration: Duration.zero,
            borderRadius: const BorderRadius.all(Radius.circular(40)),
            child: Opacity(
              opacity: progress,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text('$clapCount'),
        ),
      ),
      child: ElevatedButton(
        onPressed: _clap,
        child: const Icon(Icons.plus_one),
      ),
    );
  }

  void _clap() {
    resetHasClappedRecentlyTimer?.cancel();

    resetHasClappedRecentlyTimer = Timer(
      const Duration(seconds: 2),
      () => setState(() => hasClappedRecently = false),
    );

    setState(() {
      hasClappedRecently = true;
      clapCount++;
    });
  }
}
