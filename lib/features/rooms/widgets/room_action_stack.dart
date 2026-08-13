import 'package:flutter/material.dart';

class RoomAction {
  final Key key;
  final String heroTag;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const RoomAction({
    required this.key,
    required this.heroTag,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
}

/// Shared vertical action rail for disconnected and connected room states.
class RoomActionStack extends StatelessWidget {
  final List<RoomAction> actions;

  const RoomActionStack({super.key, required this.actions});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      for (var index = 0; index < actions.length; index++) ...[
        if (index > 0) const SizedBox(height: 16),
        FloatingActionButton(
          key: actions[index].key,
          heroTag: actions[index].heroTag,
          onPressed: actions[index].onPressed,
          tooltip: actions[index].tooltip,
          child: Icon(actions[index].icon),
        ),
      ],
    ],
  );
}
