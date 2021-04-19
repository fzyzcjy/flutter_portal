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