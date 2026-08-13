import 'package:astral/generated/locale_keys.g.dart';
import 'package:flutter/material.dart';

enum NatFamily {
  public,
  fullCone,
  restricted,
  portRestricted,
  symmetric,
  unknown,
}

class NatVisualStyle {
  final NatFamily family;
  final String labelKey;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;

  const NatVisualStyle({
    required this.family,
    required this.labelKey,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  factory NatVisualStyle.resolve(String rawNat, ColorScheme colorScheme) {
    final normalized = _normalize(rawNat);
    final family = _familyFor(normalized);
    final foreground = _foreground(family, colorScheme.brightness);
    return NatVisualStyle(
      family: family,
      labelKey: _labelFor(normalized),
      icon: _iconFor(normalized),
      foreground: foreground,
      background: Color.alphaBlend(
        foreground.withValues(
          alpha: colorScheme.brightness == Brightness.dark ? .18 : .1,
        ),
        colorScheme.surface,
      ),
      border: foreground.withValues(alpha: .76),
    );
  }

  static List<NatFamily> get legendFamilies => const [
    NatFamily.public,
    NatFamily.fullCone,
    NatFamily.restricted,
    NatFamily.portRestricted,
    NatFamily.symmetric,
    NatFamily.unknown,
  ];

  static String familyLabelKey(NatFamily family) => switch (family) {
    NatFamily.public => LocaleKeys.rooms_nat_family_public,
    NatFamily.fullCone => LocaleKeys.rooms_nat_full_cone,
    NatFamily.restricted => LocaleKeys.rooms_nat_family_restricted,
    NatFamily.portRestricted => LocaleKeys.rooms_nat_family_port_restricted,
    NatFamily.symmetric => LocaleKeys.rooms_nat_family_symmetric,
    NatFamily.unknown => LocaleKeys.rooms_nat_unknown,
  };

  static NatVisualStyle forFamily(NatFamily family, ColorScheme colorScheme) =>
      NatVisualStyle.resolve(switch (family) {
        NatFamily.public => 'OpenInternet',
        NatFamily.fullCone => 'FullCone',
        NatFamily.restricted => 'Restricted',
        NatFamily.portRestricted => 'PortRestricted',
        NatFamily.symmetric => 'Symmetric',
        NatFamily.unknown => 'Unknown',
      }, colorScheme);
}

String _normalize(String value) => switch (value.trim()) {
  'OpenInternet' || LocaleKeys.rooms_nat_open_internet => 'OpenInternet',
  'NoPat' || LocaleKeys.rooms_nat_no_pat => 'NoPat',
  'FullCone' || LocaleKeys.rooms_nat_full_cone => 'FullCone',
  'Restricted' || LocaleKeys.rooms_nat_restricted => 'Restricted',
  'PortRestricted' || LocaleKeys.rooms_nat_port_restricted => 'PortRestricted',
  'Symmetric' || LocaleKeys.rooms_nat_symmetric => 'Symmetric',
  'SymUdpFirewall' ||
  LocaleKeys.rooms_nat_symmetric_udp_firewall => 'SymUdpFirewall',
  'SymmetricEasyInc' ||
  LocaleKeys.rooms_nat_symmetric_easy_inc => 'SymmetricEasyInc',
  'SymmetricEasyDec' ||
  LocaleKeys.rooms_nat_symmetric_easy_dec => 'SymmetricEasyDec',
  _ => 'Unknown',
};

NatFamily _familyFor(String normalized) => switch (normalized) {
  'OpenInternet' || 'NoPat' => NatFamily.public,
  'FullCone' => NatFamily.fullCone,
  'Restricted' => NatFamily.restricted,
  'PortRestricted' => NatFamily.portRestricted,
  'Symmetric' ||
  'SymUdpFirewall' ||
  'SymmetricEasyInc' ||
  'SymmetricEasyDec' => NatFamily.symmetric,
  _ => NatFamily.unknown,
};

String _labelFor(String normalized) => switch (normalized) {
  'OpenInternet' => LocaleKeys.rooms_nat_open_internet,
  'NoPat' => LocaleKeys.rooms_nat_no_pat,
  'FullCone' => LocaleKeys.rooms_nat_full_cone,
  'Restricted' => LocaleKeys.rooms_nat_restricted,
  'PortRestricted' => LocaleKeys.rooms_nat_port_restricted,
  'Symmetric' => LocaleKeys.rooms_nat_symmetric,
  'SymUdpFirewall' => LocaleKeys.rooms_nat_symmetric_udp_firewall,
  'SymmetricEasyInc' => LocaleKeys.rooms_nat_symmetric_easy_inc,
  'SymmetricEasyDec' => LocaleKeys.rooms_nat_symmetric_easy_dec,
  _ => LocaleKeys.rooms_nat_unknown,
};

IconData _iconFor(String normalized) => switch (normalized) {
  'OpenInternet' => Icons.public_rounded,
  'NoPat' => Icons.router_rounded,
  'FullCone' => Icons.radar_rounded,
  'Restricted' => Icons.shield_outlined,
  'PortRestricted' => Icons.security_rounded,
  'SymUdpFirewall' => Icons.local_fire_department_outlined,
  'SymmetricEasyInc' => Icons.trending_up_rounded,
  'SymmetricEasyDec' => Icons.trending_down_rounded,
  'Symmetric' => Icons.sync_alt_rounded,
  _ => Icons.help_outline_rounded,
};

Color _foreground(NatFamily family, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (family) {
    NatFamily.public => Color(dark ? 0xFF67D4DC : 0xFF007C83),
    NatFamily.fullCone => Color(dark ? 0xFF73D397 : 0xFF287A45),
    NatFamily.restricted => Color(dark ? 0xFF82B1FF : 0xFF2864B7),
    NatFamily.portRestricted => Color(dark ? 0xFFF2BD55 : 0xFF9A6500),
    NatFamily.symmetric => Color(dark ? 0xFFC9A0F4 : 0xFF7B4CB0),
    NatFamily.unknown => Color(dark ? 0xFFB8BBC4 : 0xFF656872),
  };
}
