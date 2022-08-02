# 1.1.1

* Export some methods
* Fix Flutter 3.0 warnings

# 1.1.0

* Upgrade to Flutter 3.0
* Export Filled anchor #74 (thanks @mityax)

# 1.0.0

* Fix `_debugCheckLeaderBeforeFollower(forwardLayers, inverseLayers)': LeaderLayer anchor must come before FollowerLayer in paint order, but the reverse was true.` (@fzyzcjy)
* `Aligned.backup` is always used even if it should not; cause: `getFollowerOffset`'s `portalRect` argument is wrong #63 (@fzyzcjy)
* `CustomRenderFollowerLayer._computeLinkedOffset` is wrong especially when having a RepaintBoundary at ancestor which is quite common #62 (@fzyzcjy)
* `_RenderPortalTargetTheater.applyPaintTransform` is wrong when using operations like `globalToLocal(ancestor: something)`; it only works correctly with `globalToLocal()` without ancestors param #61 (@fzyzcjy)
* `localToGlobal` or similar methods are wrong for widgets in the subtree of portal follower #65 (@fzyzcjy)
* Touch (click) events are drifted (shifted incorrectly) for `PortalTarget`s #64 (@fzyzcjy)
* Allow the follower partially follow the target in selected axis; allow align relative to Portal #17 (@fzyzcjy)
* Shift portal follower to be inside the bounds of portal #67 (@fzyzcjy)
* Extract the composited transform ("leader/follower") in this library to beautify the code and allow users to use them directly #70 (@fzyzcjy)

# 1.0.0-dev.2

* Fix broken images in pub

# 1.0.0-dev.1

* New anchoring logic for advanced use cases #44 (@creativecreatorormaybenot for the main PR, @fzyzcjy for Flutter stable compatibility)
* Allow PortalEntry that binds to a ancestor but not nearest Portal #45 (@fzyzcjy)
* Enhance scope searching strategy: Defaults to "main" scope if provided #51 (@fzyzcjy)
* Sync those modified-from-Flutter code with latest Flutter code and some refactor (@fzyzcjy #50)
* Add debugName to ease debugging (@fzyzcjy)
* Fix `Failed assertion: '_lastOffset != null' in various cases`, which should exist in Flutter 2.8~2.10 and flutter_portal from old to new (@fzyzcjy #56)
* New readme and documentations (@fzyzcjy)

# 0.4.0

- Stable null-safety release

# 0.4.0-nullsafety.0

- Migrated to null-safety (thanks to @Jjagg!)

# 0.3.0

- Improved the dart-doc of Portal and PortalEntry
- Added and improved the examples
- Fixed a bug where changing the visibility of a portal destroys the state of `child`
- Adding a way to delay the disappearance of a portal entry:

  ```dart
  PortalEntry(
    visible: visible,
    closeDuration: Duration(seconds: 2),
    portal: ...,
    child: ...
  )
  ```

  With this code, when `visible` changes to `false`, the portal will stay
  visible for an extra 2 seconds.

  This can be useful to implement leave animations.
  For example, the following implement a fade-out transition:

  ```dart
  PortalEntry(
    visible: visible,
    closeDuration: Duration(seconds: 2),
    portal: AnimatedOpacity(
      duration: Duration(seconds: 2),
      opacity: visible ? 1 : 0,
      child: Container(color: Colors.red),
    ),
    child: ...
  )
  ```

# 0.2.0

- Update to support latest Flutter version

# 0.1.0

- Changed the algorithm behind how portals/overlays are rendered.\
This fixes some problems when combined with `LayoutBuilder`

- Removed the generic parameter of `PortalEntry`

# 0.0.1+2

Fix pub badge

# 0.0.1+1

Improve package description

# 0.0.1

Initial implementation
