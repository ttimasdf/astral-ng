import 'package:astral/generated/locale_keys.g.dart';
import 'package:flutter/material.dart';

/// Compact-card technical NAT labels and colors.
class MiniUserCardNat {
  const MiniUserCardNat._();

  static String mapNatType(String natType) {
    switch (natType) {
      case 'OpenInternet':
        return LocaleKeys.rooms_nat_open_internet;
      case 'NoPat':
        return LocaleKeys.rooms_nat_no_pat;
      case 'FullCone':
        return LocaleKeys.rooms_nat_full_cone;
      case 'Restricted':
        return LocaleKeys.rooms_nat_restricted;
      case 'PortRestricted':
        return LocaleKeys.rooms_nat_port_restricted;
      case 'Symmetric':
        return LocaleKeys.rooms_nat_symmetric;
      case 'SymUdpFirewall':
        return LocaleKeys.rooms_nat_symmetric_udp_firewall;
      case 'SymmetricEasyInc':
        return LocaleKeys.rooms_nat_symmetric_easy_inc;
      case 'SymmetricEasyDec':
        return LocaleKeys.rooms_nat_symmetric_easy_dec;
      case 'Unknown':
      default:
        return LocaleKeys.rooms_nat_unknown;
    }
  }

  static IconData getNatTypeIcon(String natType) {
    switch (natType) {
      case LocaleKeys.rooms_nat_open_internet:
      case LocaleKeys.rooms_nat_no_pat:
        return Icons.workspace_premium;
      case LocaleKeys.rooms_nat_full_cone:
        return Icons.military_tech;
      case LocaleKeys.rooms_nat_restricted:
      case LocaleKeys.rooms_nat_port_restricted:
        return Icons.verified;
      case LocaleKeys.rooms_nat_symmetric_udp_firewall:
      case LocaleKeys.rooms_nat_symmetric_easy_inc:
      case LocaleKeys.rooms_nat_symmetric_easy_dec:
        return Icons.circle;
      case LocaleKeys.rooms_nat_symmetric:
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  static Color getNatTypeColor(String natType) {
    switch (natType) {
      case LocaleKeys.rooms_nat_open_internet:
      case LocaleKeys.rooms_nat_no_pat:
        return const Color(0xFFFF6B00);
      case LocaleKeys.rooms_nat_full_cone:
        return const Color(0xFFA335EE);
      case LocaleKeys.rooms_nat_restricted:
      case LocaleKeys.rooms_nat_port_restricted:
        return const Color(0xFF0070DD);
      case LocaleKeys.rooms_nat_symmetric_udp_firewall:
      case LocaleKeys.rooms_nat_symmetric_easy_inc:
      case LocaleKeys.rooms_nat_symmetric_easy_dec:
        return const Color(0xFF1EFF00);
      case LocaleKeys.rooms_nat_symmetric:
        return const Color(0xFF9D9D9D);
      default:
        return Colors.grey;
    }
  }
}
