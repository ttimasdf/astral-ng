import 'package:enmesh/features/rooms/widgets/nat_visual_style.dart';
import 'package:flutter/material.dart';

/// Compatibility facade for compact-card NAT rendering.
class MiniUserCardNat {
  const MiniUserCardNat._();

  static String mapNatType(String natType) =>
      NatVisualStyle.resolve(natType, const ColorScheme.light()).labelKey;

  static IconData getNatTypeIcon(String natType) =>
      NatVisualStyle.resolve(natType, const ColorScheme.light()).icon;

  static Color getNatTypeColor(String natType) =>
      NatVisualStyle.resolve(natType, const ColorScheme.light()).foreground;
}
