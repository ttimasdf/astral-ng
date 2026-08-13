import 'package:astral/shared/utils/network/mesh_peer_identity.dart';
import 'package:flutter/material.dart';

/// A consistently centered peer identity used across setup and network views.
class MeshPeerBadge extends StatelessWidget {
  final String username;
  final String ip;
  final double size;
  final bool isLocal;
  final bool framed;
  final Color? borderColor;

  const MeshPeerBadge({
    super.key,
    required this.username,
    required this.ip,
    this.size = 28,
    this.isLocal = false,
    this.framed = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final emoji = MeshPeerIdentity.emojiFor(username: username, ip: ip);
    final glyph = Center(
      child: Transform.translate(
        offset: Offset(0, -size * .015),
        child: Text(
          emoji,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size * .62,
            height: 1,
            fontFamilyFallback: const [
              'Noto Color Emoji',
              'Apple Color Emoji',
              'Segoe UI Emoji',
            ],
          ),
        ),
      ),
    );

    if (!framed) return SizedBox.square(dimension: size, child: glyph);

    final identityColor = isLocal ? colorScheme.primary : colorScheme.secondary;
    final innerColor = borderColor ?? identityColor;
    final badge = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(
          innerColor.withValues(alpha: isLocal ? .14 : .1),
          colorScheme.surface,
        ),
        border: Border.all(color: innerColor, width: isLocal ? 1.5 : 1.3),
      ),
      child: glyph,
    );
    if (!isLocal || borderColor == null) return badge;

    return Container(
      width: size + 6,
      height: size + 6,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.primary, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: .2),
            blurRadius: size * .22,
          ),
        ],
      ),
      child: badge,
    );
  }
}
