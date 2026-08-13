import 'package:astral/shared/utils/network/mesh_peer_identity.dart';
import 'package:flutter/material.dart';

/// A consistently centered peer identity used across setup and network views.
class MeshPeerBadge extends StatelessWidget {
  final String username;
  final String ip;
  final double size;
  final bool isLocal;
  final bool framed;

  const MeshPeerBadge({
    super.key,
    required this.username,
    required this.ip,
    this.size = 28,
    this.isLocal = false,
    this.framed = true,
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

    final color = isLocal ? colorScheme.primary : colorScheme.secondary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(
          color.withValues(alpha: isLocal ? .16 : .1),
          colorScheme.surface,
        ),
        border: Border.all(color: color, width: isLocal ? 2.2 : 1.1),
        boxShadow:
            isLocal
                ? [
                  BoxShadow(
                    color: color.withValues(alpha: .2),
                    blurRadius: size * .22,
                  ),
                ]
                : null,
      ),
      child: glyph,
    );
  }
}
