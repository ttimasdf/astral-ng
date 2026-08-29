import 'package:enmesh/features/rooms/widgets/nat_visual_style.dart';
import 'package:flutter/material.dart';

/// Compatibility facade for detailed-card NAT rendering.
class AllUserCardNat {
  const AllUserCardNat._();

  static String mapNatType(String natType) =>
      NatVisualStyle.resolve(natType, const ColorScheme.light()).labelKey;

  static IconData getNatTypeIcon(String natType) =>
      NatVisualStyle.resolve(natType, const ColorScheme.light()).icon;

  static Color getNatTypeColor(String natType) =>
      NatVisualStyle.resolve(natType, const ColorScheme.light()).foreground;
}
