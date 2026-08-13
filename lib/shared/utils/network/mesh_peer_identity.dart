import 'package:astral/src/rust/api/simple.dart';

/// Stable emoji identities shared by Home and the Rooms constellation.
class MeshPeerIdentity {
  const MeshPeerIdentity._();

  /// Curated from Unicode Animals & Nature and Activities.
  ///
  /// Near-identical presentation variants, breeds, duplicate faces/bodies,
  /// medal ranks, card suits, and other hard-to-name lookalikes are omitted so
  /// peers can describe themselves unambiguously in conversation.
  static const emojis = <String>[
    // Mammals
    '🐵', '🦍', '🦧', '🐶', '🐺', '🦊', '🦝', '🐱', '🦁', '🐯',
    '🐆', '🐴', '🫎', '🫏', '🦄', '🦓', '🦌', '🦬', '🐮', '🐃',
    '🐷', '🐗', '🐏', '🐐', '🐪', '🦙', '🦒', '🐘', '🦣', '🦏',
    '🦛', '🐭', '🐀', '🐹', '🐰', '🐿️', '🦫', '🦔', '🦇', '🐻',
    '🐨', '🐼', '🦥', '🦦', '🦨', '🦘', '🦡',

    // Birds, reptiles, and amphibians
    '🦃', '🐔', '🐣', '🐦', '🐧', '🕊️', '🦅', '🦆', '🦢', '🦉',
    '🦤', '🦩', '🦚', '🦜', '🪿', '🐦‍🔥', '🐸', '🐊', '🐢', '🦎',
    '🐍', '🐲', '🐉', '🦕', '🦖',

    // Marine life and bugs
    '🐳', '🐬', '🦭', '🐟', '🐠', '🐡', '🦈', '🐙', '🐚', '🪸',
    '🪼', '🐌', '🦋', '🐛', '🐜', '🐝', '🪲', '🐞', '🦗', '🪳',
    '🕷️', '🦂', '🦟', '🪰', '🪱', '🦠',

    // Flowers and plants
    '💐', '🌸', '💮', '🪷', '🏵️', '🌹', '🥀', '🌺', '🌻', '🌼',
    '🌷', '🪻', '🌱', '🪴', '🌲', '🌳', '🌴', '🌵', '🌾', '🌿',
    '☘️', '🍀', '🍁', '🍂', '🍃', '🪹', '🪺', '🍄',

    // Events and celebrations
    '🎃', '🎄', '🎆', '🎇', '🧨', '✨', '🎈', '🎉', '🎊', '🎋',
    '🎍', '🎎', '🎏', '🎐', '🎑', '🧧', '🎀', '🎁', '🎟️', '🎫',
    '🏆', '🏅',

    // Sports
    '⚽', '⚾', '🥎', '🏀', '🏐', '🏈', '🏉', '🎾', '🥏', '🎳',
    '🏏', '🏑', '🏒', '🥍', '🏓', '🏸', '🥊', '🥋', '🥅', '⛳',
    '⛸️', '🎣', '🤿', '🎽', '🎿', '🛷', '🥌',

    // Games and creative activities
    '🎯', '🪀', '🪁', '🔫', '🎱', '🔮', '🪄', '🎮', '🕹️', '🎰',
    '🎲', '🧩', '🧸', '🪅', '🪩', '🪆', '♟️', '🃏', '🀄', '🎴',
    '🎭', '🖼️', '🎨', '🧵', '🪡', '🧶', '🪢',
  ];

  static String emojiFor({required String username, required String ip}) {
    final identity = '${username.trim().toLowerCase()}|${ip.trim()}';
    return emojis[_stableHash(identity) % emojis.length];
  }

  static String emojiForNode(KVNodeInfo node) =>
      emojiFor(username: node.hostname, ip: node.ipv4);

  static int _stableHash(String source) {
    var hash = 2166136261;
    for (final unit in source.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
