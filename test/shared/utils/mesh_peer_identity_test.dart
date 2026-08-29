import 'package:enmesh/shared/utils/network/mesh_peer_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('curated palette is large and contains unique emoji identities', () {
    expect(MeshPeerIdentity.emojis.length, greaterThan(180));
    expect(
      MeshPeerIdentity.emojis.toSet(),
      hasLength(MeshPeerIdentity.emojis.length),
    );
  });

  test('emoji identity is shared and stable across observers', () {
    final first = MeshPeerIdentity.emojiFor(
      username: '  Nori  ',
      ip: '10.10.0.42',
    );
    final second = MeshPeerIdentity.emojiFor(
      username: 'nori',
      ip: '10.10.0.42',
    );

    expect(first, second);
    expect(
      MeshPeerIdentity.emojiFor(username: 'nori', ip: '10.10.0.43'),
      isNot(first),
    );
  });
}
