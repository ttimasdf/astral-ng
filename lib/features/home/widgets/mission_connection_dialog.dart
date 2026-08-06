import 'package:astral/core/models/room.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MissionConnectionDialog extends StatefulWidget {
  const MissionConnectionDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const MissionConnectionDialog(),
  );

  @override
  State<MissionConnectionDialog> createState() =>
      _MissionConnectionDialogState();
}

class _MissionConnectionDialogState extends State<MissionConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _services = ServiceManager();
  late final TextEditingController _nameController;
  late final TextEditingController _ipController;
  late bool _automaticIp;
  Room? _room;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: _services.playerState.playerName.value,
    );
    _ipController = TextEditingController(
      text: _services.networkConfigState.ipv4.value,
    );
    _automaticIp = _services.networkConfigState.dhcp.value;
    _room = _services.roomState.selectedRoom.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  bool _isValidIpv4(String value) {
    final parts = value.split('/');
    if (parts.length > 2 || parts.first.isEmpty) return false;
    final octets = parts.first.split('.');
    if (octets.length != 4) return false;
    for (final octet in octets) {
      final parsed = int.tryParse(octet);
      if (parsed == null || parsed < 0 || parsed > 255) return false;
    }
    if (parts.length == 2) {
      final mask = int.tryParse(parts[1]);
      if (mask == null || mask < 0 || mask > 32) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _room == null) return;
    setState(() => _saving = true);
    // Player name and selected room share the AllSettings record, so persist
    // them sequentially to avoid overlapping read-modify-write transactions.
    await _services.appSettings.updatePlayerName(_nameController.text.trim());
    await _services.room.setRoom(_room!);
    await _services.networkConfig.updateDhcp(_automaticIp);
    if (!_automaticIp) {
      await _services.networkConfig.updateIpv4(_ipController.text.trim());
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _services.roomState.rooms.value;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.tune_rounded, color: colorScheme.primary),
      title: Text(LocaleKeys.mission_connection_details.tr()),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.username.tr(),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? LocaleKeys.username_hint.tr()
                              : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Room>(
                  initialValue: _room,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.select_room.tr(),
                    prefixIcon: const Icon(Icons.hub_outlined),
                  ),
                  items: [
                    for (final room in rooms)
                      DropdownMenuItem(value: room, child: Text(room.name)),
                  ],
                  onChanged: (room) => setState(() => _room = room),
                  validator:
                      (room) =>
                          room == null
                              ? LocaleKeys.select_room_first.tr()
                              : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(LocaleKeys.mission_automatic_ip.tr()),
                  subtitle: Text(LocaleKeys.auto_assign_ip_notice.tr()),
                  value: _automaticIp,
                  onChanged: (value) => setState(() => _automaticIp = value),
                ),
                if (!_automaticIp) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.virtual_network_ip.tr(),
                      prefixIcon: const Icon(Icons.lan_outlined),
                    ),
                    validator:
                        (value) =>
                            value == null || !_isValidIpv4(value.trim())
                                ? LocaleKeys.invalid_ipv4_error.tr()
                                : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.cancel.tr()),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child:
              _saving
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(LocaleKeys.save.tr()),
        ),
      ],
    );
  }
}
