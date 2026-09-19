import 'package:flutter/painting.dart';

/// Corner radii used across the design.
abstract final class AppRadii {
  static const double r8 = 8;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r28 = 28;
  static const double r32 = 32;
  static const double pill = 999;
}

/// Layout constants shared by several screens.
abstract final class AppLayout {
  /// The design caps content at Tailwind's `max-w-md` (448) and centres it, so
  /// tablets/foldables get a phone-width column instead of stretched cards.
  static const double maxContentWidth = 448;
  static const double headerHeight = 64;
  static const double navHeight = 80;
  static const double screenGutter = 20;
  static const double minTouchTarget = 44;
}

/// Elevation recipes (`box-shadow` values from the Figma export).
abstract final class AppShadows {
  static const List<BoxShadow> none = <BoxShadow>[];

  /// Level 1 - onboarding/auth cards.
  static const List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Soft feed card.
  static const List<BoxShadow> feedCard = <BoxShadow>[
    BoxShadow(color: Color(0x0F2C302E), offset: Offset(0, 4), blurRadius: 20, spreadRadius: -2),
    BoxShadow(color: Color(0x082C302E), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Large detail/settings section cards.
  static const List<BoxShadow> sectionCard = <BoxShadow>[
    BoxShadow(color: Color(0x0D2C302E), offset: Offset(0, 4), blurRadius: 20, spreadRadius: -2),
    BoxShadow(color: Color(0x082C302E), offset: Offset(0, 1), blurRadius: 3),
  ];

  static const List<BoxShadow> chipLift = <BoxShadow>[
    BoxShadow(color: Color(0x0F2C302E), offset: Offset(0, 4), blurRadius: 20, spreadRadius: -2),
  ];

  static const List<BoxShadow> escalation = <BoxShadow>[
    BoxShadow(color: Color(0x145B2E2D), offset: Offset(0, 4), blurRadius: 20, spreadRadius: -2),
  ];

  static const List<BoxShadow> primaryButton = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1),
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2),
  ];

  static const List<BoxShadow> approveGlow = <BoxShadow>[
    BoxShadow(color: Color(0x402D5A46), offset: Offset(0, 4), blurRadius: 6),
  ];

  static const List<BoxShadow> navPill = <BoxShadow>[
    BoxShadow(color: Color(0x0F2C302E), offset: Offset(0, 2), blurRadius: 4),
  ];

  static const List<BoxShadow> header = <BoxShadow>[
    BoxShadow(color: Color(0x0A2C302E), offset: Offset(0, 1), blurRadius: 12),
  ];

  static const List<BoxShadow> bottomBar = <BoxShadow>[
    BoxShadow(color: Color(0x0D2C302E), offset: Offset(0, -4), blurRadius: 20),
  ];

  static const List<BoxShadow> bottomDrawer = <BoxShadow>[
    BoxShadow(color: Color(0x142C302E), offset: Offset(0, -10), blurRadius: 30),
  ];

  static const List<BoxShadow> avatarRing = <BoxShadow>[
    BoxShadow(color: Color(0x332D5A46), spreadRadius: 2),
  ];
}
