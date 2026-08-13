import 'package:astral/features/rooms/widgets/all_user_card_nat.dart';
import 'package:astral/features/rooms/widgets/mini_user_card_nat.dart';
import 'package:astral/features/rooms/widgets/peer_connection_style.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connection badges use localizable role keys', () {
    expect(
      PeerConnectionStyle.mapConnectionType(0, '0.0.0.0', '10.0.0.1'),
      LocaleKeys.rooms_connection_server,
    );
    expect(
      PeerConnectionStyle.mapConnectionType(0, '10.0.0.1', '10.0.0.1'),
      LocaleKeys.rooms_connection_local,
    );
    expect(
      PeerConnectionStyle.mapConnectionType(1, '10.0.0.2', '10.0.0.1'),
      LocaleKeys.rooms_connection_direct,
    );
    expect(
      PeerConnectionStyle.mapConnectionType(2, '10.0.0.2', '10.0.0.1'),
      LocaleKeys.rooms_connection_relay,
    );
    expect(
      PeerConnectionStyle.mapConnectionType(0, '10.0.0.2', '10.0.0.1'),
      LocaleKeys.rooms_connection_unknown,
    );
  });

  test('compact and detailed cards expose technical NAT categories', () {
    for (final mapper in [
      MiniUserCardNat.mapNatType,
      AllUserCardNat.mapNatType,
    ]) {
      expect(mapper('Unknown'), LocaleKeys.rooms_nat_unknown);
      expect(mapper('Restricted'), LocaleKeys.rooms_nat_restricted);
      expect(mapper('PortRestricted'), LocaleKeys.rooms_nat_port_restricted);
      expect(mapper('unexpected'), LocaleKeys.rooms_nat_unknown);
    }
  });
}
