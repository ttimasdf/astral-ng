import 'package:astral/core/services/service_manager.dart';
import 'package:astral/features/settings/models/settings_availability.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:astral/core/ui/app_snack_bars.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signals_flutter/signals_flutter.dart';

class PermissionsSettingsContent extends StatefulWidget {
  const PermissionsSettingsContent({super.key});

  @override
  State<PermissionsSettingsContent> createState() =>
      _PermissionsSettingsContentState();
}

class _PermissionsSettingsContentState extends State<PermissionsSettingsContent>
    with WidgetsBindingObserver {
  bool _installGranted = false;
  bool _notificationGranted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    if (!SettingsAvailability.androidOnly.isSupported) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    final install = await Permission.requestInstallPackages.status;
    final notification = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _installGranted = install.isGranted;
      _notificationGranted = notification.isGranted;
      _checking = false;
    });
  }

  Future<void> _requestPermission(
    Permission permission, {
    required String successKey,
    required String failureKey,
  }) async {
    final status = await permission.request();
    await _refreshPermissions();
    if (!mounted) return;

    if (status.isGranted) {
      AppSnackBars.success(context, successKey.tr(), '');
      return;
    }

    AppSnackBars.error(context, failureKey.tr(), '');
    if (status.isPermanentlyDenied) {
      await _showSystemSettingsDialog();
    }
  }

  Future<void> _showSystemSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(LocaleKeys.permission_denied.tr()),
            content: Text(LocaleKeys.permission_open_system_settings.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocaleKeys.cancel.tr()),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text(LocaleKeys.go_settings.tr()),
              ),
            ],
          ),
    );
  }

  Widget _permissionStatus(bool granted) {
    return SettingsValueChip(
      label:
          granted
              ? LocaleKeys.permission_granted.tr()
              : LocaleKeys.permission_required.tr(),
      color: granted ? Colors.green : Colors.orange,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SettingsAvailability.androidOnly.isSupported) {
      return SettingsContentView(
        title: LocaleKeys.settings_permissions.tr(),
        description: LocaleKeys.settings_permissions_desc.tr(),
        children: [
          SettingsNotice(
            icon: Icons.verified_user_outlined,
            message: LocaleKeys.permissions_managed_by_system.tr(),
          ),
        ],
      );
    }

    return Watch((context) {
      final notificationEnabled = ServiceManager()
          .appSettingsState
          .connectionNotificationEnabled
          .watch(context);

      return SettingsContentView(
        title: LocaleKeys.settings_permissions.tr(),
        description: LocaleKeys.settings_permissions_desc.tr(),
        children: [
          if (_checking) const LinearProgressIndicator(),
          SettingsSection(
            title: LocaleKeys.android_settings.tr(),
            description: LocaleKeys.android_settings_desc.tr(),
            icon: Icons.android,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),
                leading: const Icon(Icons.install_mobile),
                title: Text(LocaleKeys.install_update_permission.tr()),
                subtitle: Text(LocaleKeys.install_permission_explanation.tr()),
                trailing: _permissionStatus(_installGranted),
                onTap:
                    _installGranted
                        ? null
                        : () => _requestPermission(
                          Permission.requestInstallPackages,
                          successKey: LocaleKeys.permission_install_success,
                          failureKey: LocaleKeys.permission_install_failed,
                        ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),
                leading: const Icon(Icons.notifications_outlined),
                title: Text(LocaleKeys.notification_permission.tr()),
                subtitle: Text(
                  LocaleKeys.notification_permission_explanation.tr(),
                ),
                trailing: _permissionStatus(_notificationGranted),
                onTap:
                    _notificationGranted
                        ? null
                        : () => _requestPermission(
                          Permission.notification,
                          successKey:
                              LocaleKeys.permission_notification_success,
                          failureKey: LocaleKeys.permission_notification_failed,
                        ),
              ),
            ],
          ),
          SettingsSection(
            title: LocaleKeys.connection_notification.tr(),
            description: LocaleKeys.connection_notification_desc.tr(),
            icon: Icons.notifications_active_outlined,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.connection_notification.tr()),
                subtitle: Text(
                  _notificationGranted
                      ? LocaleKeys.connection_notification_desc.tr()
                      : LocaleKeys.notification_permission_needed.tr(),
                ),
                value: notificationEnabled && _notificationGranted,
                onChanged: (value) async {
                  if (value && !_notificationGranted) {
                    await _requestPermission(
                      Permission.notification,
                      successKey: LocaleKeys.permission_notification_success,
                      failureKey: LocaleKeys.permission_notification_failed,
                    );
                    if (!_notificationGranted) return;
                  }
                  await ServiceManager().appSettings
                      .setConnectionNotificationEnabled(value);
                },
              ),
            ],
          ),
        ],
      );
    });
  }
}
