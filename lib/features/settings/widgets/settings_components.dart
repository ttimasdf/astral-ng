import 'package:flutter/material.dart';

class SettingsContentView extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;

  const SettingsContentView({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ..._withSpacing(children),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets) {
    return [
      for (var index = 0; index < widgets.length; index++) ...[
        widgets[index],
        if (index != widgets.length - 1) const SizedBox(height: 18),
      ],
    ];
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            description!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1)
                Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final VoidCallback onTap;

  const SettingsLinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                value!,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}

class SettingsNotice extends StatelessWidget {
  final IconData icon;
  final String message;

  const SettingsNotice({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsValueChip extends StatelessWidget {
  final String label;
  final Color? color;

  const SettingsValueChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = color ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
