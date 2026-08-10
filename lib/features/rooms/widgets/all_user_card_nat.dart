import 'package:astral/generated/locale_keys.g.dart';
import 'package:flutter/material.dart';

/// 大卡：技术 NAT 文案与颜色
class AllUserCardNat {
  const AllUserCardNat._();

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
    return switch (natType) {
      LocaleKeys.rooms_nat_open_internet ||
      LocaleKeys.rooms_nat_full_cone => Icons.public,
      LocaleKeys.rooms_nat_port_restricted => Icons.security,
      LocaleKeys.rooms_nat_restricted => Icons.shield,
      LocaleKeys.rooms_nat_symmetric => Icons.sync_alt,
      LocaleKeys.rooms_nat_symmetric_udp_firewall => Icons.fireplace,
      LocaleKeys.rooms_nat_symmetric_easy_inc => Icons.trending_up,
      LocaleKeys.rooms_nat_symmetric_easy_dec => Icons.trending_down,
      LocaleKeys.rooms_nat_no_pat => Icons.router,
      _ => Icons.help_outline,
    };
  }

  static Color getNatTypeColor(String natType) {
    return switch (natType) {
      LocaleKeys.rooms_nat_open_internet ||
      LocaleKeys.rooms_nat_full_cone ||
      LocaleKeys.rooms_nat_no_pat => Colors.green,
      LocaleKeys.rooms_nat_restricted ||
      LocaleKeys.rooms_nat_port_restricted => Colors.orange,
      LocaleKeys.rooms_nat_symmetric ||
      LocaleKeys.rooms_nat_symmetric_udp_firewall ||
      LocaleKeys.rooms_nat_symmetric_easy_inc ||
      LocaleKeys.rooms_nat_symmetric_easy_dec => Colors.red,
      _ => Colors.grey,
    };
  }
}
